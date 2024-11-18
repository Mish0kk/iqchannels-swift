//
//  NewStyleModel.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 03.06.2024.
//

import Foundation

struct StyleModel: Decodable {
    let chat: ChatStyle?
    let messages: MessagesStyle?
    let answer: AnswerStyle?
    let messagesFile: MessagesFileStyle?
    let rating: RatingStyle?
    let toolsToMessage: ToolsToMessageStyle?
    let error: ErrorStyle?
    let singleChoice: SingleChoiceStyle?
    var theme: Apperance?

    enum CodingKeys: String, CodingKey {
        case chat
        case messages
        case answer
        case messagesFile = "messages_file"
        case rating
        case toolsToMessage = "tools_to_message"
        case error
        case singleChoice = "single-choice"
        case theme
    }
    
    enum Apperance: String, Decodable {
        case light, dark, system
    }

    struct ChatStyle: Decodable {
        let background: Theme?
        let dateText: TextStyle?
        let chatHistory: Theme?
        let iconOperator: URL?
        let systemText: TextStyle?

        enum CodingKeys: String, CodingKey {
            case background
            case dateText = "date_text"
            case chatHistory = "chat_history"
            case iconOperator = "icon_operator"
            case systemText = "system_text"
        }
    }

    struct MessagesStyle: Decodable {
        let backgroundOperator: Theme?
        let backgroundClient: Theme?
        let textOperator: TextStyle?
        let textClient: TextStyle?
        let replyTextClient: TextStyle?
        let replySenderTextClient: TextStyle?
        let replyTextOperator: TextStyle?
        let replySenderTextOperator: TextStyle?
        let textTime: TextStyle?
        let textUp: TextStyle?
        let textFileStateRejectedClient: TextStyle?
        let textFileStateOnCheckingClient: TextStyle?
        let textFileStateSentForCheckingClient: TextStyle?
        let textFileStateCheckErrorClient: TextStyle?
        let textFileStateRejectedOperator: TextStyle?
        let textFileStateOnCheckingOperator: TextStyle?
        let textFileStateSentForCheckingOperator: TextStyle?
        let textFileStateCheckErrorOperator: TextStyle?

        enum CodingKeys: String, CodingKey {
            case backgroundOperator = "background_operator"
            case backgroundClient = "background_client"
            case textOperator = "text_operator"
            case textClient = "text_client"
            case replyTextClient = "reply_text_client"
            case replySenderTextClient = "reply_sender_text_client"
            case replyTextOperator = "reply_text_operator"
            case replySenderTextOperator = "reply_sender_text_operator"
            case textTime = "text_time"
            case textUp = "text_up"
            case textFileStateRejectedClient = "text_file_state_rejected_client"
            case textFileStateOnCheckingClient = "text_file_state_on_checking_client"
            case textFileStateSentForCheckingClient = "text_file_state_sent_for_checking_client"
            case textFileStateCheckErrorClient = "text_file_state_check_error_client"
            case textFileStateRejectedOperator = "text_file_state_rejected_operator"
            case textFileStateOnCheckingOperator = "text_file_state_on_checking_operator"
            case textFileStateSentForCheckingOperator = "text_file_state_sent_for_checking_operator"
            case textFileStateCheckErrorOperator = "text_file_state_check_error_operator"
        }
    }

    struct AnswerStyle: Decodable {
        let textSender: TextStyle?
        let textMessage: TextStyle?
        let backgroundTextUpMessage: Theme?
        let iconCancel: URL?
        let leftLine: Theme?

        enum CodingKeys: String, CodingKey {
            case textSender = "text_sender"
            case textMessage = "text_message"
            case backgroundTextUpMessage = "background_text_up_message"
            case iconCancel = "icon_cancel"
            case leftLine = "left_line"
        }
    }

    struct MessagesFileStyle: Decodable {
        let textFilenameClient: TextStyle?
        let textFilenameOperator: TextStyle?
        let iconFileClient: URL?
        let iconFileOperator: URL?
        let textFileSizeClient: TextStyle?
        let textFileSizeOperator: TextStyle?

        enum CodingKeys: String, CodingKey {
            case textFilenameClient = "text_filename_client"
            case textFilenameOperator = "text_filename_operator"
            case iconFileClient = "icon_file_client"
            case iconFileOperator = "icon_file_operator"
            case textFileSizeClient = "text_file_size_client"
            case textFileSizeOperator = "text_file_size_operator"
        }
    }

    struct RatingStyle: Decodable {
        let backgroundContainer: Theme?
        let text: TextStyle?
        let textRating: TextStyle?
        let fullStar: URL?
        let emptyStar: URL?
        let sentRating: SentRating?
        
        struct SentRating: Decodable {
            let colorEnabled: Theme?
            let colorDisabled: Theme?
            let textEnabled: TextStyle?
            let textDisabled: TextStyle?
            
            enum CodingKeys: String, CodingKey {
                case colorEnabled = "color_enabled"
                case colorDisabled = "color_disabled"
                case textEnabled = "text_enabled"
                case textDisabled = "text_disabled"
            }
        }

        enum CodingKeys: String, CodingKey {
            case backgroundContainer = "background_container"
            case text
            case textRating = "text_rating"
            case fullStar = "full_star"
            case emptyStar = "empty_star"
            case sentRating = "sent_rating"
        }
    }

    struct ToolsToMessageStyle: Decodable {
        let iconSent: URL?
        let backgroundIcon: Theme?
        let backgroundChat: Theme?
        let textChat: TextStyle?
        let iconClip: URL?

        enum CodingKeys: String, CodingKey {
            case iconSent = "icon_sent"
            case backgroundIcon = "background_icon"
            case backgroundChat = "background_chat"
            case textChat = "text_chat"
            case iconClip = "icon_clip"
        }
    }

    struct ErrorStyle: Decodable {
        let titleError: TextStyle?
        let textError: TextStyle?
        let iconError: URL?

        enum CodingKeys: String, CodingKey {
            case titleError = "title_error"
            case textError = "text_error"
            case iconError = "icon_error"
        }
    }

    struct SingleChoiceStyle: Decodable {
        let backgroundButton: Theme?
        let borderButton: BorderStyle?
        let textButton: TextStyle?
        let backgroundIVR: Theme?
        let borderIVR: BorderStyle?
        let textIVR: TextStyle?

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

extension StyleModel {

    struct ColorTheme: Decodable {
        let color: Theme?
    }

    struct TextStyle: Decodable {
        let color: Theme?
        let textSize: Int?

        enum CodingKeys: String, CodingKey {
            case color
            case textSize = "text_size"
        }
    }

    struct BorderStyle: Decodable {
        let size: Int?
        let color: Theme?
        let borderRadius: Int?

        enum CodingKeys: String, CodingKey {
            case size
            case color
            case borderRadius = "border-radius"
        }
    }
}
