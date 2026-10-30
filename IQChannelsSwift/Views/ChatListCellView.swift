import SwiftUI
import SDWebImageSwiftUI

struct ChatListCellView: View {
    
    // MARK: - PROPERTIES
    let chatInfoModel: IQChatItemModel
    let unreadInfo: Channel?
    
    var title: String {
        return chatInfoModel.info?.channelName ?? ""
    }
    
    var iconUrl: URL? {
        switch chatInfoModel.chatType {
        case .chat:
            return IQStyle.model?.multiChat?.iconRegularChat
        case .manager:
            return IQStyle.model?.multiChat?.iconPersonalManagerChat
        case .info:
            return IQStyle.model?.multiChat?.iconInfoChat
        }
    }
    
    var iconBackgroundColor: Color {
        if let channelIconColor = chatInfoModel.info?.channelIconColor {
            return Color(hex: channelIconColor)
        }
        return IQStyle.getColor(theme: IQStyle.model?.multiChat?.backgroundIcon) ?? Color(hex: "66B2B2")
    }
    
    var titleColor: Color {
        IQStyle.getColor(theme: IQStyle.model?.multiChat?.title?.color) ?? Color(hex: "494949")
    }
    var titleFontSize: CGFloat {
        CGFloat(IQStyle.model?.multiChat?.title?.textSize ?? 18)
    }
    var titleIsBold: Bool {
        IQStyle.model?.multiChat?.title?.textStyle?.bold ?? false
    }
    var titleIsItalic: Bool {
        IQStyle.model?.multiChat?.title?.textStyle?.italic ?? false
    }
    var titleAlignment: TextAlignment {
        stringToAlignment(stringAlignment: IQStyle.model?.multiChat?.title?.textAlign) ?? .leading
    }
    
    var lastMessageColor: Color {
        IQStyle.getColor(theme: IQStyle.model?.multiChat?.lastMessage?.color) ?? Color(hex: "8E8E93")
    }
    var lastMessageFontSize: CGFloat {
        CGFloat(IQStyle.model?.multiChat?.lastMessage?.textSize ?? 15)
    }
    var lastMessageIsBold: Bool {
        IQStyle.model?.multiChat?.lastMessage?.textStyle?.bold ?? false
    }
    var lastMessageIsItalic: Bool {
        IQStyle.model?.multiChat?.lastMessage?.textStyle?.italic ?? false
    }
    var lastMessageAlignment: TextAlignment {
        stringToAlignment(stringAlignment: IQStyle.model?.multiChat?.lastMessage?.textAlign) ?? .leading
    }
    
    var timeText: String {
        guard let raw = unreadInfo?.lastMessage?.date else { return "" }
        return Self.formatDate(raw)
    }
    
    var subtitleText: String {
        guard let lastMessage = unreadInfo?.lastMessage else { return "" }
        if lastMessage.isSurvey == true { return "Опрос" }
        
        let text = lastMessage.text ?? ""
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let fileId = lastMessage.fileID {
            return fileId
        }
        
        return text
    }
    
    static func parseDate(_ raw: String) -> Date? {
        LastMessage.parseDate(raw)
    }
    
    static func formatDate(_ raw: String) -> String {
        guard let date = parseDate(raw) else { return raw }
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "dd.MM"
        } else {
            formatter.dateFormat = "dd.MM.yyyy"
        }
        return formatter.string(from: date)
    }
    
    // MARK: - BODY
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 52, height: 52)
                
                if let iconUrl {
                    AnimatedImage(url: iconUrl)
                        .resizable()
                        .indicator(SDWebImageActivityIndicator.gray)
                        .transition(SDWebImageTransition.fade)
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                } else {
                    let imageName = chatInfoModel.chatType == .manager ? "user" : "chat"
                    Image(name: imageName)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    if #available(iOS 16.0, *) {
                        Text(title)
                            .font(.system(size: titleFontSize))
                            .foregroundColor(titleColor)
                            .multilineTextAlignment(titleAlignment)
                            .bold(titleIsBold)
                            .italic(titleIsItalic)
                            .lineLimit(1)
                    } else {
                        Text(title)
                            .font(.system(size: titleFontSize))
                            .foregroundColor(titleColor)
                            .multilineTextAlignment(titleAlignment)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    if !timeText.isEmpty {
                        Text(timeText)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .lineLimit(1)
                    }
                }
                
                HStack(alignment: .top, spacing: 8) {
                    if #available(iOS 16.0, *) {
                        Text(subtitleText)
                            .font(.system(size: lastMessageFontSize))
                            .foregroundColor(lastMessageColor)
                            .multilineTextAlignment(lastMessageAlignment)
                            .bold(lastMessageIsBold)
                            .italic(lastMessageIsItalic)
                            .lineLimit(1)
                    } else {
                        Text(subtitleText)
                            .font(.system(size: lastMessageFontSize))
                            .foregroundColor(lastMessageColor)
                            .multilineTextAlignment(lastMessageAlignment)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    if let count = unreadInfo?.unreadCount, count > 0 {
                        Text("\(count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Circle().fill(Color(hex: "8E8E93")))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }
}
