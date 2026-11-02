//
//  IQChannelsManager.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 08.05.2024.
//

import Foundation
import Combine
import SDWebImage

class IQChannelsManager: IQChannelsManagerProtocol {
    
    //MARK: - Typealiases
    typealias AuthResult = (channel: String, auth: IQClientAuth)
    
    //MARK: - Models
    @Published var selectedChat: (auth: AuthResult, chatType: IQChatType)?
    @Published var authResults = [AuthResult]()
    @Published var state: IQChannelsState = .awaitingNetwork
    @Published var messages: [IQMessage] = []
    @Published var detailViewModel: IQChatDetailViewModel?
    @Published var systemChat: Bool = false
    var config: IQChannelsConfig
    /// Key is channel. Blocker (info-stub) settings are fetched per channel,
    /// so they must not leak from one channel into another.
    @Published var infoChatSettingsByChannel: [String: IQInfoChatSettings] = [:]
    /// Key is channel
    @Published var greetingSettingsByChannel: [String: IQGreetingSettings] = [:]
    var listViewModel: IQChatListViewModel?
    var isSingleChatExpected: Bool {
        config.chatToOpen != nil || config.channels.count == 1
    }
    var baseViewModels: [IQBaseViewModel] {
        [listViewModel, detailViewModel].compactMap { $0 }
    }
    var unsentMessages = [IQMessage]()
    var isRetryingUnsentMessages = false
    var readMessages = Set<Int>()
    var authAttempt = 0
    var lastLocalID = 0
    var loginType: IQLoginType?
    var typingTimer: Timer?
    var isAnonim = false
    var isLoadingOldMessages = false
    var typingSentDate: Date?
    var advancedUnreadBounceTask: Task<Void, Never>?
    var didSendAttachments = false
    var fileLimit: IQFileConfig?
    var eventListener: IQChannelsEventListenerProtocol?
    static var unreadListeners: [any IQChannelsUnreadListenerProtocol] = []
    static var advancedUnreadListeners: [any IQChannelsAdvancedUnreadListenerProtocol] = []
    static var linkListeners: [any IQChannelsLinkListenerProtocol] = []
    static var advancedUnread: IQAdvancedUnread? = nil
    var subscriptions = Set<AnyCancellable>()
    
    //MARK: - Managers
    /// Key is channel
    var networkManagers: [String: any IQNetworkManagerProtocol]
    let networkStatusManager = IQNetworkStatusManager()
    let storageManager = IQStorageManager()
    lazy var analytics = IQAnalyticsManager(isOnline: { [networkStatusManager] in
        networkStatusManager.isReachable
    })
    var currentNetworkManager: IQNetworkManagerProtocol? {
        if let token = selectedChat?.auth.auth.session?.token {
            SDWebImageDownloader.shared.setValue("client-session=\(token)", forHTTPHeaderField: "Cookie")
        }
        guard let channel = selectedChat?.auth.channel else { return nil}
        return networkManagers[channel]
    }
    /// Channel of the chat that is currently open (or will be opened automatically)
    var currentChannel: String? {
        selectedChat?.auth.channel ?? config.chatToOpen?.channel ?? config.channels.first
    }
    /// Blocker (info-stub) settings of the current channel only
    var infoChatSettings: IQInfoChatSettings? {
        currentChannel.flatMap { infoChatSettingsByChannel[$0] }
    }
    /// Greeting settings of the current channel only
    var greetingSettings: IQGreetingSettings? {
        currentChannel.flatMap { greetingSettingsByChannel[$0] }
    }
    var lifecycleObserver: AppLifecycleObserver?
    var sendDelay: TimeInterval = 0
    /// Пауза между загрузками файлов одной партии (в секундах),
    /// чтобы не отправлять на сервер всплеск запросов
    let fileUploadPause: TimeInterval = 0.5
    
    init(configuration: IQChannelsConfig) {
        self.config = configuration
        var networkManagers = [String: IQNetworkManagerProtocol]()
        configuration.channels.forEach {
            networkManagers.updateValue(IQNetworkManager(address: configuration.address, channel: $0, useRussianTrustedRootCA: configuration.useRussianTrustedRootCA, urlSession: configuration.urlSession), forKey: $0)
        }
        self.networkManagers = networkManagers
        
        networkStatusManager.delegate = self
        
        setupCombine()
        setupImageManager()
        setupFileLimits()
    }
    
    func getViewController() -> IQChatDetailViewController? {
        return getDetailViewController(for: selectedChat, showNavBar: false)
    }
    
    func getChatSkeletonViewController() -> IQChatDetailViewController {
        return getDetailViewController(for: selectedChat, showNavBar: true)
    }
    
    
    func configure(configuration: IQChannelsConfig) {
        logout()
        
        self.config = configuration
        var networkManagers = [String: IQNetworkManagerProtocol]()
        configuration.channels.forEach {
            networkManagers.updateValue(IQNetworkManager(address: configuration.address, channel: $0, useRussianTrustedRootCA: configuration.useRussianTrustedRootCA, urlSession: configuration.urlSession), forKey: $0)
        }
        self.networkManagers = networkManagers
        
        networkStatusManager.delegate = self
        
        configureCombine()
        setupImageManager()
        setupFileLimits()
    }
    
    func setCustomHeaders(_ headers: [String: String]) {
        headers.forEach { key, value in
            SDWebImageDownloader.shared.setValue(value, forHTTPHeaderField: key)
        }
        networkManagers.values.forEach { $0.setCustomHeaders(headers) }
    }
    
    func setListViewModel(_ viewModel: IQChatListViewModel?) {
        self.listViewModel = viewModel
        listViewModel?.chatsInfo = getChatItems(from: authResults, config: config)
        listViewModel?.advancedUnread = IQChannelsManager.advancedUnread?.channels ?? []
        
        if !isSingleChatExpected && IQChannelsManager.advancedUnread == nil && !authResults.isEmpty {
            getAdvancedUnread()
        }
    }
    
    func addEvent(listener: any IQChannelsEventListenerProtocol) {
        eventListener = listener
    }
    
    func removeEventListener() {
        eventListener = nil
    }
    
    func addUnread(listener: IQChannelsUnreadListenerProtocol) {
        IQChannelsManager.unreadListeners.append(listener)
    }
    
    func removeUnread(listener: IQChannelsUnreadListenerProtocol) {
        Task {
            await MainActor.run {
                IQChannelsManager.unreadListeners.removeAll(where: { $0.id == listener.id })
            }
        }
    }
    
    func addAdvancedUnread(listener: IQChannelsAdvancedUnreadListenerProtocol) {
        IQChannelsManager.advancedUnreadListeners.append(listener)
    }
    
    func removeAdvancedUnread(listener: IQChannelsAdvancedUnreadListenerProtocol) {
        Task {
            await MainActor.run {
                IQChannelsManager.advancedUnreadListeners.removeAll(where: { $0.id == listener.id })
            }
        }
    }
    
    func addLink(listener: IQChannelsLinkListenerProtocol) {
        IQChannelsManager.linkListeners.append(listener)
    }
    
    func removeLink(listener: IQChannelsLinkListenerProtocol) {
        IQChannelsManager.linkListeners.removeAll(where: { $0.id == listener.id })
    }
    
    static func shouldHandleLink(_ link: String) -> Bool {
        !linkListeners.contains { !$0.iqChannelsShouldHandleLink(link: link) }
    }
    
    func login(_ loginType: IQLoginType, _ completion: ((Bool) -> Void)?) {
        logout()
        var fired = false
        let onceCompletion = completion.map { callback in
            { (success: Bool) in
                if !fired {
                    fired = true
                    callback(success)
                }
            }
        }
        auth(loginType, onceCompletion)
    }
    
    func logout() {
        IQLog.debug(message: "logout")
        listViewModel?.dismissListener.send(())
        detailViewModel?.dismissListener.send(())
        clear()
    }
    
}
