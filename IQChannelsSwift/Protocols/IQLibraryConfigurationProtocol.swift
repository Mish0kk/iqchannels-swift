//
//  IQLibraryConfigurationProtocol.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 27.05.2024.
//

import Foundation
import UIKit

public protocol IQLibraryConfigurationProtocol {
    /// Returns the main navigation controller of the library.
    func getViewController() -> UINavigationController?
    /// Returns the library's chat controller.
    func getChatViewController() -> UIViewController?
    /// Configures the library with the provided configuration settings.
    func configure(_ config: IQChannelsConfig)
    /// Sets custom HTTP headers for network requests.
    func setCustomHeaders(_ headers: [String: String])
    /// Logs in the user with the specified login type.
    func login(_ loginType: IQLoginType, _ completion: (() -> Void)?)
    /// Logs out the current user and closes chat.
    func logout()
    /// Adds event listener to handle events
    func addEvent(listener: IQChannelsEventListenerProtocol)
    /// Removes event listener that handles events
    func removeEventListener()
    /// Adds a listener to receive unread message notifications.
    func addUnread(listener: IQChannelsUnreadListenerProtocol)
    /// Removes a listener from receiving unread message notifications.
    func removeUnread(listener: IQChannelsUnreadListenerProtocol)
    /// Adds a listener to receive advanced unread message notifications.
    func addAdvancedUnread(listener: IQChannelsAdvancedUnreadListenerProtocol)
    /// Removes a listener from receiving advanced unread message notifications.
    func removeAdvancedUnread(listener: IQChannelsAdvancedUnreadListenerProtocol)
    /// Pushes the device token for push notifications.
    func pushToken(_ token: Data?)
    /// Set theme
    func setTheme(_ styleType: IQTheme)
}
