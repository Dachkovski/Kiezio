import SwiftUI

struct CategoryChip: View {
    let category: PostCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: KiezioSpacing.xs) {
            Image(systemName: category.systemImage)
            Text(category.rawValue)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isSelected ? category.feedForeground : category.tint)
        .frame(height: 38)
        .padding(.horizontal, 13)
        .background(isSelected ? category.feedSurface : category.softSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? .clear : category.tint.opacity(0.16), lineWidth: 1)
        }
    }
}
