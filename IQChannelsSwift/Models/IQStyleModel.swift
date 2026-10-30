//
//  NewStyleModel.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 03.06.2024.
//

import Foundation
import SwiftUI

struct IQStyleModel: Decodable {
    let appBar: AppBarStyle?
    let chat: ChatStyle?
    let messages: MessagesStyle?
    let answer: AnswerStyle?
    let messagesFile: MessagesFileStyle?
    let changeSegment: ChangeSegmentStyles?
    let rating: RatingStyle?
    let toolsToMessage: ToolsToMessageStyle?
    let error: ErrorStyle?
    let singleChoice: SingleChoiceStyle?
    let multiChat: MultiChatStyle?
    var theme: Apperance?

    enum CodingKeys: String, CodingKey {
        case appBar = "app_bar"
        case chat
        case messages
        case answer
        case messagesFile = "messages_file"
        case changeSegment = "change_segment"
        case rating
        case toolsToMessage = "tools_to_message"
        case error
        case singleChoice = "single-choice"
        case multiChat = "multi_chat"
        case theme
    }
    
    enum Apperance: String, Decodable {
        case light, dark, system
    }
    
    struct AppBarStyle: Decodable {
        let background: Theme?
        let backButton: Theme?
        let statusLabel: Text?
        let titleLabel: Text?
        let languageButton: Theme?
        let languageButtonText: Text?
        

        enum CodingKeys: String, CodingKey {
            case background
            case backButton = "back_button"
            case statusLabel = "status_label"
            case titleLabel = "title_label"
            case languageButton = "language_button"
            case languageButtonText = "language_button_text"
        }
    }

    struct ChatStyle: Decodable {
        let background: Theme?
        let dateText: Text?
        let chatHistory: Theme?
        let chatLoader: Theme?
        let chatLoaderIcon: URL?
        let iconOperator: URL?
        let systemText: Text?
        let newMessageBackground: Theme?
        let scrollDownButtonBackground: ContainerStyle?
        let scrollDownButtonIconColor: Theme?
        

        enum CodingKeys: String, CodingKey {
            case background
            case dateText = "date_text"
            case chatHistory = "chat_history"
            case chatLoader = "chat_loader"
            case chatLoaderIcon = "chat_loader_icon"
            case iconOperator = "icon_operator"
            case systemText = "system_text"
            case newMessageBackground = "new_message_background"
            case scrollDownButtonBackground = "scroll_down_button_background"
            case scrollDownButtonIconColor = "scroll_down_button_icon_color"
        }
    }

    struct MultiChatStyle: Decodable {
        let background: Theme?
        let iconRegularChat: URL?
        let iconPersonalManagerChat: URL?
        let iconInfoChat: URL?
        let backgroundIcon: Theme?
        let title: Text?
        let lastMessage: Text?

        enum CodingKeys: String, CodingKey {
            case background
            case iconRegularChat = "icon_regular_chat"
            case iconPersonalManagerChat = "icon_personal_manager_chat"
            case iconInfoChat = "icon_info_chat"
            case backgroundIcon = "background_icon"
            case title
            case lastMessage = "last_message"
        }
    }

    struct MessagesStyle: Decodable {
        let backgroundOperator: ContainerStyle?
        let backgroundClient: ContainerStyle?
        let textOperator: Text?
        let textClient: Text?
        let replyTextClient: Text?
        let replySenderTextClient: Text?
        let replyLeftLineClient: Theme?
        let replyTextOperator: Text?
        let replySenderTextOperator: Text?
        let replyLeftLineOperator: Theme?
        let textTimeOperator: Text?
        let textTimeClient: Text?
        let textUp: Text?
        let textFileStateRejectedClient: Text?
        let textFileStateOnCheckingClient: Text?
        let textFileStateSentForCheckingClient: Text?
        let textFileStateCheckErrorClient: Text?
        let textFileStateRejectedOperator: Text?
        let textFileStateOnCheckingOperator: Text?
        let textFileStateSentForCheckingOperator: Text?
        let textFileStateCheckErrorOperator: Text?
        let checkmarkRead: Theme?
        let checkmarkReceived: Theme?
        let sending: Theme?
        let errorIcon: Text?
        let errorBackground: Theme?
        let errorPopupMenuBackground: ContainerStyle?
        let errorPopupMenuText: Text?

        enum CodingKeys: String, CodingKey {
            case backgroundOperator = "background_operator"
            case backgroundClient = "background_client"
            case textOperator = "text_operator"
            case textClient = "text_client"
            case replyTextClient = "reply_text_client"
            case replySenderTextClient = "reply_sender_text_client"
            case replyLeftLineClient = "reply_left_line_client"
            case replyTextOperator = "reply_text_operator"
            case replySenderTextOperator = "reply_sender_text_operator"
            case replyLeftLineOperator = "reply_left_line_operator"
            case textTimeOperator = "text_time_operator"
            case textTimeClient = "text_time_client"
            case textUp = "text_up"
            case textFileStateRejectedClient = "text_file_state_rejected_client"
            case textFileStateOnCheckingClient = "text_file_state_on_checking_client"
            case textFileStateSentForCheckingClient = "text_file_state_sent_for_checking_client"
            case textFileStateCheckErrorClient = "text_file_state_check_error_client"
            case textFileStateRejectedOperator = "text_file_state_rejected_operator"
            case textFileStateOnCheckingOperator = "text_file_state_on_checking_operator"
            case textFileStateSentForCheckingOperator = "text_file_state_sent_for_checking_operator"
            case textFileStateCheckErrorOperator = "text_file_state_check_error_operator"
            case checkmarkRead = "checkmark_read"
            case checkmarkReceived = "checkmark_received"
            case sending = "sending"
            case errorIcon = "error_icon"
            case errorBackground = "error_background"
            case errorPopupMenuBackground = "error_popup_menu_background"
            case errorPopupMenuText = "error_popup_menu_text"
        }
    }

    struct AnswerStyle: Decodable {
        let textSender: Text?
        let textMessage: Text?
        let backgroundTextUpMessage: Theme?
        let iconCancel: URL?
        let leftLine: Theme?
        let textOperatorTyping: Text?
        let backgroundOperatorTyping: Theme?
        
        enum CodingKeys: String, CodingKey {
            case textSender = "text_sender"
            case textMessage = "text_message"
            case backgroundTextUpMessage = "background_text_up_message"
            case iconCancel = "icon_cancel"
            case leftLine = "left_line"
            case textOperatorTyping = "text_operator_typing"
            case backgroundOperatorTyping = "background_operator_typing"
        }
    }

    struct MessagesFileStyle: Decodable {
        let textFilenameClient: Text?
        let textFilenameOperator: Text?
        let iconFileClient: URL?
        let iconFileOperator: URL?
        let textFileSizeClient: Text?
        let textFileSizeOperator: Text?

        enum CodingKeys: String, CodingKey {
            case textFilenameClient = "text_filename_client"
            case textFilenameOperator = "text_filename_operator"
            case iconFileClient = "icon_file_client"
            case iconFileOperator = "icon_file_operator"
            case textFileSizeClient = "text_file_size_client"
            case textFileSizeOperator = "text_file_size_operator"
        }
    }
    
    struct ChangeSegmentStyles: Decodable {
        let backgroundContainer: ContainerStyle?
        let title: Text?
        let backgroundButton: ContainerStyle?
        let textButton: Text?

        enum CodingKeys: String, CodingKey {
            case backgroundContainer = "background_container"
            case title
            case backgroundButton = "background_button"
            case textButton = "text_button"
        }
    }

    struct RatingStyle: Decodable {
        let backgroundContainer: ContainerStyle?
        let ratingTitle: Text?
        let fullStar: URL?
        let emptyStar: URL?
        let sentRating: ButtonStyle?
        let answerButton: ButtonStyle?
        let scaleButton: ButtonStyle?
        let scaleMinText: Text?
        let scaleMaxText: Text?
        let inputBackground: ContainerStyle?
        let inputText: Text?
        let feedbackThanksText: Text?
        
        
        enum CodingKeys: String, CodingKey {
            case backgroundContainer = "background_container"
            case ratingTitle = "rating_title"
            case fullStar = "full_star"
            case emptyStar = "empty_star"
            case sentRating = "sent_rating"
            case answerButton = "answer_button"
            case scaleButton = "scale_button"
            case scaleMinText = "scale_min_text"
            case scaleMaxText = "scale_max_text"
            case inputBackground = "input_background"
            case inputText = "input_text"
            case feedbackThanksText = "feedback_thanks_text"
        }
    }

    struct ToolsToMessageStyle: Decodable {
        let background: Theme?
        let iconSent: URL?
        let backgroundIconSent: ContainerStyle?
        let iconClip: URL?
        let backgroundIconClip: ContainerStyle?
        let backgroundInput: ContainerStyle?
        let textInput: Text?
        let cursorColor: Theme?

        enum CodingKeys: String, CodingKey {
            case background
            case iconSent = "icon_sent"
            case backgroundIconSent = "background_icon_sent"
            case iconClip = "icon_clip"
            case backgroundIconClip = "background_icon_clip"
            case backgroundInput = "background_input"
            case textInput = "text_input"
            case cursorColor = "cursor_color"
        }
    }

    struct ErrorStyle: Decodable {
        let titleError: Text?
        let textError: Text?
        let iconError: URL?
        let backgroundButtonError: ContainerStyle?
        let textButtonError: Text?

        enum CodingKeys: String, CodingKey {
            case titleError = "title_error"
            case textError = "text_error"
            case iconError = "icon_error"
            case backgroundButtonError = "background_button_error"
            case textButtonError = "text_button_error"
        }
    }

    struct SingleChoiceStyle: Decodable {
        let backgroundButton: Theme?
        let borderButton: BorderStyle?
        let textButton: Text?
        let backgroundIVR: Theme?
        let borderIVR: BorderStyle?
        let textIVR: Text?

        enum CodingKeys: String, CodingKey {
            case backgroundButton = "background_button"
            case borderButton = "border_button"
            case textButton = "text_button"
            case backgroundIVR = "background_IVR"
            case borderIVR = "border_IVR"
            case textIVR = "text_IVR"
        }
    }
}

struct Theme: Decodable {
    let light: String?
    let dark: String?
}

extension IQStyleModel {
    struct ColorTheme: Decodable {
        let color: Theme?
    }

    struct Text: Decodable {
        let color: Theme?
        let textSize: Int?
        let textAlign: String?
        let textStyle: TextStyle?

        enum CodingKeys: String, CodingKey {
            case color
            case textSize = "text_size"
            case textAlign = "text_align"
            case textStyle = "text_style"
        }
    }
    
    struct TextStyle: Decodable {
        let bold: Bool?
        let italic: Bool?
    }

    struct BorderStyle: Decodable {
        let size: CGFloat?
        let color: Theme?
        let borderRadius: CGFloat?

        enum CodingKeys: String, CodingKey {
            case size
            case color
            case borderRadius = "border-radius"
        }
    }
    
    struct ContainerStyle: Decodable {
        let color: Theme?
        let border: BorderStyle?
    }
    
    struct ButtonStyle: Decodable {
        let backgroundEnabled: ContainerStyle?
        let backgroundDisabled: ContainerStyle?
        let textEnabled: Text?
        let textDisabled: Text?
        
        enum CodingKeys: String, CodingKey {
            case backgroundEnabled = "background_enabled"
            case backgroundDisabled = "background_disabled"
            case textEnabled = "text_enabled"
            case textDisabled = "text_disabled"
        }
    }

}

public func stringToAlignment(stringAlignment: String?) -> TextAlignment? {
    switch stringAlignment {
    case "left":
        return .leading
    case "center":
        return .center
    case "right":
        return .trailing
    default:
        return nil
    }
}

public func textAlignmentToAlignment(textAlignment: TextAlignment?) -> Alignment? {
    switch textAlignment {
    case .leading:
        return .leading
    case .center:
        return .center
    case .trailing:
        return .trailing
    default:
        return nil
    }
}


public func textAlignmentToHorizontalAlignment(textAlignment: TextAlignment?) -> HorizontalAlignment {
    switch textAlignment {
    case .leading:
        return .leading
    case .center:
        return .center
    case .trailing:
        return .trailing
    default:
        return .leading
    }
}


public func textAlignmentToNSTextAlignment(textAlignment: TextAlignment?) -> NSTextAlignment {
    switch textAlignment {
    case .leading:
        return .left
    case .center:
        return .center
    case .trailing:
        return .right
    default:
        return .center
    }
}
