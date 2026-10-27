import UIKit

#if canImport(IQChannelsObjC)
import IQChannelsObjC
#endif

class IQEventSourceManager: NSObject, TRVSEventSourceDelegate {

    typealias Callback = (Data?, Error?) -> Void

    private var callback: Callback?
    private var onOpen: (() -> Void)

    private(set) var eventSource: TRVSEventSource?

    private var watchdogTimer: DispatchWorkItem?
    private var hasReceivedPing = false

    private let watchdogTimeout: TimeInterval = 60

    init(
        url: URL,
        authToken: String?,
        customHeaders: [String: String]? = nil,
        onOpen: @escaping (() -> Void),
        callback: @escaping Callback
    ) {
        self.callback = callback
        self.onOpen = onOpen

        super.init()

        var additionalHeaders = [
            "Authorization": "Client \(authToken ?? "")"
        ]

        if let customHeaders = customHeaders {
            additionalHeaders.merge(customHeaders) { (_, new) in new }
        }

        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = additionalHeaders

        eventSource = TRVSEventSource(
            url: url,
            sessionConfiguration: config
        )

        eventSource?.delegate = self
        eventSource?.open()
    }

    deinit {
        stopWatchdog()
        eventSource?.close()
    }

    func close() {
        stopWatchdog()
        eventSource?.close()
    }

    // MARK: - TRVSEventSourceDelegate

    func eventSourceDidOpen(_ eventSource: TRVSEventSource) {
        onOpen()
    }

    func eventSourceDidClose(_ eventSource: TRVSEventSource) {
        stopWatchdog()
    }

    func eventSource(
        _ eventSource: TRVSEventSource,
        didReceive event: TRVSServerSentEvent
    ) {
        if event.event == "ping" {
            IQLog.debug(message: "SSE ping received")

            hasReceivedPing = true

            resetWatchdog()

            return
        }

        if hasReceivedPing {
            resetWatchdog()
        }

        callback?(event.data, nil)
    }

    func eventSource(
        _ eventSource: TRVSEventSource,
        didFailWithError error: Error?
    ) {
        stopWatchdog()

        var finalError: Error? = error

        if error?.localizedDescription.isEmpty ?? true {
            finalError = NSError.clientError(
                "Unknown event stream error"
            )
        }

        callback?(nil, finalError)
    }

    // MARK: - Watchdog

    private func resetWatchdog() {
        watchdogTimer?.cancel()

        let watchdog = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            IQLog.error(
                message: "SSE watchdog timeout. Closing connection."
            )

            self.eventSource?.close()

            self.callback?(
                nil,
                NSError.clientError("SSE watchdog timeout")
            )
        }

        watchdogTimer = watchdog

        DispatchQueue.main.asyncAfter(
            deadline: .now() + watchdogTimeout,
            execute: watchdog
        )
    }

    private func stopWatchdog() {
        watchdogTimer?.cancel()
        watchdogTimer = nil
    }
}
