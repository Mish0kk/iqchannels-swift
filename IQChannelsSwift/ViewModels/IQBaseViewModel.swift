//
//  IQBaseViewModel.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 18.05.2024.
//

import Combine

class IQBaseViewModel: ObservableObject {
//    @Published var state: IQChannelsState = .awaitingNetwork
    @Published var state: IQChannelsState = .authenticated
    @Published var infoChatSettings: IQInfoChatSettings? = nil
    var errorListener = PassthroughSubject<Error, Never>()
}

extension Sequence where Element == IQBaseViewModel {
    func setState(_ state: IQChannelsState) {
        forEach { $0.state = state }
    }
    
    func setState(_ infoChatSettings: IQInfoChatSettings?) {
        forEach { $0.infoChatSettings = infoChatSettings }
    }
    
    func sendError(_ error: Error) {
        forEach { $0.errorListener.send(error) }
    }
}
