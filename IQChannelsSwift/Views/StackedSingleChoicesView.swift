import SwiftUI

struct StackedSingleChoicesView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    let message: IQMessage
    let onSingleChoiceTapCompletion: ((IQSingleChoice) -> Void)?
    
    // MARK: - BODY
    var body: some View {
        VStack(alignment: message.isMy ?? false ? .trailing : .leading, spacing: 4) {
            TextMessageCellView(message: message)
            
            if let singleChoices = message.singleChoices {
                ForEach(singleChoices) { singleChoice in
                    let backgroundColor = IQStyle.getColor(theme: IQStyle.model?.singleChoice?.backgroundButton) ?? Color(hex: "AFB8BE")
                    let textColor = IQStyle.getColor(theme: IQStyle.model?.singleChoice?.textButton?.color) ?? Color.white
                    let fontSize = CGFloat(IQStyle.model?.singleChoice?.textButton?.textSize ?? 12)
                    
                    let isBold = IQStyle.model?.singleChoice?.textButton?.textStyle?.bold ?? false
                    let isItalic = IQStyle.model?.singleChoice?.textButton?.textStyle?.italic ?? false
                    let alignment = stringToAlignment(stringAlignment: IQStyle.model?.singleChoice?.textButton?.textAlign) ?? .center
                    let textAlignments: [TextAlignment: Alignment] = [
                        .leading: Alignment.leading,
                        .center: Alignment.center,
                        .trailing: Alignment.trailing
                    ]
                    
                    let borderColor = IQStyle.getColor(theme: IQStyle.model?.singleChoice?.borderButton?.color) ?? Color.clear
                    let lineWidth = CGFloat(IQStyle.model?.singleChoice?.borderButton?.size ?? 0)
                    let borderRadius = CGFloat(IQStyle.model?.singleChoice?.borderButton?.borderRadius ?? 4)
                    
                    if(singleChoice.deleted != true){
                        Button {
                            onSingleChoiceTapCompletion?(singleChoice)
                        } label: {
                            if #available(iOS 16.0, *) {
                                Text(singleChoice.title ?? "")
                                    .font(.system(size: fontSize))
                                    .foregroundColor(textColor)
                                    .frame(height: 32)
                                    .frame(maxWidth: .infinity, alignment: textAlignments[alignment] ?? Alignment.center)
                                    .background(backgroundColor)
                                    .cornerRadius(borderRadius)
                                    .bold(isBold)
                                    .italic(isItalic)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: borderRadius)
                                            .stroke(borderColor, lineWidth: lineWidth)
                                    )
                            } else {
                                Text(singleChoice.title ?? "")
                                    .font(.system(size: fontSize))
                                    .foregroundColor(textColor)
                                    .frame(height: 32)
                                    .frame(maxWidth: .infinity, alignment: textAlignments[alignment] ?? Alignment.center)
                                    .background(backgroundColor)
                                    .cornerRadius(borderRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: borderRadius)
                                            .stroke(borderColor, lineWidth: lineWidth)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}
