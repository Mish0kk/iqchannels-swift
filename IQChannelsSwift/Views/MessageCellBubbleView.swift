import SwiftUI

struct MessageCellBubbleView: View {
    
    // MARK: - PROPERTIES
    private let message: IQMessage
    private let replyMessage: IQMessage?
    private let isLastMessage: Bool
    private let onLongPress: ((MessageControlInfo) -> Void)?
    private let onReplyMessageTapCompletion: ((Int) -> Void)?
    private let isSender: Bool
    private let backgroundColor: Color
    private let textColor: Color
    private let secondaryColor: Color
    private var sessionToken: String
    private weak var delegate: ChatDetailViewDelegate?
    
    // MARK: - INIT
    init(message: IQMessage,
         replyMessage: IQMessage?,
         isLastMessage: Bool,
         onLongPress: ((MessageControlInfo) -> Void)? = nil,
         onReplyMessageTapCompletion: ((Int) -> Void)? = nil,
         sessionToken: String,
         delegate: ChatDetailViewDelegate? = nil) {
        self.message = message
        self.replyMessage = replyMessage
        self.isLastMessage = isLastMessage
        self.onLongPress = onLongPress
        self.onReplyMessageTapCompletion = onReplyMessageTapCompletion
        self.isSender = message.isMy ?? false
        self.backgroundColor = self.isSender ? Color(hex: "242729") : Color(hex: "F4F4F8")
        self.textColor = self.isSender ? Color.white : Color(hex: "242729")
        self.secondaryColor = Color(hex: "919399")
        self.sessionToken = sessionToken
        self.delegate = delegate
    }
    
    // MARK: - BODY
    var body: some View {
        switch message.payload {
        case .text:
            TextMessageCellView(message: message,
                                replyMessage: replyMessage,
                                onLongPress: onLongPress,
                                onReplyMessageTapCompletion: onReplyMessageTapCompletion)
        case .file:
            if let files = message.files, files.count > 1 {
                MultiFilesMessageCellView(message: message,
                                          replyMessage: replyMessage,
                                          files: files,
                                          sessionToken: sessionToken,
                                          delegate: delegate,
                                          onReplyMessageTapCompletion: onReplyMessageTapCompletion)
            } else if let file = message.file {
                if file.isImage {
                    MediaMessageCellView(message: message, replyMessage: replyMessage) {
                        delegate?.onFileTap(file, sessionToken: sessionToken)
                    } onCancelImageSendCompletion: {
                        delegate?.onCancelUpload(message)
                    } onReplyMessageTapCompletion: { messageId in
                        onReplyMessageTapCompletion?(messageId)
                    }
                } else if file.isFile {
                    FilePreviewCellView(message: message, replyMessage: replyMessage) {
                        delegate?.onFileTap(file, sessionToken: sessionToken)
                    } onCancelFileSendCompletion: {
                        delegate?.onCancelUpload(message)
                    } onReplyMessageTapCompletion: { messageId in
                        onReplyMessageTapCompletion?(messageId)
                    }
                }
            }
        case .singleChoice:
            if message.isDropDown == true {
                SingleChoicesView(message: message, displaySingleChoices: isLastMessage) { singleChoice in
                    delegate?.onSingleChoiceTap(singleChoice)
                }
            } else {
                StackedSingleChoicesView(message: message) { singleChoice in
                    delegate?.onSingleChoiceTap(singleChoice)
                }
            }
        case .product:
            ProductView(message: message) { productTap in
                delegate?.onProductTap(productTap)
            }
        case .card, .carousel:
            CardCellView(message: message) { action in
                delegate?.onActionTap(action)
            }
        default:
            TextMessageCellView(message: message)
        }
    }
}
