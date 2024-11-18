//
//  TextSystemMessageCellView.swift
//  Pods
//
//  Created by  Mikhail Zinkov on 11.11.2024.
//

import SwiftUI

private let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

struct TextSystemMessageCellView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    private let message: IQMessage
    private let text: String
    
    var textColor: UIColor {
        let textSystem = Style.getUIColor(theme: Style.model?.chat?.systemText?.color) ?? UIColor(hex: "888888")
        return textSystem
    }
    
    var fontSize: CGFloat {
        let sizeSystem = CGFloat(Style.model?.chat?.systemText?.textSize ?? 17)
        return sizeSystem
    }
    
    // MARK: - INIT
    init (message: IQMessage) {
        self.message = message
        self.text = message.messageText    }
    
    // MARK: - BODY
    var body: some View {
        let data = AttributeTextManager.shared.getString(from: text,
                                                         textColor: textColor,
                                                         fontSize: fontSize)
        TextLabel(text: data.0,
                  linkRanges: data.1)
        .layoutPriority(1)
        .padding(.vertical, 8)
    }
}
