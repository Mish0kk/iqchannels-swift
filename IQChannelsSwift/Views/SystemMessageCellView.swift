//
//  SystemMessageCellView.swift
//  Pods
//
//  Created by  Mikhail Zinkov on 11.11.2024.
//

import SwiftUI

struct SystemMessageCellView: View {
    
    // MARK: - PROPERTIES
    @EnvironmentObject var viewModel: IQChatDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var cachedText: (NSAttributedString, [Link])?
    
    private let message: IQMessage
    
    private func loadText() {
        let result = AttributeTextManager.shared.getString(
            from: message.messageText,
            textColor: textColor,
            fontSize: fontSize,
            alingment: aligment,
            isBold: isBold,
            isItalic: isItalic
        )

        DispatchQueue.main.async {
            self.cachedText = result
        }
    }
    
    var textColor: UIColor {
        return IQStyle.getUIColor(theme: IQStyle.model?.chat?.systemText?.color) ?? UIColor(hex: "888888")
    }
    var fontSize: CGFloat {
        return CGFloat(IQStyle.model?.chat?.systemText?.textSize ?? 17)
    }
    var isBold: Bool {
        return IQStyle.model?.chat?.systemText?.textStyle?.bold ?? false
    }
    var isItalic: Bool {
        return IQStyle.model?.chat?.systemText?.textStyle?.italic ?? false
    }
    var aligment: TextAlignment {
        return stringToAlignment(stringAlignment: IQStyle.model?.chat?.systemText?.textAlign) ?? .leading
    }
    
    var backgroundColor: Color {
        return IQStyle.getColor(theme: IQStyle.model?.rating?.backgroundContainer?.color) ?? Color(hex: "F4F4F8")
    }
    
    // MARK: - INIT
    var onLinkTap: ((URL) -> Void)? = nil

    init(message: IQMessage, onLinkTap: ((URL) -> Void)? = nil) {
        self.message = message
        self.onLinkTap = onLinkTap
    }
    
    // MARK: - BODY
    var body: some View {
        Group {
            if let cachedText {
                TextLabel(text: cachedText.0,
                          linkRanges: cachedText.1,
                          onLinkTap: onLinkTap)
                .layoutPriority(1)
                .padding(.vertical, 8)
            } else {
                Text("")
            }
        }
        .onAppear {
            loadText()
        }
        .onChange(of: message) { _ in
            loadText()
        }
    }
}
