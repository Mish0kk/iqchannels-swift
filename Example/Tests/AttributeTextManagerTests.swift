import XCTest
import UIKit
@testable import IQChannelsSwift

final class AttributeTextManagerTests: XCTestCase {

    private func lineCount(_ string: String) -> Int {
        string
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .count
    }

    private func makePlain(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        return NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    private func height(_ attributed: NSAttributedString, width: CGFloat) -> CGFloat {
        attributed
            .boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            .height
    }

    func testMultilineTextPreservesLineBreaks() {
        let text = "первая строка\nвторая строка\nтретья"

        let result = AttributeTextManager.shared.getString(
            from: text,
            textColor: .black,
            fontSize: 17,
            alingment: .leading,
            isBold: false,
            isItalic: false
        )

        XCTAssertGreaterThanOrEqual(lineCount(result.0.string), 3)
    }

    func testCRLFMultilineTextPreservesLineBreaks() {
        let text = "первая строка\r\nвторая строка"

        let result = AttributeTextManager.shared.getString(
            from: text,
            textColor: .black,
            fontSize: 17,
            alingment: .leading,
            isBold: false,
            isItalic: false
        )

        XCTAssertGreaterThanOrEqual(lineCount(result.0.string), 2)
    }

    func testMultilineMessageHeightMatchesPlainText() {
        let text = "первая строка достаточно длинная чтобы переноситься"
            + " на новую строку при узкой ширине\nвторая строка\nтретья"
        let width: CGFloat = 250

        let result = AttributeTextManager.shared.getString(
            from: text,
            textColor: .black,
            fontSize: 17,
            alingment: .leading,
            isBold: false,
            isItalic: false
        )

        let plainHeight = height(makePlain(text), width: width)
        let attributedHeight = height(result.0, width: width)

        XCTAssertEqual(attributedHeight, plainHeight, accuracy: 1.0)
    }

    func testPlaceholderHeightMatchesFinalHeightForLongUnspacedMultilineText() {
        let longLine = "ывраарвлыаыворавыолывраарвлыаыворавыолывраарвлыаыворавыолывраарвлыаыворавыол"
        let text = (0..<6).map { _ in longLine }.joined(separator: "\n")
        let width = UIScreen.screenWidth / 1.5 - 24

        let final = AttributeTextManager.shared.getString(
            from: text,
            textColor: .black,
            fontSize: 17,
            alingment: .leading,
            isBold: false,
            isItalic: false
        ).0

        let placeholder = AttributeTextManager.shared.plainString(
            from: text,
            textColor: .black,
            fontSize: 17,
            alingment: .leading,
            isBold: false,
            isItalic: false
        )

        XCTAssertEqual(
            height(final, width: width),
            height(placeholder, width: width),
            accuracy: 1.0
        )
    }

    func testSingleLineTextContentPreserved() {
        let text = "обычное сообщение без переносов"

        let result = AttributeTextManager.shared.getString(
            from: text,
            textColor: .black,
            fontSize: 17,
            alingment: .leading,
            isBold: false,
            isItalic: false
        )

        XCTAssertEqual(result.0.string, text)
    }

    func testLinkDetectionStillWorksOnMultilineText() {
        let text = "смотри https://example.com/page\nвторая строка"

        let result = AttributeTextManager.shared.getString(
            from: text,
            textColor: .black,
            fontSize: 17,
            alingment: .leading,
            isBold: false,
            isItalic: false
        )

        XCTAssertTrue(result.1.contains { $0.0.contains("example.com") })
        XCTAssertGreaterThanOrEqual(lineCount(result.0.string), 2)
    }
}
