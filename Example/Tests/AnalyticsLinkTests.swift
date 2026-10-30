import XCTest
@testable import IQChannelsSwift

final class AnalyticsLinkTests: XCTestCase {

    func testExtractsSimpleTrackingID() {
        XCTAssertEqual(Self.trackingID("https://example.com/offer?iq_ref=abc123"), "abc123")
    }

    func testExtractsAmongOtherParams() {
        XCTAssertEqual(Self.trackingID("https://example.com/offer?utm_source=x&iq_ref=abc&foo=bar"), "abc")
    }

    func testDecodesPercentEncodedValue() {
        XCTAssertEqual(Self.trackingID("https://example.com/offer?iq_ref=a%2Fb%3Dc"), "a/b=c")
    }

    func testReturnsNilWithoutParam() {
        XCTAssertNil(Self.trackingID("https://example.com/offer?utm_source=x"))
        XCTAssertNil(Self.trackingID("https://example.com/offer"))
    }

    func testReturnsNilForEmptyValue() {
        XCTAssertNil(Self.trackingID("https://example.com/offer?iq_ref="))
        XCTAssertNil(Self.trackingID("https://example.com/offer?iq_ref"))
    }

    func testIgnoresParamInsideFragment() {
        XCTAssertNil(Self.trackingID("https://example.com/offer#?iq_ref=abc"))
        XCTAssertNil(Self.trackingID("https://example.com/offer?a=1#iq_ref=abc"))
    }

    private static func trackingID(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else {
            XCTFail("невалидный URL в тесте: \(urlString)")
            return nil
        }
        return IQAnalyticsLink.trackingID(from: url)
    }
}
