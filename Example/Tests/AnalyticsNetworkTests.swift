import XCTest
@testable import IQChannelsSwift

final class AnalyticsNetworkTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testNon2xxErrorCarriesStatusCodeAndBodyCode() async {
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test/x")!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"OK":false,"Error":{"Code":"forbidden","Text":"Аналитика отключена"}}"#.utf8))
        }

        let error = await lastPostError()

        XCTAssertEqual(error?.iqHTTPStatusCode, 403)
        XCTAssertEqual(error?.iqErrorCode, "forbidden")
        XCTAssertEqual(error?.iqAppError?.text, "Аналитика отключена")
        XCTAssertFalse(error?.localizedDescription.isEmpty ?? true)
    }

    func testNon2xxEmptyBodyCarriesStatusCodeWithoutCode() async {
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test/x")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let error = await lastPostError()

        XCTAssertEqual(error?.iqHTTPStatusCode, 500)
        XCTAssertNil(error?.iqErrorCode)
        XCTAssertNil(error?.iqAppError)
    }

    func testNon2xxUnparseableBodyCarriesStatusCode() async {
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test/x")!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, Data("not-json".utf8))
        }

        let error = await lastPostError()

        XCTAssertEqual(error?.iqHTTPStatusCode, 422)
        XCTAssertNil(error?.iqErrorCode)
    }

    func testSuccessResponseHasNoError() async {
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test/x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let manager = Self.makeManager()
        let response = await manager.post(
            "/x", body: Optional<[String: String]>.none, responseType: IQEmptyResponse.self
        )

        XCTAssertNil(response.error)
    }

    private func lastPostError() async -> Error? {
        let manager = Self.makeManager()
        let response = await manager.post(
            "/x", body: Optional<[String: String]>.none, responseType: IQEmptyResponse.self
        )
        return response.error
    }

    private static func makeManager() -> IQNetworkManager {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return IQNetworkManager(address: "https://test", channel: "c", urlSession: session)
    }
}

final class MockURLProtocol: URLProtocol {

    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data?))?

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
