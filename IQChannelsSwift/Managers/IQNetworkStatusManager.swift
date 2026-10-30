//
//  IQNetworkStatusManager.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 09.05.2024.
//

import Foundation
import Network

class IQNetworkStatusManager {
    
    weak var delegate: IQNetworkStatusManagerDelegate?
    
    private var monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .userInteractive)
    private var stuckPathWorkItem: DispatchWorkItem?
    
    var isReachable: Bool {
        status != .notReachable
    }
    
    var status: IQNetworkStatus = .notReachable
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stuckPathWorkItem?.cancel()
        monitor.cancel()
    }
    
    private func startMonitoring() {
        attachHandler()
        monitor.start(queue: queue)
    }
    
    private func attachHandler() {
        monitor.pathUpdateHandler = { [weak self] path in
            let status: IQNetworkStatus = path.status == .satisfied ? .reachable : .notReachable
            if self?.status != status {
                self?.status = status
                    self?.delegate?.networkStatusChanged(status)
            } else {
                self?.status = status
            }
            self?.scheduleStuckPathRecheck()
        }
    }
    
    // симулятор не всегда рассылает обновления пути при восстановлении интерфейса
    private func scheduleStuckPathRecheck() {
        stuckPathWorkItem?.cancel()
        guard status == .notReachable else { return }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.status == .notReachable else { return }
            self.monitor.cancel()
            self.monitor = NWPathMonitor()
            self.attachHandler()
            self.monitor.start(queue: self.queue)
        }
        stuckPathWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 5, execute: workItem)
    }
    
}
