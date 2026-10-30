import SwiftUI

typealias Link = (String, NSRange)

struct TextLabel: UIViewRepresentable {
    typealias UIViewType = UILabel

    let text: NSAttributedString
    let linkRanges: [Link]
    var maxWidth: CGFloat = UIScreen.screenWidth / 1.5 - 24
    var onLinkTap: ((URL) -> Void)? = nil
    
    func makeUIView(context: Context) -> UILabel {
        let label: UILabel = .init()
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = maxWidth
        label.isUserInteractionEnabled = true
        label.lineBreakMode = .byWordWrapping
        
        context.coordinator.label = label
        
        let gesture = UITapGestureRecognizer(target: context.coordinator,
                                             action: #selector(context.coordinator.onLabelTap(gesture:)))
        gesture.delegate = context.coordinator
        label.addGestureRecognizer(gesture)
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = text
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    func makeCoordinator() -> Coordinator {
        return TextLabel.Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        
        weak var label: UILabel?
        
        var parent: TextLabel
        
        init(parent: TextLabel) {
            self.parent = parent
        }
        
        @objc
        func onLabelTap(gesture: UITapGestureRecognizer) {
            guard let label else { return }
            if let link = parent.linkRanges.first(where: { gesture.didTapAttributedTextInLabel(label: label, inRange: $0.1) }),
               let url = URL(string: link.0) {
                if IQChannelsManager.shouldHandleLink(url.absoluteString) {
                if let onLinkTap = parent.onLinkTap {
                    onLinkTap(url)
                } else {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
