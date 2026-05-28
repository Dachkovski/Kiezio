import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: KiezioSpacing.md) {
            Image(systemName: "map")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
            Text("Noch nichts in diesem Space")
                .font(.headline)
            Text("Starte mit einer Frage, Empfehlung oder einem hilfreichen Hinweis fuer deine Umgebung.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.78))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(KiezioSpacing.lg)
        .background(KiezioColor.plum, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, KiezioSpacing.md)
    }
}
