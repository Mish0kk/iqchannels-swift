import SwiftUI

private let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

struct TextMessageCellView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    private let message: IQMessage
    private let replyMessage: IQMessage?
    private let onLongPress: ((MessageControlInfo) -> Void)?
    private let onReplyMessageTapCompletion: ((Int) -> Void)?
    
    private let text: String
    private let isSender: Bool
    private let links: [NSTextCheckingResult]
    
    @State private var keyboardShown: Bool = false
    @State private var computeFrame = false
    @State private var frame: CGRect = .zero
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
    
    
    // MARK: - INIT
    init (message: IQMessage,
          replyMessage: IQMessage? = nil,
          onLongPress: ((MessageControlInfo) -> Void)? = nil,
          onReplyMessageTapCompletion: ((Int) -> Void)? = nil) {
        self.message = message
        self.replyMessage = replyMessage
        self.onLongPress = onLongPress
        self.onReplyMessageTapCompletion = onReplyMessageTapCompletion
        self.text = message.messageText
        self.isSender = message.isMy ?? false
        
        let nsText = text as NSString
        
        let wholeString = NSRange(location: 0, length: nsText.length)
        links = linkDetector.matches(in: text, options: [], range: wholeString)
    }
    
    // MARK: - BODY
    var body: some View {
        let cursorColor = IQStyle.getColor(theme: IQStyle.model?.toolsToMessage?.cursorColor) ?? Color(hex: "3d3d3d")
        
        VStack(alignment: .trailing, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                if let replyMessage {
                    MessageReplyView(message: replyMessage,
                                     isMy: message.isMy ?? false,
                                     onReplyMessageTapCompletion: onReplyMessageTapCompletion)
                }
                

                Group {
                    if let cachedText {
                        TextLabel(text: cachedText.0,
                                  linkRanges: cachedText.1)
                        .layoutPriority(1)
                        .padding(.horizontal, 12)
                    } else {
                        Text("")
                    }
                }
                .onAppear {
                    loadText()
                }
            }

            MessageStatusView(message: message)
        }
        .padding(.horizontal, 12)
        .padding(.top, message.isAutoGreet ? 16 : 8)
        .padding(.bottom, 8)
        .background(backgroundColor)
        .cornerRadius(backgroundRadius)
        .overlay(
            RoundedRectangle(cornerRadius: backgroundRadius)
                .stroke(backgroundBorderColor, lineWidth: backgroundBorderSize)
        )
        .onReceive(keyboardPublisher) { keyboardShown = $0 }
        .background(
            GeometryReader { proxy in
                Rectangle().fill(SwiftUI.Color.clear)
                    .onChange(of: computeFrame, perform: { _ in
                        DispatchQueue.main.async {
                            frame = proxy.frame(in: .global)
                        }
                    })
            }
        )
        .onTapGesture {}
        .onLongPressGesture {
            handleLongTap()
        }
    }
    
    // MARK: - METHODS
    private func handleLongTap() {
        if keyboardShown {
            resignFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                computeFrameOnPress()
            }
        } else {
            computeFrameOnPress()
        }
    }
    
    private func computeFrameOnPress() {
        computeFrame = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            computeFrame = false
            triggerHapticFeedback(style: .medium)
            onLongPress?(MessageControlInfo(message: message, replyMessage: replyMessage, frame: frame))
        }
    }
}

struct MessageColoredText: View {
    enum Component {
        case text(String)
        case link(String, URL)
    }
    
    let text: String
    let components: [Component]
    
    init(text: String, links: [NSTextCheckingResult]) {
        self.text = text
        let nsText = text as NSString
        
        var components: [Component] = []
        var index = 0
        for result in links {
            if result.range.location > index {
                components.append(.text(nsText.substring(with: NSRange(location: index, length: result.range.location - index))))
            }
            components.append(.link(nsText.substring(with: result.range), result.url!))
            index = result.range.location + result.range.length
        }
        
        if index < nsText.length {
            components.append(.text(nsText.substring(from: index)))
        }
        
        self.components = components
    }
    
    var body: some View {
        components.map { component in
            switch component {
            case .text(let text):
                return Text(verbatim: text)
            case .link(let text, _):
                return Text(verbatim: text)
                    .underline()
            }
        }.reduce(Text(""), +)
    }
}

private struct LinkTapOverlay: UIViewRepresentable {
    let text: String
    let links: [NSTextCheckingResult]
    
    func makeUIView(context: Context) -> LinkTapOverlayView {
        let view = LinkTapOverlayView()
        view.textContainer = context.coordinator.textContainer
        
        view.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTapLabel(_:)))
        tapGesture.delegate = context.coordinator
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: LinkTapOverlayView, context: Context) {
        let attributedString = NSAttributedString(string: text,
                                                  attributes: [.font: UIFont.systemFont(ofSize: 17)])
        context.coordinator.textStorage = NSTextStorage(attributedString: attributedString)
        context.coordinator.textStorage!.addLayoutManager(context.coordinator.layoutManager)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let overlay: LinkTapOverlay
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        var textStorage: NSTextStorage?
        
        init(_ overlay: LinkTapOverlay) {
            self.overlay = overlay
            
            textContainer.lineFragmentPadding = 0
            textContainer.lineBreakMode = .byWordWrapping
            textContainer.maximumNumberOfLines = 0
            layoutManager.addTextContainer(textContainer)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            let location = touch.location(in: gestureRecognizer.view!)
            let result = link(at: location)
            return result != nil
        }
        
        @objc func didTapLabel(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view!)
            guard let result = link(at: location) else {
                return
            }
            
            guard let url = result.url else {
                return
            }
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        private func link(at point: CGPoint) -> NSTextCheckingResult? {
            guard !overlay.links.isEmpty else {
                return nil
            }
            
            let indexOfCharacter = layoutManager.characterIndex(
                for: point,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )
            
            return overlay.links.first { $0.range.contains(indexOfCharacter) }
        }
    }
}

private class LinkTapOverlayView: UIView {
    var textContainer: NSTextContainer!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var newSize = bounds.size
        newSize.height += 20 // need some extra space here to actually get the last line
        textContainer.size = newSize
    }
}
