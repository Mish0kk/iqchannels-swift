import SwiftUI

struct MultiFilesMessageCellView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    private let message: IQMessage
    private let replyMessage: IQMessage?
    private let files: [IQFile]
    private var sessionToken: String
    private weak var delegate: ChatDetailViewDelegate?
    private let onReplyMessageTapCompletion: ((Int) -> Void)?
    
    private let text: String
    private let isSender: Bool
    
    @State private var cachedText: (NSAttributedString, [Link])?
    
    private func loadText() {
        let textColor = self.textColor
        let fontSize = self.fontSize
        let aligment = self.aligment
        let isBold = self.isBold
        let isItalic = self.isItalic
        let rawText = message.text ?? ""
        
        DispatchQueue.global().async {
            let result = AttributeTextManager.shared.getString(
                from: rawText,
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
    }
    
    var textColor: UIColor {
        let textOperator = IQStyle.getUIColor(theme: IQStyle.model?.messages?.textOperator?.color) ?? UIColor(hex: "242729")
        let textClient = IQStyle.getUIColor(theme: IQStyle.model?.messages?.textClient?.color) ?? UIColor.white
        return self.isSender ? textClient : textOperator
    }
    var fontSize: CGFloat {
        let sizeOperator = CGFloat(IQStyle.model?.messages?.textOperator?.textSize ?? 17)
        let sizeClient = CGFloat(IQStyle.model?.messages?.textClient?.textSize ?? 17)
        return self.isSender ? sizeClient : sizeOperator
    }
    var isBold: Bool {
        let clientIsBold = IQStyle.model?.messages?.textClient?.textStyle?.bold ?? false
        let operatorIsBold = IQStyle.model?.messages?.textOperator?.textStyle?.bold ?? false
        return self.isSender ? clientIsBold : operatorIsBold
    }
    var isItalic: Bool {
        let clientIsItalic = IQStyle.model?.messages?.textClient?.textStyle?.italic ?? false
        let operatorIsItalic = IQStyle.model?.messages?.textOperator?.textStyle?.italic ?? false
        return self.isSender ? clientIsItalic : operatorIsItalic
    }
    var aligment: TextAlignment {
        let clientAlignment = stringToAlignment(stringAlignment: IQStyle.model?.messages?.textClient?.textAlign) ?? .leading
        let operatorAlignment = stringToAlignment(stringAlignment: IQStyle.model?.messages?.textOperator?.textAlign) ?? .leading
        return self.isSender ? clientAlignment : operatorAlignment
    }
    
    var backgroundColor: Color {
        let backgroundClient = IQStyle.getColor(theme: IQStyle.model?.messages?.backgroundClient?.color) ?? Color(hex: "242729")
        let backgroundOperator = IQStyle.getColor(theme: IQStyle.model?.messages?.backgroundOperator?.color) ?? Color(hex: "F4F4F8")
        return self.isSender ? backgroundClient : backgroundOperator
    }
    var backgroundRadius: CGFloat {
        let backgroundOperator = IQStyle.model?.messages?.backgroundOperator?.border?.borderRadius ?? 12
        let backgroundClient = IQStyle.model?.messages?.backgroundClient?.border?.borderRadius ?? 12
        return self.isSender ? backgroundClient : backgroundOperator
    }
    var backgroundBorderSize: CGFloat {
        let backgroundOperator = IQStyle.model?.messages?.backgroundOperator?.border?.size ?? 0
        let backgroundClient = IQStyle.model?.messages?.backgroundClient?.border?.size ?? 0
        return self.isSender ? backgroundClient : backgroundOperator
    }
    var backgroundBorderColor: Color {
        let backgroundOperator = IQStyle.getColor(theme: IQStyle.model?.messages?.backgroundOperator?.border?.color) ?? Color(hex: "000000")
        let backgroundClient = IQStyle.getColor(theme: IQStyle.model?.messages?.backgroundClient?.border?.color) ?? Color(hex: "000000")
        return self.isSender ? backgroundClient : backgroundOperator
    }
    
    // MARK: - INIT
    init(message: IQMessage,
         replyMessage: IQMessage? = nil,
         files: [IQFile],
         sessionToken: String,
         delegate: ChatDetailViewDelegate? = nil,
         onReplyMessageTapCompletion: ((Int) -> Void)? = nil) {
        self.message = message
        self.replyMessage = replyMessage
        self.files = files
        self.sessionToken = sessionToken
        self.delegate = delegate
        self.onReplyMessageTapCompletion = onReplyMessageTapCompletion
        self.text = message.text ?? ""
        self.isSender = message.isMy ?? false
    }
    
    // MARK: - BODY
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            VStack(alignment: .leading, spacing: 8) {
                if let replyMessage {
                    MessageReplyView(message: replyMessage,
                                     isMy: message.isMy ?? false,
                                     onReplyMessageTapCompletion: onReplyMessageTapCompletion)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(files.enumerated()), id: \.offset) { _, file in
                        getFileView(file)
                    }
                }
                
                if text != "" {
                    Group {
                        if let cachedText {
                            if #available(iOS 16.0, *) {
                                TextLabel(text: cachedText.0,
                                          linkRanges: cachedText.1)
                                .layoutPriority(1)
                                .bold(isBold)
                                .italic(isItalic)
                            } else {
                                TextLabel(text: cachedText.0,
                                          linkRanges: cachedText.1)
                                .layoutPriority(1)
                            }
                        } else {
                            PlainMessageText(text: text,
                                             textColor: textColor,
                                             fontSize: fontSize,
                                             aligment: aligment,
                                             isBold: isBold,
                                             isItalic: isItalic)
                            .layoutPriority(1)
                        }
                    }
                    .onAppear {
                        loadText()
                    }
                }
            }
            MessageStatusView(message: message)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(backgroundRadius)
        .overlay(
            RoundedRectangle(cornerRadius: backgroundRadius)
                .stroke(backgroundBorderColor, lineWidth: backgroundBorderSize)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: files.first?.isLoading)
    }
    
    // MARK: - VIEWS
    @ViewBuilder
    private func getFileView(_ file: IQFile) -> some View {
        if file.isImage {
            MediaMessageCellView(message: message,
                                 file: file,
                                 embedded: true) {
                delegate?.onFileTap(file, sessionToken: sessionToken)
            } onCancelImageSendCompletion: {
                delegate?.onCancelUpload(message)
            }
        } else if file.isFile {
            FilePreviewCellView(message: message,
                                file: file,
                                embedded: true) {
                delegate?.onFileTap(file, sessionToken: sessionToken)
            } onCancelFileSendCompletion: {
                delegate?.onCancelUpload(message)
            }
        }
    }
}
