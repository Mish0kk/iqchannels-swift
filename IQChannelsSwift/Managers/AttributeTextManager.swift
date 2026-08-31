import UIKit
import SwiftUI

final class AttributeTextManager {
    static let shared: AttributeTextManager = .init()
    
    private init() {}

    func getString(
        from markdown: String,
        textColor: UIColor,
        fontSize: CGFloat,
        alingment: TextAlignment,
        isBold: Bool,
        isItalic: Bool
    ) -> (NSAttributedString, [Link]) {

        var formattedMarkdown = markdown.replacingOccurrences(of: "\\\n", with: "\n")

        // MARK: - Base font

        var symbolicTraits: UIFontDescriptor.SymbolicTraits = []

        if isBold {
            symbolicTraits.insert(.traitBold)
        }

        if isItalic {
            symbolicTraits.insert(.traitItalic)
        }

        var font = UIFont.systemFont(ofSize: fontSize)

        if let descriptor = font.fontDescriptor.withSymbolicTraits(symbolicTraits) {
            font = UIFont(descriptor: descriptor, size: fontSize)
        }

        // MARK: - Alignment

        let textAlignments: [TextAlignment: NSTextAlignment] = [
            .leading: .left,
            .center: .center,
            .trailing: .right
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignments[alingment] ?? .left

        // MARK: - Link attributes

        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .underlineColor: textColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        // MARK: - Create attributed string

        let attributedString: NSMutableAttributedString

        if let data = formattedMarkdown.data(using: .utf8),
           let htmlString = try? NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
           ) {

            attributedString = htmlString

        } else {
            attributedString = NSMutableAttributedString(string: formattedMarkdown)
        }

        var linkRanges: [Link] = []

        // MARK: - Base attributes

        attributedString.addAttributes(
            [
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ],
            range: NSRange(
                location: 0,
                length: attributedString.length
            )
        )

        // MARK: - Process fonts

        attributedString.enumerateAttribute(
            .font,
            in: NSRange(
                location: 0,
                length: attributedString.length
            )
        ) { value, range, _ in

            let currentFont = value as? UIFont
                ?? UIFont.systemFont(ofSize: fontSize)

            let traits = currentFont.fontDescriptor.symbolicTraits

            let descriptor = UIFont.systemFont(ofSize: fontSize)
                .fontDescriptor
                .withSymbolicTraits(traits)

            let newFont = descriptor.map {
                UIFont(descriptor: $0, size: fontSize)
            } ?? UIFont.systemFont(ofSize: fontSize)

            attributedString.addAttribute(
                .font,
                value: newFont,
                range: range
            )
        }

        // MARK: - Extract HTML links

        attributedString.enumerateAttribute(
            .link,
            in: NSRange(
                location: 0,
                length: attributedString.length
            )
        ) { value, range, _ in

            let urlString: String?

            if let url = value as? URL {
                urlString = url.absoluteString
            } else if let string = value as? String {
                urlString = string
            } else {
                urlString = nil
            }

            guard let urlString else {
                return
            }

            linkRanges.append(
                (urlString, range)
            )

            attributedString.addAttributes(
                linkAttributes,
                range: range
            )
        }

        // MARK: - Markdown patterns

        let patterns: [(String, [NSAttributedString.Key: Any])] = [

            // Bold
            (
                "\\\\\\* (.*?) \\\\\\*"
                    .replacingOccurrences(of: " ", with: ""),
                [
                    .font: UIFont.systemFont(
                        ofSize: fontSize,
                        weight: .bold
                    )
                ]
            ),

            // Italic
            (
                "\\\\_(.*?)\\\\_",
                [
                    .font: UIFont.italicSystemFont(
                        ofSize: fontSize
                    )
                ]
            ),

            // Code
            (
                "`(.*?)`",
                [
                    .font: UIFont(
                        name: "Courier",
                        size: UIFont.systemFontSize
                    ) ?? UIFont.systemFont(ofSize: fontSize)
                ]
            ),

            // Markdown link
            (
                "\\[([^\\]]+)\\]\\(([^\\)]+)\\)",
                [:]
            )
        ]

        // MARK: - Apply Markdown attributes

        func applyAttributes(
            to matches: [NSTextCheckingResult],
            in text: NSMutableAttributedString,
            attributes: [NSAttributedString.Key: Any],
            pattern: String
        ) {

            for match in matches.reversed() {

                // Markdown link
                if pattern == "\\[([^\\]]+)\\]\\(([^\\)]+)\\)" {

                    if match.numberOfRanges == 3 {

                        let linkTextRange = match.range(at: 1)
                        let linkURLRange = match.range(at: 2)

                        let linkText = text
                            .attributedSubstring(from: linkTextRange)
                            .string

                        let linkURL = text
                            .attributedSubstring(from: linkURLRange)
                            .string

                        guard !linkText.isEmpty,
                              !linkURL.isEmpty else {
                            continue
                        }

                        let encodedURL = linkURL
                            .addingPercentEncoding(
                                withAllowedCharacters: .urlQueryAllowed
                            ) ?? linkURL

                        let urlString = encodedURL.hasPrefix("http")
                            ? encodedURL
                            : "http://\(encodedURL)"

                        linkRanges.append(
                            (urlString, linkTextRange)
                        )

                        text.setAttributes(
                            linkAttributes,
                            range: linkTextRange
                        )

                        let replacementText = text
                            .attributedSubstring(
                                from: linkTextRange
                            )

                        text.replaceCharacters(
                            in: match.range,
                            with: replacementText
                        )
                    }

                } else {
                    // Bold / italic / code
                    text.addAttributes(
                        attributes,
                        range: match.range(at: 1)
                    )

                    let fullRange = match.range

                    let replacementText = text
                        .attributedSubstring(
                            from: match.range(at: 1)
                        )

                    text.replaceCharacters(
                        in: fullRange,
                        with: replacementText
                    )
                }
            }
        }

        // MARK: - Lists

        func formatStringWithList(_ input: String) -> String {

            let lines = input.components(
                separatedBy: "\n"
            )

            var formattedLines = [String]()

            for line in lines {

                let trimmedLine = line
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                if trimmedLine.hasPrefix("*") {

                    let text = trimmedLine
                        .dropFirst()
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                    formattedLines.append(
                        "• \(text)"
                    )

                } else if trimmedLine.first?.isNumber ?? false {

                    formattedLines.append(
                        trimmedLine
                    )
                }
            }

            return formattedLines.joined(
                separator: "\n"
            )
        }

        // MARK: - Check list

        func isList(_ input: String) -> Bool {
            let pattern = "(\\\n\\*|\\\n\\d+\\.)"

            let regex = try? NSRegularExpression(
                pattern: pattern,
                options: []
            )

            return (
                regex?.firstMatch(
                    in: input,
                    options: [],
                    range: NSRange(
                        location: 0,
                        length: input.utf16.count
                    )
                ) != nil
            )
        }

        // MARK: - Apply patterns

        for (pattern, attributes) in patterns {

            do {

                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: []
                )

                let matches = regex.matches(
                    in: attributedString.string,
                    options: [],
                    range: NSRange(
                        location: 0,
                        length: attributedString.length
                    )
                )

                applyAttributes(
                    to: matches,
                    in: attributedString,
                    attributes: attributes,
                    pattern: pattern
                )

            } catch {

                print(
                    "Invalid regex pattern: \(pattern)"
                )
            }
        }

        // MARK: - Generic links

        let linkPatterns = [
            #"https?:\/\/[^\s/$.?#].[^\s]*"#
        ]

        for pattern in linkPatterns {

            do {

                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: []
                )

                let matches = regex.matches(
                    in: attributedString.string,
                    options: [],
                    range: NSRange(
                        location: 0,
                        length: (attributedString.string as NSString).length
                    )
                )

                for match in matches.reversed() {

                    let linkRange = match.range(at: 0)

                    let linkText = attributedString
                        .attributedSubstring(
                            from: linkRange
                        )
                        .string

                    let urlString = linkText.hasPrefix("http")
                        ? linkText
                        : "http://\(linkText)"

                    linkRanges.append(
                        (urlString, linkRange)
                    )

                    attributedString.setAttributes(
                        linkAttributes,
                        range: linkRange
                    )
                }

            } catch {

                print(
                    "Invalid regex pattern: \(pattern)"
                )
            }
        }

        return (
            attributedString,
            linkRanges
        )
    }
}
