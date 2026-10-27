//
//  IQChatListViewModel.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 08.05.2024.
//

import UIKit
import Combine

class IQChatListViewModel: IQBaseViewModel {
    @Published var chatsInfo: [IQChatItemModel] = []
    @Published var advancedUnread: [Channel] = []
    var chatToPresentListener = CurrentValueSubject<IQChatDetailViewController?, Never>(nil)
    var dismissListener = PassthroughSubject<Void, Never>()
    var popListener = PassthroughSubject<Void, Never>()
}
