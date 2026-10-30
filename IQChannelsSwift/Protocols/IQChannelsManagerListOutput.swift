//
//  IQChannelsManagerListOutput.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 09.05.2024.
//

import Foundation

protocol IQChannelsManagerListOutput {
    func listController(didSelectChat item: IQChatItemModel)
    func listControllerDismissChat()
    func listControllerDidAppear()
}
