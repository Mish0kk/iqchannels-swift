import SwiftUI
import Combine

extension View {
    func flippedUpsideDown() -> some View {
        self.modifier(FlippedUpsideDown())
    }
    
    func hideKeyboardOnTap(shouldAdd: Bool) -> some View {
        self.modifier(HideKeyboardOnTapGesture(shouldAdd: shouldAdd))
    }
    
    func hideKeyboardOnDrag() -> some View {
        self.modifier(HideKeyboardOnDragGesture())
    }
    
    func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
    
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
    
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in false })
            .eraseToAnyPublisher()
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}
struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
    }
}

struct FlippedUpsideDown: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .rotationEffect(.radians(Double.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

struct HideKeyboardOnTapGesture: ViewModifier {
    var shouldAdd: Bool
    var onTapped: (() -> Void)?

    public init(shouldAdd: Bool, onTapped: (() -> Void)? = nil) {
        self.shouldAdd = shouldAdd
        self.onTapped = onTapped
    }

    public func body(content: Content) -> some View {
        content
            .gesture(shouldAdd ? TapGesture().onEnded { _ in
                resignFirstResponder()
                if let onTapped = onTapped {
                    onTapped()
                }
            } : nil)
    }
}

struct HideKeyboardOnDragGesture: ViewModifier {
    public func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content.scrollDismissesKeyboard(.interactively)
        } else {
            content.gesture(DragGesture()
                .onChanged { _ in
                    resignFirstResponder()
                })
        }
    }
}

func iqMessageTextMaxWidth(isSender: Bool, horizontalInsets: CGFloat) -> CGFloat {
    UIScreen.screenWidth - (isSender ? 80 : 128) - horizontalInsets
}

func resignFirstResponder() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
