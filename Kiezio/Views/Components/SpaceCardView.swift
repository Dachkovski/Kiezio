import SwiftUI

struct SpaceCardView: View {
    let space: KiezioSpace
    let postCount: Int
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: KiezioSpacing.sm) {
            HStack {
                Image(systemName: space.systemImage)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : space.tint)
                    .frame(width: 34, height: 34)
                    .background((isSelected ? .white.opacity(0.20) : .white.opacity(0.72)), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
                Text("\(postCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white.opacity(0.84) : space.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(space.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .white : KiezioColor.ink)
                Text(space.subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.78) : KiezioColor.ink.opacity(0.66))
                    .lineLimit(2)
            }
        }
        .frame(width: 168, height: 124, alignment: .topLeading)
        .padding(12)
        .background(isSelected ? space.tint : space.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? .clear : space.tint.opacity(0.16), lineWidth: 1)
        }
    }
}
