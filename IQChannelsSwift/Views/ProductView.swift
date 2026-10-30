import SwiftUI


struct IQProductTap: Codable, Equatable, Identifiable, Hashable {
    var id: Int = 0
    var messageID: Int = 0
    var isAccept: Bool = false
}

struct ProductView: View {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    let message: IQMessage
    let onProductTapCompletion: ((IQProductTap) -> Void)?
    
    // MARK: - BODY
    var body: some View {
        VStack(alignment: message.isMy ?? false ? .trailing : .leading, spacing: 4) {
            TextMessageCellView(message: message)
            
            if let product = message.product, message.productOfferState == "pending" {
//                ForEach(singleChoices) { singleChoice in
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
                
                let map = [
                    "year": "год",
                    "month": "месяц",
                    "day": "день"
                ]
                
                let text: String = {
                    if product.periodicPaymentPrice == 0 {
                        return "Подключить продукт бесплатно"
                    } else {
                        return "Подключить продукт за \(product.periodicPaymentPrice)/\(map[product.periodicPaymentType ?? ""] ?? "")"
                    }
                }()
                
                
                Button {
                    let productTap = IQProductTap(
                        id: product.id,
                        messageID: message.messageID,
                        isAccept: true
                    )
                    onProductTapCompletion?(productTap)
                } label: {
                    if #available(iOS 16.0, *) {
                        Text(text)
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
                        Text(text)
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
                
                
                Button {
                    let productTap = IQProductTap(
                        id: product.id,
                        messageID: message.messageID,
                        isAccept: false
                    )
                    onProductTapCompletion?(productTap)
                } label: {
                    if #available(iOS 16.0, *) {
                        Text("Отказаться")
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
                        Text("Отказаться")
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
//                }
//                .onAppear(){
//                    print(singleChoices)
//                }
            }
        }
    }
}
