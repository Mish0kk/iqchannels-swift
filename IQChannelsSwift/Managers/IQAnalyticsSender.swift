//
//  IQAnalyticsSender.swift
//  IQChannelsSwift
//

import Foundation

struct IQAnalyticsSendError: Error {
    var statusCode: Int?
    var code: String?
}

protocol IQAnalyticsTransport: AnyObject {
    func send(_ event: IQAnalyticsEvent) async -> Result<Void, IQAnalyticsSendError>
}

actor IQAnalyticsSender {

    static let maxCachedEvents = 3
    static let retryDelay: TimeInterval = 2
    static let analyticsDisabledCode = "forbidden"

    private let transport: IQAnalyticsTransport
    private let maxCached: Int
    private let retryDelay: TimeInterval
    private let delay: (TimeInterval) async -> Void

    private(set) var disabled = false
    private var cache: [IQAnalyticsEvent] = []
    private var flushing = false

    var pendingCacheEventIDs: [String] {
        cache.map(\.eventID)
    }

    init(
        transport: IQAnalyticsTransport,
        maxCached: Int = IQAnalyticsSender.maxCachedEvents,
        retryDelay: TimeInterval = IQAnalyticsSender.retryDelay,
        delay: @escaping (TimeInterval) async -> Void = { seconds in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    ) {
        self.transport = transport
        self.maxCached = maxCached
        self.retryDelay = retryDelay
        self.delay = delay
    }

    func send(_ event: IQAnalyticsEvent) async {
        guard !disabled else { return }
        await attempt(event, isRetry: false)
    }

    func flushCache() async {
        guard !cache.isEmpty, !disabled, !flushing else { return }
        let pending = cache
        cache = []
        flushing = true
        await withTaskGroup(of: Void.self) { group in
            for event in pending {
                group.addTask { [weak self] in
                    await self?.attempt(event, isRetry: false)
                }
            }
        }
        flushing = false
    }

    private func attempt(_ event: IQAnalyticsEvent, isRetry: Bool) async {
        let result = await transport.send(event)
        switch result {
        case .success:
            await flushCache()
        case .failure(let error):
            await handleError(event, error: error, isRetry: isRetry)
        }
    }

    private func handleError(_ event: IQAnalyticsEvent, error: IQAnalyticsSendError, isRetry: Bool) async {
        if isDisabledByServer(error) {
            disabled = true
            cache = []
            IQLog.warn(message: "Аналитика отключена сервером, отправка приостановлена до конца сессии")
            return
        }

        if let status = error.statusCode, (400..<500).contains(status) {
            IQLog.error(message: "Событие аналитики \(event.event.rawValue) отброшено: ошибка клиента \(status)")
            return
        }

        if error.statusCode == nil {
            cacheEvent(event)
            return
        }

        if isRetry {
            let status = error.statusCode ?? 0
            IQLog.error(
                message: "Событие аналитики \(event.event.rawValue) отброшено: повтор не удался, статус \(status)"
            )
            return
        }

        await delay(retryDelay)
        guard !disabled else { return }
        await attempt(event, isRetry: true)
    }

    private func isDisabledByServer(_ error: IQAnalyticsSendError) -> Bool {
        error.statusCode == 403 && error.code == Self.analyticsDisabledCode
    }

    private func cacheEvent(_ event: IQAnalyticsEvent) {
        guard !cache.contains(where: { $0.eventID == event.eventID }) else { return }
        if cache.count >= maxCached {
            let dropped = cache.removeFirst()
            IQLog.warn(message: "Кэш аналитики переполнен, отброшено самое старое событие \(dropped.event.rawValue)")
        }
        cache.append(event)
    }
}
