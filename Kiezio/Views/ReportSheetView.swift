import SwiftUI

struct ReportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let targetName: String
    let onReport: (ReportReason) -> Void
    @State private var selectedReason: ReportReason = .spam
    @State private var didSubmit = false

    init(targetName: String = "Inhalt", onReport: @escaping (ReportReason) -> Void) {
        self.targetName = targetName
        self.onReport = onReport
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: KiezioSpacing.lg) {
                if didSubmit {
                    VStack(alignment: .leading, spacing: KiezioSpacing.md) {
                        Label("Danke fuer die Meldung", systemImage: "checkmark.circle.fill")
                            .font(.title3.bold())
                            .foregroundStyle(KiezioColor.green)
                        Text("\(targetName) wird anhand klarer Regeln geprueft. Bei nachvollziehbaren Meldungen wird die Reichweite reduziert, der Status markiert oder der Inhalt entfernt.")
                            .foregroundStyle(KiezioColor.muted)
                    }
                    .kiezioCard()
                    Spacer()
                } else {
                    Text("Warum meldest du diesen Inhalt?")
                        .font(.headline)

                    VStack(spacing: KiezioSpacing.sm) {
                        ForEach(ReportReason.allCases) { reason in
                            Button {
                                selectedReason = reason
                            } label: {
                                HStack(alignment: .top, spacing: KiezioSpacing.sm) {
                                    Image(systemName: reason.systemImage)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: KiezioSpacing.xs) {
                                        Text(reason.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                        Text(reason.reviewDetail)
                                            .font(.caption)
                                            .foregroundStyle(KiezioColor.muted)
                                    }
                                    Spacer()
                                    Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                }
                                .foregroundStyle(selectedReason == reason ? KiezioColor.teal : .primary)
                                .padding()
                                .background(KiezioColor.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("Meldung absenden") {
                        onReport(selectedReason)
                        didSubmit = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(KiezioSpacing.md)
            .background(KiezioColor.background)
            .navigationTitle("Melden")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(didSubmit ? "Fertig" : "Abbrechen") { dismiss() }
                }
            }
        }
    }
}
