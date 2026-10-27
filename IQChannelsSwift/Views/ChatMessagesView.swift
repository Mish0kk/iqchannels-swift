import SwiftUI

struct ChatMessagesView: View {
    
    // MARK: - PROPERTIES
    @EnvironmentObject var viewModel: IQChatDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    
    weak var delegate: ChatDetailViewDelegate?
    
    @State private var keyboardShown: Bool = false
    @State private var isScrollDownVisible: Bool = false
    @State private var isMenuVisibleMessage: IQMessage? = nil
    
    var loaderColor: Color {
        return IQStyle.getColor(theme: IQStyle.model?.chat?.chatLoader) ?? Color(hex: "555555")
    }
    
    // MARK: - BODY
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    Color.clear.frame(height: 1)
                        .id("last")
                    
                    ForEach(viewModel.messages) { message in
                        let index = viewModel.messages.firstIndex(of: message) ?? 0
                        VStack(spacing: 8) {
                            if shouldDisplayMessageDate(index) {
                                getDatePreviewView(date: message.createdDate.formatRelatively())
                            }
                            
                            if message.newMsgHeader {
                                getNewMessagesView()
                            }
                            
                            VStack(alignment: .trailing){
                                if isMenuVisibleMessage == message{
                                    getMenuView()
                                        .zIndex(200)
                                }
                                
                                if let rating = message.rating {
                                    if(message.isPendingRatingMessage){
                                        if (rating.state == .poll) {
                                            if let ratingPoll = message.rating?.ratingPoll {
                                                RatingPollCellView(rating: rating, ratingPoll: ratingPoll) { value, answers, ratingId, pollId, rated in
                                                    if(rated){
                                                        delegate?.onSendPoll(value: value, answers: answers, ratingId: ratingId, pollId: pollId)
                                                    }else{
                                                        delegate?.onPollIgnored(ratingId: ratingId, pollId: pollId)
                                                    }
                                                }
                                                .onAppear {
                                                    delegate?.onMessageAppear(with: message.messageID)
                                                }
                                            }
                                            
                                        } else{
                                            RatingCellView(rating: rating) { value, ratingId in
                                                delegate?.onRate(value: value, ratingId: ratingId)
                                            }
                                            .onAppear {
                                                delegate?.onMessageAppear(with: message.messageID)
                                            }
                                        }
                                    }else{
                                        SystemMessageCellView(message: message)
                                            .onAppear {
                                                delegate?.onMessageAppear(with: message.messageID)
                                            }
                                    }
                                } else if(message.transferToChannel != nil){
                                    ChangeSegmentView(message: message) {
                                        delegate?.onChangeSegment(message)
                                    }
                                } else{
                                    let isLastMessage = message == viewModel.messages.first
                                    ChatMessageCellView(message: message,
                                                        replyMessage: viewModel.getMessage(with: message.replyToMessageID),
                                                        isGroupStart: isGroupStart(index),
                                                        isLastMessage: isLastMessage,
                                                        sessionToken: viewModel.session?.token ?? "",
                                                        delegate: delegate,
                                                        onLongPress: { messageControlInfo in
                                                            if(message.isReply){
                                                                viewModel.showMessageControl(messageControlInfo)
                                                            }
                                                        },
                                                        onReplyToMessage: { message in
                                                            withAnimation {
                                                                viewModel.messageToReply = message
                                                            }
                                                        },
                                                        onReplyMessageTapCompletion: { messageId in
                                                            if let id = viewModel.messages.first(where: { $0.messageID == messageId })?.id {
                                                                withAnimation(.easeInOut) {
                                                                    proxy.scrollTo(id, anchor: .center)
                                                                }
                                                            }
                                                        },
                                                        onErrorTap: { message in
                                                            isMenuVisibleMessage = message
                                                        })
                                                        .onAppear {
                                                            delegate?.onMessageAppear(with: message.messageID)
                                                        }
                                }
                            }
                        }
                        .modifier(FlippedUpsideDown())
                    }
                }
                .padding([.bottom, .horizontal], 16)
                .background(GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                })
            }
            .clipped()
            .coordinateSpace(name: "scroll")
            .modifier(FlippedUpsideDown())
            .modifier(HideKeyboardOnDragGesture())
            .modifier(HideKeyboardOnTapGesture(shouldAdd: keyboardShown))
            .overlay(getScrollDownButton(proxy: proxy), alignment: .bottomTrailing)
            .overlay(getLoadingView())
            .onReceive(keyboardPublisher) { keyboardShown = $0 }
            .onChange(of: viewModel.scrollDown) { _ in
                withAnimation(.easeInOut) {
                    proxy.scrollTo("last", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.idOfNewMessage) { messageId in
                guard let messageId,
                      let messageUiId = viewModel.messages.first(where: { $0.messageID == messageId })?.id else { return }
                withAnimation(.easeOut) {
                    proxy.scrollTo(messageUiId, anchor: .bottom)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: isScrollDownVisible)
            .animation(.easeInOut, value: viewModel.isLoading)
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            isScrollDownVisible = value.y < -100
        }
        .onTapGesture {
            isMenuVisibleMessage = nil
        }
        .animation(isScrollDownVisible || !viewModel.enableAnimMessages || viewModel.disableMessagesAnimation ? nil : .easeInOut(duration: 0.25), value: viewModel.messages)
    }
    
    // MARK: - VIEWS
    @ViewBuilder
    private func getDatePreviewView(date: String) -> some View {
        let color = IQStyle.getColor(theme: IQStyle.model?.chat?.dateText?.color) ?? Color(hex: "919399")
        let fontSize = CGFloat(IQStyle.model?.chat?.dateText?.textSize ?? 13)
        let alignment = stringToAlignment(stringAlignment: IQStyle.model?.chat?.dateText?.textAlign) ?? .leading
        let isBold = IQStyle.model?.chat?.dateText?.textStyle?.bold ?? false
        let isItalic = IQStyle.model?.chat?.dateText?.textStyle?.italic ?? false
        if #available(iOS 16.0, *) {
            Text(date)
                .font(.system(size: fontSize))
                .foregroundColor(color)
                .multilineTextAlignment(alignment)
                .bold(isBold)
                .italic(isItalic)
                .padding(.vertical, 12)
        } else {
            Text(date)
                .font(.system(size: fontSize))
                .foregroundColor(color)
                .multilineTextAlignment(alignment)
                .padding(.vertical, 12)
        }
    }
    
    @ViewBuilder
    private func getScrollDownButton(proxy: ScrollViewProxy) -> some View {
        let backgroundColor = IQStyle.getColor(theme: IQStyle.model?.chat?.scrollDownButtonBackground?.color) ?? Color(hex: "ffffff")
        let borderColor = IQStyle.getColor(theme: IQStyle.model?.chat?.scrollDownButtonBackground?.border?.color) ?? Color(hex: "E4E8ED")
        let borderSize = CGFloat(IQStyle.model?.chat?.scrollDownButtonBackground?.border?.size ?? 1)
        
        let foregroundColor = IQStyle.getColor(theme: IQStyle.model?.chat?.scrollDownButtonIconColor) ?? Color(hex: "000000")
        
        if isScrollDownVisible {
            Button {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo("last", anchor: .bottom)
                    }
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(name: "chevron_down")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(foregroundColor)
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background(backgroundColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(borderColor, lineWidth: borderSize))
                    
                    if !viewModel.scrollDotHidden {
                        Circle()
                            .fill(Color(hex: "DD0A34"))
                            .frame(width: 8, height: 8)
                            .padding(2)
                    }
                }
                .animation(.easeInOut, value: viewModel.scrollDotHidden)
            }
            .padding(8)
            .transition(.move(edge: .trailing))
        }
    }
    
    @ViewBuilder
    private func getLoadingView() -> some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: loaderColor))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private func getNewMessagesView() -> some View {
        let textColor = IQStyle.getColor(theme: IQStyle.model?.chat?.systemText?.color) ?? Color(hex: "242729")
        let fontSize = CGFloat(IQStyle.model?.chat?.systemText?.textSize ?? 17)
        let alignment = stringToAlignment(stringAlignment: IQStyle.model?.chat?.systemText?.textAlign) ?? .leading
        let isBold = IQStyle.model?.chat?.systemText?.textStyle?.bold ?? false
        let isItalic = IQStyle.model?.chat?.systemText?.textStyle?.italic ?? false
        
        let background = IQStyle.getColor(theme: IQStyle.model?.chat?.newMessageBackground) ?? Color(hex: "F4F4F8")
        
        if #available(iOS 16.0, *) {
            Text(IQLanguageTexts.model.newMessages ?? "Новые сообщения")
                .foregroundColor(textColor)
                .font(.system(size: fontSize))
                .multilineTextAlignment(alignment)
                .bold(isBold)
                .italic(isItalic)
                .frame(height: 24)
                .frame(maxWidth: .infinity)
                .background(background)
                .padding(.top, 12)
                .padding(.horizontal, -16)
        } else {
            Text(IQLanguageTexts.model.newMessages ?? "Новые сообщения")
                .foregroundColor(textColor)
                .font(.system(size: fontSize))
                .multilineTextAlignment(alignment)
                .frame(height: 24)
                .frame(maxWidth: .infinity)
                .background(background)
                .padding(.top, 12)
                .padding(.horizontal, -16)
        }
    }
    
    // MARK: - METHODS
    private func isGroupStart(_ index: Int) -> Bool {
        guard index < viewModel.messages.count - 1 else { return true }
        
        let message = viewModel.messages[index]
        let prev = viewModel.messages[index + 1]
        return prev.isMy != message.isMy
        || (prev.userID != nil && prev.userID != message.userID)
        || ((message.createdAt ?? 0) - (prev.createdAt ?? 0)) > 60000
    }
    
    private func shouldDisplayMessageDate(_ index: Int) -> Bool {
        guard index < viewModel.messages.count - 1 else { return true }
        
        let message = viewModel.messages[index]
        let prev = viewModel.messages[index + 1]
        let calendar = Calendar.current
        let messageDateComponents = calendar.dateComponents([.year, .month, .day], from: message.createdDate)
        let prevDateComponents = calendar.dateComponents([.year, .month, .day], from: prev.createdDate)
        
        return messageDateComponents.year != prevDateComponents.year ||
        messageDateComponents.month != prevDateComponents.month ||
        messageDateComponents.day != prevDateComponents.day
    }
    
    
    
    
    @ViewBuilder
    private func getMenuView() -> some View {
        let textColor = IQStyle.getColor(theme: IQStyle.model?.messages?.errorPopupMenuText?.color) ?? Color(hex: "000000")
        let fontSize = CGFloat(IQStyle.model?.messages?.errorPopupMenuText?.textSize ?? 16)
        let alignment = stringToAlignment(stringAlignment: IQStyle.model?.messages?.errorPopupMenuText?.textAlign) ?? .leading
        let isBold = IQStyle.model?.messages?.errorPopupMenuText?.textStyle?.bold ?? false
        let isItalic = IQStyle.model?.messages?.errorPopupMenuText?.textStyle?.italic ?? false
        
        
        let backgroundColor = IQStyle.getColor(theme: IQStyle.model?.messages?.errorPopupMenuBackground?.color) ?? Color(hex: "f1f1f1")
        let radius = IQStyle.model?.messages?.errorPopupMenuBackground?.border?.borderRadius ?? 12
        let borderSize = IQStyle.model?.messages?.errorPopupMenuBackground?.border?.size ?? 1
        let borderColor = IQStyle.getColor(theme: IQStyle.model?.messages?.errorPopupMenuBackground?.border?.color) ?? Color(hex: "cccccc")
        
        
        
        
        
        VStack(spacing: 8) {
            Button(action: {
                delegate?.onResendMessage(isMenuVisibleMessage!.withError(false))
                isMenuVisibleMessage = nil
            }) {
                if #available(iOS 16.0, *) {
                    Text(IQLanguageTexts.model.resend ?? "Повторить отправку")
                        .frame(width: 200)
                        .font(.system(size: fontSize))
                        .padding(3)
                        .foregroundColor(textColor)
                        .bold(isBold)
                        .italic(isItalic)
                        .multilineTextAlignment(alignment)
                } else {
                    Text(IQLanguageTexts.model.resend ?? "Повторить отправку")
                        .frame(width: 200)
                        .font(.system(size: fontSize))
                        .padding(3)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                }
            }
//            Divider()

            Button(action: {
                delegate?.onCancelSend(isMenuVisibleMessage!)
                isMenuVisibleMessage = nil
            }) {
                if #available(iOS 16.0, *) {
                    Text(IQLanguageTexts.model.delete ?? "Удалить")
                        .frame(width: 200)
                        .font(.system(size: fontSize))
                        .padding(3)
                        .foregroundColor(textColor)
                        .bold(isBold)
                        .italic(isItalic)
                        .multilineTextAlignment(alignment)
                } else {
                    Text(IQLanguageTexts.model.delete ?? "Удалить")
                        .frame(width: 200)
                        .font(.system(size: fontSize))
                        .padding(3)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                }
            }
        }
        .animation(.easeInOut(duration: 0.1), value: true)
        .frame(width: 200)
        .padding(6)
        .background(backgroundColor)
        
        .cornerRadius(radius)
        .shadow(radius: 4)
        
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(borderColor, lineWidth: borderSize)
        )
    }
}
