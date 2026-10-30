import SwiftUI
import SDWebImageSwiftUI

struct ChatMessageCellView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    let message: IQMessage
    let replyMessage: IQMessage?
    let isGroupStart: Bool
    let isLastMessage: Bool
    let sessionToken: String
    
    weak var delegate: ChatDetailViewDelegate?
    
    let onLongPress: ((MessageControlInfo) -> Void)?
    let onReplyToMessage: ((IQMessage) -> Void)?
    let onReplyMessageTapCompletion: ((Int) -> Void)?
    let onErrorTap: ((IQMessage) -> Void)?
    
    @State private var dragAmountX: CGFloat = 0
    @State private var isMenuVisible = false
    
    var backgroundColor: Color {
        return IQStyle.getColor(theme: IQStyle.model?.chat?.background) ?? Color(hex: "919399")
    }
    
    var senderTextColor: Color {
        return IQStyle.getColor(theme: IQStyle.model?.messages?.textUp?.color) ?? Color(hex: "919399")
    }
    var senderFontSize: CGFloat {
        return CGFloat(IQStyle.model?.messages?.textUp?.textSize ?? 13)
    }
    var senderIsBold: Bool {
        return IQStyle.model?.messages?.textUp?.textStyle?.bold ?? false
    }
    var senderIsItalic: Bool {
        return IQStyle.model?.messages?.textUp?.textStyle?.italic ?? false
    }
    var senderAligment: TextAlignment {
        return stringToAlignment(stringAlignment: IQStyle.model?.messages?.textUp?.textAlign) ?? .leading
    }
    
    
    
    var errorIconBackgroundColor: Color {
        return IQStyle.getColor(theme: IQStyle.model?.messages?.errorBackground) ?? Color(hex: "ff0000")
    }
    var errorTextColor: Color {
        return IQStyle.getColor(theme: IQStyle.model?.messages?.errorIcon?.color) ?? Color(hex: "ffffff")
    }
    var errorFontSize: CGFloat {
        return CGFloat(IQStyle.model?.messages?.errorIcon?.textSize ?? 13)
    }
    var errorIsBold: Bool {
        return IQStyle.model?.messages?.errorIcon?.textStyle?.bold ?? false
    }
    var errorIsItalic: Bool {
        return IQStyle.model?.messages?.errorIcon?.textStyle?.italic ?? false
    }
    
    
    
    var avatarURL: URL? {
        return IQStyle.model?.chat?.iconOperator ?? message.user?.avatarURL
    }
    
    // MARK: - BODY
    var body: some View {
        let isSender = message.isMy ?? false
        let isSystem = message.isSystem
        
        if !isSystem {
            ZStack(alignment: .trailing) {
                getReplyView()
                    .opacity(-dragAmountX / 56)
                    .offset(x: 56)
                
                HStack(alignment: .bottom, spacing: 8) {
                    if !isSender {
                        getAvatarView(avatarURL: avatarURL,
                                      userDisplayName: message.senderName)
                        .opacity(isGroupStart ? 1 : 0)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if !isSender,
                           isGroupStart {
                            if #available(iOS 16.0, *) {
                                Text(message.senderName)
                                    .font(.system(size: senderFontSize))
                                    .foregroundColor(senderTextColor)
                                    .multilineTextAlignment(senderAligment)
                                    .bold(senderIsBold)
                                    .italic(senderIsItalic)
                                    .padding(.leading, 12)
                                    .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: senderAligment) ?? .leading)
                            } else {
                                Text(message.senderName)
                                    .font(.system(size: senderFontSize))
                                    .foregroundColor(senderTextColor)
                                    .multilineTextAlignment(senderAligment)
                                    .padding(.leading, 12)
                                    .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: senderAligment) ?? .leading)
                            }
                        }
                        
                        HStack(alignment: .bottom){
                            MessageCellBubbleView(message: message,
                                                  replyMessage: replyMessage,
                                                  isLastMessage: isLastMessage,
                                                  onLongPress: onLongPress,
                                                  onReplyMessageTapCompletion: onReplyMessageTapCompletion,
                                                  sessionToken: sessionToken,
                                                  delegate: delegate)
                            if(message.error){
                                getErrorView()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: isSender ? .trailing : .leading)
            .padding(isSender ? .leading : .trailing, 48)
            .offset(x: dragAmountX)
            .background(Color(white: 1, opacity: 0.000001))
            .gesture(
                message.isReply ?
                    DragGesture(minimumDistance: 25, coordinateSpace: .local)
                        .onChanged { dragValue in
                            if dragValue.translation.width < 0,
                               dragValue.translation.width > -(UIScreen.main.bounds.width / 3) {
                                dragAmountX = dragValue.translation.width
                            }
                        }
                        .onEnded { dragValue in
                            if dragValue.translation.width < -60 {
                                triggerHapticFeedback(style: .rigid)
                                onReplyToMessage?(message)
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragAmountX = 0
                            }
                        }
                : nil
            )
        } else{
            SystemMessageCellView(message: message) { [weak delegate] url in
                delegate?.onLinkTap(url: url, message: message)
            }
        }
    }

    // MARK: - VIEWS
    @ViewBuilder
    private func getAvatarView(avatarURL: URL?, userDisplayName: String) -> some View {
        ZStack {
            Color.paletteColorFromString(string: userDisplayName)
            
            if let avatarURL {
                AnimatedImage(url: avatarURL)
                    .resizable()
                    .indicator(SDWebImageActivityIndicator.gray)
                    .transition(SDWebImageTransition.fade)
                    .scaledToFill()
            } else {
                let initials = userDisplayName.prefix(1)
                Text(initials)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
    
    @ViewBuilder
    private func getReplyView() -> some View {
        Image(name: "reply")
            .resizable()
            .scaledToFill()
            .frame(width: 16, height: 16)
            .padding(8)
            .background(Color(hex: "F4F4F8"))
            .clipShape(Circle())
    }
    
    
    @ViewBuilder
    private func getErrorView() -> some View {
        Button(action: {
            onErrorTap?(message)
        }) {
            ZStack {
                Circle()
                    .fill(errorIconBackgroundColor)
                    .frame(width: 40, height: 40)

                if #available(iOS 16.0, *) {
                    Text("!")
                        .foregroundColor(errorTextColor)
                        .font(.system(size: errorFontSize, weight: .bold))
                        .bold(errorIsBold)
                        .italic(errorIsItalic)
                } else {
                    Text("!")
                        .foregroundColor(errorTextColor)
                        .font(.system(size: errorFontSize, weight: .bold))
                }
            }
        }
    }
}
