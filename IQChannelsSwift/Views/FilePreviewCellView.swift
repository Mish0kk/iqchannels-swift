import SwiftUI
import SDWebImageSwiftUI

struct FilePreviewCellView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    private let message: IQMessage
    private let replyMessage: IQMessage?
    private let onFileTapCompletion: (() -> Void)?
    private let onCancelFileSendCompletion: (() -> Void)?
    private let onReplyMessageTapCompletion: ((Int) -> Void)?
    private let text: String
    private let isSender: Bool
    
    @State private var showMessageLoading: Bool = false
    @State private var cachedText: (NSAttributedString, [Link])?
    
    private func loadText() {
        let result = AttributeTextManager.shared.getString(
            from: message.text ?? "",
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
        let backgroundOperator = IQStyle.getColor(theme: IQStyle.model?.messages?.backgroundOperator?.color) ?? Color(hex: "F4F4F8")
        let backgroundClient = IQStyle.getColor(theme: IQStyle.model?.messages?.backgroundClient?.color) ?? Color(hex: "242729")
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
    
    
    
    var fileNameTextColor: Color {
        let clientColor = IQStyle.getColor(theme: IQStyle.model?.messagesFile?.textFilenameClient?.color) ?? Color.white
        let operatorColor = IQStyle.getColor(theme: IQStyle.model?.messagesFile?.textFilenameOperator?.color) ?? Color(hex: "242729")
        return self.isSender ? clientColor : operatorColor
    }
    var fileNameFontSize: CGFloat {
        let clientFontSize = CGFloat(IQStyle.model?.messagesFile?.textFilenameClient?.textSize ?? 17)
        let operatorFontSize = CGFloat(IQStyle.model?.messagesFile?.textFilenameOperator?.textSize ?? 17)
        return self.isSender ? clientFontSize : operatorFontSize
    }
    var fileNameIsBold: Bool {
        let clientIsBold = IQStyle.model?.messagesFile?.textFilenameClient?.textStyle?.bold ?? false
        let operatorIsBold = IQStyle.model?.messagesFile?.textFilenameOperator?.textStyle?.bold ?? false
        return self.isSender ? clientIsBold : operatorIsBold
    }
    var fileNameIsItalic: Bool {
        let clientIsItalic = IQStyle.model?.messagesFile?.textFilenameClient?.textStyle?.italic ?? false
        let operatorIsItalic = IQStyle.model?.messagesFile?.textFilenameOperator?.textStyle?.italic ?? false
        return self.isSender ? clientIsItalic : operatorIsItalic
    }
    var fileNameAligment: TextAlignment {
        let clientAlignment = stringToAlignment(stringAlignment: IQStyle.model?.messagesFile?.textFilenameClient?.textAlign) ?? .leading
        let operatorAlignment = stringToAlignment(stringAlignment: IQStyle.model?.messagesFile?.textFilenameOperator?.textAlign) ?? .leading
        return self.isSender ? clientAlignment : operatorAlignment
    }
    
    
    
    var fileIcon: URL? {
        let clientFile = IQStyle.model?.messagesFile?.iconFileClient
        let operatorFile = IQStyle.model?.messagesFile?.iconFileOperator
        return self.isSender ? clientFile : operatorFile
    }
    
    
    
    var fileSizeTextColor: Color {
        let clientColor = IQStyle.getColor(theme: IQStyle.model?.messagesFile?.textFileSizeClient?.color) ?? Color(hex: "919399")
        let operatorColor = IQStyle.getColor(theme: IQStyle.model?.messagesFile?.textFileSizeOperator?.color) ?? Color(hex: "919399")
        return self.isSender ? clientColor : operatorColor
    }
    var fileSizeFontSize: CGFloat {
        let clientFontSize = CGFloat(IQStyle.model?.messagesFile?.textFileSizeClient?.textSize ?? 15)
        let operatorFontSize = CGFloat(IQStyle.model?.messagesFile?.textFileSizeOperator?.textSize ?? 15)
        return self.isSender ? clientFontSize : operatorFontSize
    }
    var fileSizeIsBold: Bool {
        let clientIsBold = IQStyle.model?.messagesFile?.textFileSizeClient?.textStyle?.bold ?? false
        let operatorIsBold = IQStyle.model?.messagesFile?.textFileSizeOperator?.textStyle?.bold ?? false
        return self.isSender ? clientIsBold : operatorIsBold
    }
    var fileSizeIsItalic: Bool {
        let clientIsItalic = IQStyle.model?.messagesFile?.textFileSizeClient?.textStyle?.italic ?? false
        let operatorIsItalic = IQStyle.model?.messagesFile?.textFileSizeOperator?.textStyle?.italic ?? false
        return self.isSender ? clientIsItalic : operatorIsItalic
    }
    var fileSizeAlignment: TextAlignment {
        let clientAlignment = stringToAlignment(stringAlignment: IQStyle.model?.messagesFile?.textFileSizeClient?.textAlign) ?? .leading
        let operatorAlignment = stringToAlignment(stringAlignment: IQStyle.model?.messagesFile?.textFileSizeOperator?.textAlign) ?? .leading
        return self.isSender ? clientAlignment : operatorAlignment
    }
    
    
    
    // MARK: - INIT
    init(message: IQMessage,
         replyMessage: IQMessage? = nil,
         onFileTapCompletion: (() -> Void)? = nil,
         onCancelFileSendCompletion: (() -> Void)? = nil,
         onReplyMessageTapCompletion: ((Int) -> Void)? = nil) {
        self.message = message
        self.replyMessage = replyMessage
        self.onFileTapCompletion = onFileTapCompletion
        self.onCancelFileSendCompletion = onCancelFileSendCompletion
        self.onReplyMessageTapCompletion = onReplyMessageTapCompletion
        self.text = message.text ?? ""
        self.isSender = message.isMy ?? false
    }
    
    // MARK: - BODY
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                    if let replyMessage {
                        MessageReplyView(message: replyMessage,
                                         isMy: message.isMy ?? false,
                                         onReplyMessageTapCompletion: onReplyMessageTapCompletion)
                    }
                    
                    if let file = message.file {
                        getApprovedStateView(file)
                    }
                }
                
                if(text != ""){

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
                            Text("")
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
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: message.file?.isLoading)
        .onTapGesture {
            if let file = message.file {
                if let state = file.state {
                    if state == .approved {
                        onFileTapCompletion?()
                    }
                } else {
                    onFileTapCompletion?()
                }
            }
        }
    }
    
    // MARK: - VIEWS
    @ViewBuilder
    private func getApprovedStateView(_ file: IQFile) -> some View {
        HStack(spacing: 8) {
            if file.isLoading {
                Button {
                    onCancelFileSendCompletion?()
                } label: {
                    ZStack {
                        Image(name: "loading")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .rotationEffect(Angle(degrees: showMessageLoading ? 360 : 0.0))
                        
                        Image(name: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    }
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: showMessageLoading)
                    .onAppear { self.showMessageLoading = true }
                }
            } else {
                if let fileIcon {
                    AnimatedImage(url: fileIcon)
                        .resizable()
                        .indicator(SDWebImageActivityIndicator.gray)
                        .transition(SDWebImageTransition.fade)
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else {
                    Image(name: "file")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(fileNameTextColor)
                        .frame(width: 32, height: 32)
                }
            }
            
            VStack(alignment: textAlignmentToHorizontalAlignment(textAlignment: fileSizeAlignment), spacing: 4) {
                if #available(iOS 16.0, *) {
                    Text(file.name ?? "")
                        .foregroundColor(fileNameTextColor)
                        .font(.system(size: fileNameFontSize))
                        .bold(fileNameIsBold)
                        .italic(fileNameIsItalic)
                        .multilineTextAlignment(fileNameAligment)
                } else {
                    Text(file.name ?? "")
                        .foregroundColor(fileNameTextColor)
                        .font(.system(size: fileNameFontSize))
                        .multilineTextAlignment(fileNameAligment)
                }
                
                if #available(iOS 16.0, *) {
                    Text(file.convertedSize)
                        .foregroundColor(fileSizeTextColor)
                        .font(.system(size: fileSizeFontSize))
                        .bold(fileSizeIsBold)
                        .italic(fileSizeIsItalic)
                        .multilineTextAlignment(fileSizeAlignment)
                        
                } else {
                    Text(file.convertedSize)
                        .foregroundColor(fileSizeTextColor)
                        .font(.system(size: fileSizeFontSize))
                        .multilineTextAlignment(fileSizeAlignment)
                }
            }
        }
    }
    
    @ViewBuilder
    private func getNotApprovedStateView(_ state: IQFileState) -> some View {
        let textColor: Color = isSender ? state.titleClientColor : state.titleOperatorColor
        let fontSize: CGFloat = isSender ? state.titleClientFontSize : state.titleOperatorFontSize
        let alignment: TextAlignment = isSender ? state.titleClientAligment: state.titleOperatorAligment
        let isBold: Bool = isSender ? state.titleClientIsBold : state.titleOperatorIsBold
        let isItalic: Bool = isSender ? state.titleClientIsItalic : state.titleOperatorIsItalic
        
        if #available(iOS 16.0, *) {
            Text(state.title)
                .foregroundColor(textColor)
                .font(.system(size: fontSize))
                .bold(isBold)
                .italic(isItalic)
                .multilineTextAlignment(alignment)
        } else {
            Text(state.title)
                .foregroundColor(textColor)
                .font(.system(size: fontSize))
                .multilineTextAlignment(alignment)
        }
    }
}
