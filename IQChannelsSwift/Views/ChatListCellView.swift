import SwiftUI

struct ChatListCellView: View {
    
    // MARK: - PROPERTIES
    let chatInfoModel: IQChatItemModel
    let unreadInfo: Channel?
    
    var title: String {
        return chatInfoModel.info?.channelName ?? ""
    }
    
    var timeText: String {
        guard let raw = unreadInfo?.lastMessage?.date else { return "" }
        return Self.formatDate(raw)
    }
    
    var subtitleText: String {
        guard let lastMessage = unreadInfo?.lastMessage else { return "" }
        if lastMessage.isSurvey == true { return "Опрос" }
        return lastMessage.text ?? ""
    }
    
    static func parseDate(_ raw: String) -> Date? {
        if let interval = TimeInterval(raw) {
            return interval > 1e12 ? Date(timeIntervalSince1970: interval / 1000) : Date(timeIntervalSince1970: interval)
        }
        
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: raw) { return date }
        
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFractional.date(from: raw) { return date }
        
        let parts = raw.split(separator: " ")
        if parts.count >= 2 {
            var normalized = "\(parts[0]) \(parts[1])"
            if normalized.contains(".") {
                normalized = String(normalized.split(separator: ".").first ?? "")
            }
            
            if let zonePart = parts.dropFirst(2).first(where: { $0.hasPrefix("+") || $0.hasPrefix("-") }) {
                let zoned = DateFormatter()
                zoned.locale = Locale(identifier: "en_US_POSIX")
                zoned.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                if let date = zoned.date(from: "\(normalized) \(zonePart)") { return date }
            }
            
            let utc = DateFormatter()
            utc.locale = Locale(identifier: "en_US_POSIX")
            utc.timeZone = TimeZone(identifier: "UTC")
            utc.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = utc.date(from: normalized) { return date }
        }
        
        if raw.count >= 19 {
            let prefix = String(raw.prefix(19))
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.date(from: prefix)
        }
        return nil
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
                    .fill(Color(hex: chatInfoModel.info?.channelIconColor ?? "66B2B2"))
                    .frame(width: 52, height: 52)
                
                let imageName = chatInfoModel.chatType == .manager ? "user" : "chat"
                Image(name: imageName)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "494949"))
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                    
                    if !timeText.isEmpty {
                        Text(timeText)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .lineLimit(1)
                    }
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Text(subtitleText)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .lineLimit(1)
                    
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
