import SwiftUI
import Combine
import SDWebImageSwiftUI

struct MediaMessageCellView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    private let message: IQMessage
    private let replyMessage: IQMessage?
    private let file: IQFile?
    private let embedded: Bool
    private let onImageTapCompletion: (() -> Void)?
    private let onCancelImageSendCompletion: (() -> Void)?
    private let onReplyMessageTapCompletion: ((Int) -> Void)?
    private let onLinkTap: ((URL) -> Void)?
    
    private let text: String
    private let isSender: Bool
    
    var currentFile: IQFile? {
        file ?? message.file
    }
    
    @State private var showMessageLoading: Bool = false
    @State private var uiImage: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var cachedText: (NSAttributedString, [Link])? = nil
    
    private func loadText() {
        guard cachedText == nil else { return }
        
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
        let clientIsItalic = stringToAlignment(stringAlignment: IQStyle.model?.messagesFile?.textFilenameClient?.textAlign) ?? .leading
        let operatorIsItalic = stringToAlignment(stringAlignment: IQStyle.model?.messagesFile?.textFilenameOperator?.textAlign) ?? .leading
        return self.isSender ? clientIsItalic : operatorIsItalic
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
    
    
    
    
    // MARK: - INIT
    init(message: IQMessage,
         replyMessage: IQMessage? = nil,
         file: IQFile? = nil,
         embedded: Bool = false,
         onImageTapCompletion: (() -> Void)? = nil,
         onCancelImageSendCompletion: (() -> Void)? = nil,
         onReplyMessageTapCompletion: ((Int) -> Void)? = nil,
         onLinkTap: ((URL) -> Void)? = nil) {
        self.message = message
        self.replyMessage = replyMessage
        self.file = file
        self.embedded = embedded
        self.onImageTapCompletion = onImageTapCompletion
        self.onCancelImageSendCompletion = onCancelImageSendCompletion
        self.onReplyMessageTapCompletion = onReplyMessageTapCompletion
        self.onLinkTap = onLinkTap
        self.text = message.text ?? ""
        self.isSender = message.isMy ?? false
        
        _cachedText = State(initialValue: AttributeTextManager.shared.getStringSync(
            from: message.text ?? "",
            textColor: textColor,
            fontSize: fontSize,
            alingment: aligment,
            isBold: isBold,
            isItalic: isItalic
        ))
    }
    
    // MARK: - BODY
    var body: some View {
        if embedded {
            embeddedBody
        } else {
            fullBody
        }
    }
    
    private var embeddedBody: some View {
        VStack(alignment: .trailing) {
            ZStack(alignment: .bottomTrailing) {
                if let file = currentFile {
                    if let state = file.state {
                        if state == .approved || state == .onChecking{
                            getApprovedStateView(file, state)
                        } else {
                            getNotApprovedStateView(state)
                        }
                    } else {
                        getApprovedStateView(file, nil)
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: currentFile?.isLoading)
        .onTapGesture {
            handleTap()
        }
    }
    
    private var fullBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let replyMessage {
                MessageReplyView(message: replyMessage,
                                 isMy: message.isMy ?? false,
                                 onReplyMessageTapCompletion: onReplyMessageTapCompletion)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            VStack(alignment: .trailing){
                ZStack(alignment: .bottomTrailing) {
                    if let file = currentFile {
                        if let state = file.state {
                            if state == .approved || state == .onChecking{
                                getApprovedStateView(file, state)
                            } else {
                                getNotApprovedStateView(state)
                            }
                        } else {
                            getApprovedStateView(file, nil)
                        }
                        
                        
                        if(text == "" && !file.isLoading){
                            MessageStatusView(message: message, withBackground: uiImage != nil)
                                .padding(8)
                        }
                    }
                }
                
                if(text != ""){

                    Group {
                        if let cachedText {
                            TextLabel(text: cachedText.0,
                                      linkRanges: cachedText.1,
                                      maxWidth: iqMessageTextMaxWidth(isSender: isSender, horizontalInsets: 24),
                                      onLinkTap: onLinkTap)
                            .layoutPriority(1)
                            .padding(.horizontal, 12)
                        } else {
                            PlainMessageText(text: text,
                                             textColor: textColor,
                                             fontSize: fontSize,
                                             aligment: aligment,
                                             isBold: isBold,
                                             isItalic: isItalic)
                            .layoutPriority(1)
                            .padding(.horizontal, 12)
                        }
                    }
                    .onAppear {
                        loadText()
                    }
                    
                    MessageStatusView(message: message)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
        }
        .background(backgroundColor)
        .cornerRadius(backgroundRadius)
        .overlay(
            RoundedRectangle(cornerRadius: backgroundRadius)
                .stroke(backgroundBorderColor, lineWidth: backgroundBorderSize)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: currentFile?.isLoading)
        .onTapGesture {
            handleTap()
        }
    }
    
    private func handleTap() {
        if let uiImage = uiImage {
            if let file = currentFile {
                if let state = file.state {
                    if state == .approved {
                        onImageTapCompletion?()
                    }
                } else {
                    onImageTapCompletion?()
                }
            }
        }
    }
    
    // MARK: - VIEWS
    @ViewBuilder
    private func getApprovedStateView(_ file: IQFile, _ state: IQFileState?) -> some View {
        let imageSize = calculateImageSize(file: currentFile)
        HStack(spacing: 8) {
            if file.isLoading || state == .onChecking{
                    HStack(spacing: 8) {
                        Button {
                            onCancelImageSendCompletion?()
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
                        VStack(alignment: .leading, spacing: 4) {
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
                            } else {
                                Text(file.convertedSize)
                                    .foregroundColor(fileSizeTextColor)
                                    .font(.system(size: fileSizeFontSize))
                            }
                        }
                    }
                    .padding(8)
            } else {
                Group {
                    let textColor = IQStyle.getUIColor(theme: IQStyle.model?.error?.textError?.color) ?? UIColor(hex: "242729")
                    let fontSize = CGFloat(IQStyle.model?.error?.textError?.textSize ?? 17)
                    let isBold = IQStyle.model?.error?.textError?.textStyle?.bold ?? false
                    let isItalic = IQStyle.model?.error?.textError?.textStyle?.italic ?? false
                    let alignment = stringToAlignment(stringAlignment: IQStyle.model?.error?.textError?.textAlign) ?? .leading
                    
                    if isLoading {
                        ProgressView()
                            .frame(width: imageSize.width, height: imageSize.height)
                    } else if let uiImage = uiImage {
                        AnimatedImage(url: currentFile?.imagePreviewUrl)
                            .resizable()
                            .indicator(SDWebImageActivityIndicator.gray)
                            .transition(SDWebImageTransition.fade)
                            .scaledToFill()
                            .frame(width: imageSize.width, height: imageSize.height)
                            .clipped()
                    } else {
                        if #available(iOS 16.0, *) {
                            Text(IQLanguageTexts.model.imageLoadError ?? "Ошибка загрузки")
                                .foregroundColor(.red)
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: text == "" ? 30 : 0, trailing: 10))
                                .bold(isBold)
                                .italic(isItalic)
                                .multilineTextAlignment(alignment)
                        } else {
                            Text(IQLanguageTexts.model.imageLoadError ?? "Ошибка загрузки")
                                .foregroundColor(.red)
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: text == "" ? 30 : 0, trailing: 10))
                                .multilineTextAlignment(alignment)
                        }
                    }
                }
                .onAppear {
                    loadImage()
                }
            }
        }
    }
    
    private func loadImage() {
        guard let url = currentFile?.imagePreviewUrl else {
            isLoading = false
            return
        }
        
        SDWebImageManager.shared.loadImage(
            with: url,
            options: [],
            progress: nil
        ) { image, _, error, _, _, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                if let image = image {
                    self.uiImage = image
                }
            }
        }
    }
    
    @ViewBuilder
    private func getNotApprovedStateView(_ state: IQFileState) -> some View {
        HStack(spacing: 8) {
            Spacer()
            Button {
                onCancelImageSendCompletion?()
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
            Spacer()
        }
        .padding(8)
    }
    
    // MARK: - METHODS
    private func calculateImageSize(file: IQFile?) -> CGSize {
        let horizontalReserve: CGFloat = isSender ? 80 : 128
        let maxWidth = UIScreen.screenWidth - horizontalReserve
        let maxHeight = CGFloat(450)
        
        if file?.isLoading ?? false {
            guard let data = file?.dataFile?.data,
                  let image = UIImage(data: data) else {
                return CGSize(width: maxWidth, height: 300)
            }
            
            let height = min(maxWidth * image.size.height / image.size.width, maxHeight)
            return CGSize(width: maxWidth, height: height)
        } else {
            guard let width = file?.imageWidth,
                  let height = file?.imageHeight else {
                return CGSize(width: maxWidth, height: 300)
            }
            
            let proportionalHeight = maxWidth * CGFloat(height) / CGFloat(width)
            return CGSize(width: maxWidth, height: min(proportionalHeight, maxHeight))
        }
    }
}
