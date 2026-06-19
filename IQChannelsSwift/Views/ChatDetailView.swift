import SwiftUI
import SDWebImageSwiftUI

protocol ChatDetailViewDelegate: AnyObject {
    func onAttachmentTap()
    func onFileTap(_ file: IQFile, sessionToken: String)
    func onSingleChoiceTap(_ singleChoice: IQSingleChoice)
    func onProductTap(_ product: IQProductTap)
    func onActionTap(_ action: IQAction)
    func onMessageAppear(with messageId: Int)
    func onSendMessage(_ text: String)
    func onResendMessage(_ message: IQMessage)
    func onCancelUpload(_ message: IQMessage)
    func onCancelSend(_ message: IQMessage)
    func onRate(value: Int, ratingId: Int)
    func onSendPoll(value: Int?, answers: [IQRatingPollClientAnswerInput], ratingId: Int, pollId: Int)
    func onPollIgnored(ratingId: Int, pollId: Int)
    func onChangeSegment(_ message: IQMessage)
}

struct ChatDetailView: View {
    
    // MARK: - PROPERTIES
    @EnvironmentObject var viewModel: IQChatDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    
    weak var delegate: ChatDetailViewDelegate?
    
    var backgroundColor: Color {
        return IQStyle.getColor(theme: IQStyle.model?.chat?.background) ?? .white
    }
    
    var showInfoChatStub: Bool {
        if(viewModel.isAnonim && viewModel.greetingSettings?.channelType == "info"){
            return true
        } else {
            return (viewModel.client?.chatTypes.contains(.info) ?? false) && viewModel.messages.isEmpty
        }
    }

    // MARK: - BODY
    var body: some View {
        if((viewModel.state == .authenticated || viewModel.state == .awaitingNetwork) && !showInfoChatStub){
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    
                    if(viewModel.showBottomTypingBar){
                        ZStack(alignment: .bottom){
                            ChatMessagesView(delegate: delegate)
                            
                            if let typingUser = viewModel.typingUser {
                                getTypingView(user: typingUser)
                                    .zIndex(2)
                            }
                        }
                    } else {
                        ChatMessagesView(delegate: delegate)
                    }
                    
                    if(!(viewModel.client?.chatTypes.contains(.info) ?? true)){
                        ChatInputView(text: $viewModel.inputText,
                                      messageToReply: $viewModel.messageToReply,
                                      selectedFiles: $viewModel.selectedFiles,
                                      disableInput: viewModel.messages.first?.disableFreeText ?? false,
                                      onAttachmentCompletion: {
                            delegate?.onAttachmentTap()
                        }, onSendCompletion: {
                            delegate?.onSendMessage(viewModel.inputText)
                            viewModel.inputText = ""
                            viewModel.messageToReply = nil
                            viewModel.selectedFiles = nil
                        })
                    }
                }
                .zIndex(0)
        
                Group {
                    if viewModel.isMessageCopied {
                        getMessageCopiedOverlay()
                    }
                }
                .zIndex(1)
                .opacity(viewModel.isMessageCopied ? 1 : 0)
            }
            .background(backgroundColor.ignoresSafeArea())
            .animation(.easeInOut(duration: 0.25), value: viewModel.typingUser)
            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: viewModel.isMessageCopied)
            .overlay(getMessageControlOverlay())
        }
        else if (showInfoChatStub){
            ZStack {
                backgroundColor.ignoresSafeArea()
                getInfoChatStubView()
            }
        }
        else if (viewModel.state == .noPm){
            ZStack {
                backgroundColor.ignoresSafeArea()
                getErrorView(isPm: true)
            }
        }
//        else {
//            ZStack {
//                backgroundColor.ignoresSafeArea()
//                getErrorView(isPm: false)
//            }
//        }
    }
    
    // MARK: - VIEWS
    @ViewBuilder
    private func getMessageControlOverlay() -> some View {
        if viewModel.messageControlShown,
           let controlInfo = viewModel.messageControlInfo {
            MessageControlOverlayView(messageDisplayInfo: controlInfo) {
                viewModel.messageControlShown = false
                viewModel.messageControlInfo = nil
            } onActionCompletion: { controlType in
                switch controlType {
                case .copy:
                    UIPasteboard.general.string = controlInfo.message.text
                    viewModel.isMessageCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        viewModel.isMessageCopied = false
                    }
                case .reply:
                    viewModel.messageToReply = controlInfo.message
                }
            }
        }
    }
    
    @ViewBuilder
    private func getMessageCopiedOverlay() -> some View {
        HStack(spacing: 8) {
            Image(name: "status_success")
                .resizable()
                .frame(width: 20, height: 20)
            
            Text(IQLanguageTexts.model.textCopied ?? "Сообщение скопировано")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                viewModel.isMessageCopied = false
            } label: {
                Image(name: "xmark")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(8)
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 16)
        .background(Color(hex: "57B22F"))
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding(16)
        .transition(.move(edge: .top))
    }
    
    @ViewBuilder
    private func getTypingView(user: IQUser) -> some View {
        let textColor = IQStyle.getColor(theme: IQStyle.model?.answer?.textOperatorTyping?.color) ?? Color(hex: "242729")
        let fontSize = CGFloat(IQStyle.model?.answer?.textOperatorTyping?.textSize ?? 17)
        let alignment = stringToAlignment(stringAlignment: IQStyle.model?.answer?.textOperatorTyping?.textAlign) ?? .leading
        let isBold = IQStyle.model?.answer?.textOperatorTyping?.textStyle?.bold ?? false
        let isItalic = IQStyle.model?.answer?.textOperatorTyping?.textStyle?.italic ?? false
        
        let backgroundColor = IQStyle.getColor(theme: IQStyle.model?.answer?.backgroundOperatorTyping) ?? Color.white
        
        ZStack {
            if #available(iOS 16.0, *) {
                Text("\(user.displayName ?? "Оператор") \(IQLanguageTexts.model.operatorTyping ?? "печатает...")")
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 12)
                    .multilineTextAlignment(alignment)
                    .bold(isBold)
                    .italic(isItalic)
                    .lineLimit(1)
                    .padding(.horizontal, 48)
            } else {
                Text("\(user.displayName ?? "Оператор") \(IQLanguageTexts.model.operatorTyping ?? "печатает...")")
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 12)
                    .multilineTextAlignment(alignment)
                    .lineLimit(1)
                    .padding(.horizontal, 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: alignment) ?? .leading)
        .background(backgroundColor)
    }
    
    struct RoundedCorner: Shape {
        var radius: CGFloat = 0
        var corners: UIRectCorner = .allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }
    
    
    
    @ViewBuilder
    private func getErrorView(isPm: Bool) -> some View {
        let titleColor = IQStyle.getColor(theme: IQStyle.model?.error?.titleError?.color) ?? Color(hex: "242729")
        let titleFontSize = CGFloat(IQStyle.model?.error?.titleError?.textSize ?? 17)
        let titleIsBold = IQStyle.model?.error?.titleError?.textStyle?.bold ?? false
        let titleIsItalic = IQStyle.model?.error?.titleError?.textStyle?.italic ?? false
        let titleAlignment = stringToAlignment(stringAlignment: IQStyle.model?.error?.titleError?.textAlign) ?? .center
        
        let descriptionColor = IQStyle.getColor(theme: IQStyle.model?.error?.textError?.color) ?? Color(hex: "242729")
        let descriptionFontSize = CGFloat(IQStyle.model?.error?.textError?.textSize ?? 15)
        let descriptionIsBold = IQStyle.model?.error?.textError?.textStyle?.bold ?? false
        let descriptionIsItalic = IQStyle.model?.error?.textError?.textStyle?.italic ?? false
        let descriptionAlignment = stringToAlignment(stringAlignment: IQStyle.model?.error?.textError?.textAlign) ?? .center
        
        
        var titleError: String {
            let pmError = IQLanguageTexts.model.titleErrorPm ?? "Нет закреплённого персонального менеджера"
            let chatError = IQLanguageTexts.model.titleError ?? "Чат временно недоступен"
            return isPm ? pmError : chatError
        }
        
        var textError: String {
            let pmError = IQLanguageTexts.model.textErrorPm ?? "Обратитесь в чат с тех. поддержкой"
            let chatError = IQLanguageTexts.model.textError ?? "Мы уже все исправляем. Обновите\nстраницу или попробуйте позже"
            return isPm ? pmError : chatError
        }
        
        
        
        VStack(spacing: 20) {
            AnimatedImage(url: IQStyle.model?.error?.iconError,
                          placeholderImage: UIImage(name: "circle_error"))
                .resizable()
                .indicator(SDWebImageActivityIndicator.gray)
                .transition(SDWebImageTransition.fade)
                .scaledToFit()
                .frame(width: 48, height: 48)
            
            VStack(spacing: 8) {
                if #available(iOS 16.0, *) {
                    Text(titleError)
                        .foregroundColor(titleColor)
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .bold(titleIsBold)
                        .italic(titleIsItalic)
                        .multilineTextAlignment(titleAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: titleAlignment) ?? .center)
                } else {
                    Text(titleError)
                        .foregroundColor(titleColor)
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .multilineTextAlignment(titleAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: titleAlignment) ?? .center)
                }
                
                if #available(iOS 16.0, *) {
                    Text(textError)
                        .foregroundColor(descriptionColor)
                        .font(.system(size: descriptionFontSize))
                        .bold(descriptionIsBold)
                        .italic(descriptionIsItalic)
                        .multilineTextAlignment(descriptionAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: descriptionAlignment) ?? .center)
                } else {
                    Text(textError)
                        .foregroundColor(descriptionColor)
                        .font(.system(size: descriptionFontSize))
                        .multilineTextAlignment(descriptionAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: descriptionAlignment) ?? .center)
                }
            }
        }
    }
    
    
    
    
    
    
    @ViewBuilder
    private func getInfoChatStubView() -> some View {
        let descriptionColor = IQStyle.getColor(theme: IQStyle.model?.error?.textError?.color) ?? Color(hex: "242729")
        let descriptionFontSize = CGFloat(IQStyle.model?.error?.textError?.textSize ?? 15)
        let descriptionIsBold = IQStyle.model?.error?.textError?.textStyle?.bold ?? false
        let descriptionIsItalic = IQStyle.model?.error?.textError?.textStyle?.italic ?? false
        let descriptionAlignment = stringToAlignment(stringAlignment: IQStyle.model?.error?.textError?.textAlign) ?? .center
 
        
        VStack(spacing: 20) {
            AnimatedImage(url: viewModel.infoChatSettings?.blockerIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            
            VStack(spacing: 8) {
                if #available(iOS 16.0, *) {
                    Text(viewModel.infoChatSettings?.blockerText ?? "")
                        .foregroundColor(descriptionColor)
                        .font(.system(size: descriptionFontSize))
                        .bold(descriptionIsBold)
                        .italic(descriptionIsItalic)
                        .multilineTextAlignment(descriptionAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: descriptionAlignment) ?? .center)
                } else {
                    Text(viewModel.infoChatSettings?.blockerText ?? "")
                        .foregroundColor(descriptionColor)
                        .font(.system(size: descriptionFontSize))
                        .multilineTextAlignment(descriptionAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: descriptionAlignment) ?? .center)
                }
            }
        }
    }
}
