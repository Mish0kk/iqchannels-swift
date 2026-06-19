import SwiftUI
import SDWebImageSwiftUI

struct AuthorizationView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    let state: IQChannelsState
    let infoChatSettings: IQInfoChatSettings?
    let onDismissChat: (() -> Void)?
    
    
    let background = IQStyle.getColor(theme: IQStyle.model?.chat?.background) ?? Color(hex: "ffffff")
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            
            switch state {
                case .loggedOut:
                    getErrorView(isPm: false)
                case .noPm:
                    getErrorView(isPm: true)
                case .awaitingNetwork:
                    getLoadingView()
                case .authenticating:
                    getLoadingView()
                case .authenticated:
                    EmptyView()
                case .infoChatStub:
                    getInfoChatStubView()
            }
        }
    }
    
    // MARK: - VIEWS
    @ViewBuilder
    private func getLoadingView() -> some View {
        HStack(spacing: 4) {
            ProgressView()
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
        
        
        let errorButtonTextColor = IQStyle.getColor(theme: IQStyle.model?.error?.textButtonError?.color) ?? Color(hex: "000000")
        let errorButtonFontSize = CGFloat(IQStyle.model?.error?.textButtonError?.textSize ?? 16)
        let errorButtonIsBold = IQStyle.model?.error?.textButtonError?.textStyle?.bold ?? false
        let errorButtonIsItalic = IQStyle.model?.error?.textButtonError?.textStyle?.italic ?? false
        
        let errorButtonBackgroundColor = IQStyle.getColor(theme: IQStyle.model?.error?.backgroundButtonError?.color) ?? Color(hex: "F4F4F8")
        let errorButtonRadius = IQStyle.model?.error?.backgroundButtonError?.border?.borderRadius ?? 12
        let errorButtonBorderSize = IQStyle.model?.error?.backgroundButtonError?.border?.size ?? 0
        let errorButtonBorderColor = IQStyle.getColor(theme: IQStyle.model?.error?.backgroundButtonError?.border?.color) ?? Color(hex: "cccccc")
        
        
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
            
            Button {
                onDismissChat?()
            } label: {
                if #available(iOS 16.0, *) {
                    Text(IQLanguageTexts.model.buttonError ?? "Вернуться")
                        .font(.system(size: errorButtonFontSize, weight: .medium))
                        .foregroundColor(errorButtonTextColor)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(errorButtonBackgroundColor)
                        .cornerRadius(errorButtonRadius)
                        .bold(errorButtonIsBold)
                        .italic(errorButtonIsItalic)
                        .overlay(
                            RoundedRectangle(cornerRadius: errorButtonRadius)
                                .stroke(errorButtonBorderColor, lineWidth: errorButtonBorderSize)
                        )
                } else {
                    Text(IQLanguageTexts.model.buttonError ?? "Вернуться")
                        .font(.system(size: errorButtonFontSize, weight: .medium))
                        .foregroundColor(errorButtonTextColor)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(errorButtonBackgroundColor)
                        .cornerRadius(errorButtonRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: errorButtonRadius)
                                .stroke(errorButtonBorderColor, lineWidth: errorButtonBorderSize)
                        )
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
            AnimatedImage(url: infoChatSettings?.blockerIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            
            VStack(spacing: 8) {
                if #available(iOS 16.0, *) {
                    Text(infoChatSettings?.blockerText ?? "")
                        .foregroundColor(descriptionColor)
                        .font(.system(size: descriptionFontSize))
                        .bold(descriptionIsBold)
                        .italic(descriptionIsItalic)
                        .multilineTextAlignment(descriptionAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: descriptionAlignment) ?? .center)
                } else {
                    Text(infoChatSettings?.blockerText ?? "")
                        .foregroundColor(descriptionColor)
                        .font(.system(size: descriptionFontSize))
                        .multilineTextAlignment(descriptionAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(textAlignment: descriptionAlignment) ?? .center)
                }
            }
        }
    }
}
