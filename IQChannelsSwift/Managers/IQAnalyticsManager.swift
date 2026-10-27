//
//  IQAnalyticsManager.swift
//  IQChannelsSwift
//

import Foundation

final class IQAnalyticsNetworkTransport: IQAnalyticsTransport {

    private let networkManager: IQNetworkManagerProtocol

    init(networkManager: IQNetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func send(_ event: IQAnalyticsEvent) async -> Result<Void, IQAnalyticsSendError> {
        let response = await networkManager.sendAnalyticsEvent(event)
        guard let error = response.error else {
            return .success(())
        }
        return .failure(IQAnalyticsSendError(statusCode: error.iqHTTPStatusCode, code: error.iqErrorCode))
    }
}

final class IQAnalyticsManager {

    private struct ChannelAnalytics {
        let auth: IQClientAuth
        let sender: IQAnalyticsSender

        var config: IQAnalyticsConfig? { auth.analytics }
    }

    private var channels: [String: ChannelAnalytics] = [:]
    private var source: String?
    private var sourceAttributionSent = false
    private var channelEnterSent = false
    private let isOnline: () -> Bool

    init(isOnline: @escaping () -> Bool = { true }) {
        self.isOnline = isOnline
    }

    func activate(
        results: [(channel: String, auth: IQClientAuth)],
        source: String?,
        transports: [String: IQAnalyticsTransport]
    ) {
        channels = [:]
        for (channel, auth) in results {
            guard let transport = transports[channel] else { continue }
            channels[channel] = ChannelAnalytics(
                auth: auth,
                sender: IQAnalyticsSender(transport: transport)
            )
        }
        self.source = source
        sourceAttributionSent = false
        trackSourceAttributionIfNeeded()
    }

    func allows(channel: String, type: IQAnalyticsEventType) -> Bool {
        guard let item = channels[channel] else { return false }
        return !item.sender.disabled && (item.config?.allows(type) ?? false)
    }

    func thresholdMs(channel: String) -> Int? {
        channels[channel]?.config?.thresholdMs
    }

    func track(channel: String, type: IQAnalyticsEventType, payload: [String: IQAnalyticsJSONValue]?) async {
        guard isOnline(), let item = channels[channel], !item.sender.disabled else { return }
        guard item.config?.allows(type) == true else { return }
        await item.sender.send(
            IQAnalyticsEvent.make(type: type, channelAuth: item.auth, source: source, payload: payload)
        )
    }

    func trackChannelEnterOnce(channel: String, payload: [String: IQAnalyticsJSONValue]?) async {
        guard !channelEnterSent else { return }
        channelEnterSent = true
        await track(channel: channel, type: .channelEnter, payload: payload)
    }

    func trackAll(type: IQAnalyticsEventType, payload: [String: IQAnalyticsJSONValue]?) async {
        var seenProjects = Set<Int>()
        for (channel, item) in channels {
            guard !item.sender.disabled, item.config?.allows(type) == true else { continue }
            let project = item.auth.client?.projectID ?? 0
            guard seenProjects.insert(project).inserted else { continue }
            await item.sender.send(
                IQAnalyticsEvent.make(type: type, channelAuth: item.auth, source: source, payload: payload)
            )
        }
    }

    func reset() {
        channels = [:]
        source = nil
        sourceAttributionSent = false
        channelEnterSent = false
    }

    func flushCaches() async {
        for item in channels.values {
            await item.sender.flushCache()
        }
    }

    private func trackSourceAttributionIfNeeded() {
        guard !sourceAttributionSent, let source, !source.isEmpty else { return }
        var seenProjects = Set<Int>()
        for item in channels.values {
            guard item.config?.allows(.sourceAttribution) == true else { continue }
            let project = item.auth.client?.projectID ?? 0
            guard seenProjects.insert(project).inserted else { continue }
            sourceAttributionSent = true
            let sender = item.sender
            let auth = item.auth
            Task {
                let event = IQAnalyticsEvent.make(
                    type: .sourceAttribution, channelAuth: auth, source: source, payload: nil
                )
                await sender.send(event)
            }
        }
    }
}
