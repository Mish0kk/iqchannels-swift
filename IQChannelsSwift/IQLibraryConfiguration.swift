//
//  IQLibraryConfiguration.swift
//  IQChannelsSwift-IQChannelsSwift
//
//  Created by Muhammed Aralbek on 06.05.2024.
//

import Foundation
import UIKit

public class IQLibraryConfiguration: IQLibraryConfigurationProtocol {
    
    var channelManager: (IQChannelsManagerProtocol & IQChannelsManagerListOutput)?
    var deviceToken: Data?
    
    public init () { }
    
    public func getViewController() -> UINavigationController? {
        guard let channelManager else { return nil }
        
        let viewModel = IQChatListViewModel()
        channelManager.setListViewModel(viewModel)
        let list = IQChatListViewController(viewModel: viewModel, output: channelManager)
        
        let navigationController = UINavigationController(rootViewController: list)
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.modalTransitionStyle = .coverVertical

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundImage = UIImage()
        navigationBarAppearance.backgroundColor = .white
        navigationBarAppearance.shadowColor = .clear

        navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController.navigationBar.compactAppearance = navigationBarAppearance
        navigationController.navigationBar.standardAppearance = navigationBarAppearance
        IQLog.debug(message: "1")
        return navigationController
    }
    
    public func getChatViewController() -> UIViewController? {
        guard let channelManager else { return nil }
        let viewController = channelManager.getViewController()
        return viewController
    }
    
    public func setCustomHeaders(_ headers: [String : String]) {
        channelManager?.setCustomHeaders(headers)
    }
    
    public func configure(_ config: IQChannelsConfig) {        
        IQStyle.configure(config.styleJson)
        IQLanguageTexts.configure(config.languageJson)
        if channelManager == nil {
            channelManager = IQChannelsManager(configuration: config)
        } else {
            channelManager?.configure(configuration: config)
        }
        
        IQLog.configure(state: config.logging)
//        #if DEBUG
//            IQLog.configure(state: true)
////            IQLog.configure(state: false)
//        #else
////            IQLog.configure(state: true)
//            IQLog.configure(state: false)
//        #endif
    }
    
    public func setNewJSON(_ json: Data?) {
        IQStyle.configure(json)
    }
    
    public func login(_ loginType: IQLoginType, _ completion: (() -> Void)?) {
        channelManager?.login(loginType, completion)
    }
    
    public func logout() {
        channelManager?.logout()
    }
    
    public func addEvent(listener: any IQChannelsEventListenerProtocol) {
        channelManager?.addEvent(listener: listener)
    }
    
    public func removeEventListener() {
        channelManager?.removeEventListener()
    }

    public func addUnread(listener: any IQChannelsUnreadListenerProtocol) {
        channelManager?.addUnread(listener: listener)
    }
    
    public func removeUnread(listener: any IQChannelsUnreadListenerProtocol) {
        channelManager?.removeUnread(listener: listener)
    }
    
    public func addAdvancedUnread(listener: any IQChannelsAdvancedUnreadListenerProtocol) {
        channelManager?.getAdvancedUnread()
        channelManager?.addAdvancedUnread(listener: listener)
    }
    
    public func removeAdvancedUnread(listener: any IQChannelsAdvancedUnreadListenerProtocol) {
        channelManager?.removeAdvancedUnread(listener: listener)
    }
    
    public func pushToken(_ token: Data?) {
        channelManager?.pushToken(token)
    }
    
    public func setTheme(_ styleType: IQTheme) {
        IQStyle.newTheme(styleType)
    }
}

extension IQLibraryConfigurationProtocol {
    public func login(_ loginType: IQLoginType) {
        login(loginType, nil)
    }
}
