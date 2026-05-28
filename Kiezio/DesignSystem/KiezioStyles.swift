import SwiftUI

struct KiezioCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(KiezioSpacing.md)
            .background(KiezioColor.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(KiezioColor.line, lineWidth: 1)
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(KiezioColor.ink.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension View {
    func kiezioCard() -> some View {
        modifier(KiezioCardStyle())
    }
}
