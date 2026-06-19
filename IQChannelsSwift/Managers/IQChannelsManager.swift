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
    @Published var infoChatSettings: IQInfoChatSettings? = nil
    @Published var greetingSettings: IQGreetingSettings? = nil
    var listViewModel: IQChatListViewModel?
    var baseViewModels: [IQBaseViewModel] {
        [listViewModel, detailViewModel].compactMap { $0 }
    }
    var unsentMessages = [IQMessage]()
    var readMessages = Set<Int>()
    var authAttempt = 0
    var lastLocalID = 0
    var loginType: IQLoginType?
    var typingTimer: Timer?
    var isAnonim = false
    var isLoadingOldMessages = false
    var typingSentDate: Date?
    var didSendAttachments = false
    var fileLimit: IQFileConfig?
    var eventListener: IQChannelsEventListenerProtocol?
    static var unreadListeners: [any IQChannelsUnreadListenerProtocol] = []
    var subscriptions = Set<AnyCancellable>()
    
    //MARK: - Managers
    /// Key is channel
    var networkManagers: [String: any IQNetworkManagerProtocol]
    let networkStatusManager = IQNetworkStatusManager()
    let storageManager = IQStorageManager()
    var currentNetworkManager: IQNetworkManagerProtocol? {
        if let token = selectedChat?.auth.auth.session?.token {
            SDWebImageDownloader.shared.setValue("client-session=\(token)", forHTTPHeaderField: "Cookie")
        }
        guard let channel = selectedChat?.auth.channel else { return nil}
        return networkManagers[channel]
    }
    var lifecycleObserver: AppLifecycleObserver?
    var sendDelay: TimeInterval = 0
    
    init(configuration: IQChannelsConfig) {
        self.config = configuration
        var networkManagers = [String: IQNetworkManagerProtocol]()
        configuration.channels.forEach {
            networkManagers.updateValue(IQNetworkManager(address: configuration.address, channel: $0), forKey: $0)
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
    
    
    func configure(configuration: IQChannelsConfig) {
        logout()
        
        self.config = configuration
        var networkManagers = [String: IQNetworkManagerProtocol]()
        configuration.channels.forEach {
            networkManagers.updateValue(IQNetworkManager(address: configuration.address, channel: $0), forKey: $0)
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
    
    func login(_ loginType: IQLoginType, _ completion: (() -> Void)?) {
        logout()
        auth(loginType, completion)
    }
    
    func logout() {
        IQLog.debug(message: "logout")
        listViewModel?.dismissListener.send(())
        clear()
    }
    
}
