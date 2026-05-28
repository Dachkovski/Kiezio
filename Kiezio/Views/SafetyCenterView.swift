import SwiftUI

struct SafetyCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: HomeViewModel
    var onAccountDeleted: () -> Void = {}
    @State private var showDeleteConfirmation = false
    @State private var exportText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SafetyStatusRow(
                        systemImage: "location.viewfinder",
                        title: "Grobe Zone",
                        value: viewModel.zoneName,
                        detail: "Keine exakte Entfernung im Feed."
                    )
                    SafetyStatusRow(
                        systemImage: "person.crop.circle.badge.checkmark",
                        title: "Pseudonym",
                        value: "aktiv",
                        detail: "Oeffentliche Namen bleiben vom Account getrennt."
                    )
                    SafetyStatusRow(
                        systemImage: "shield.checkered",
                        title: "Moderation",
                        value: "sichtbar",
                        detail: "Melden, Blockieren und Stummschalten sind im Feed erreichbar."
                    )
                } header: {
                    Text("Privacy")
                }

                Section {
                    SafetyMetricRow(title: "Ausgeblendete Threads", value: viewModel.hiddenPostCount)
                    SafetyMetricRow(title: "Stumme Autoren", value: viewModel.mutedAuthorCount)
                    SafetyMetricRow(title: "Blockierte Autoren", value: viewModel.blockedAuthorCount)
                    SafetyMetricRow(title: "Meldungen in Pruefung", value: viewModel.actionableReportCount)
                } header: {
                    Text("Deine Kontrollen")
                }

                Section {
                    Label("Keine Doxxing-Hinweise oder lokale Identifizierung.", systemImage: "lock.shield")
                    Label("Keine Belästigung, Drohungen oder Hate Speech.", systemImage: "hand.raised")
                    Label("Keine genaue Standortanzeige oder zufällige Video-Suche.", systemImage: "video.slash")
                } header: {
                    Text("Community-Regeln")
                }

                Section {
                    Button {
                        viewModel.requestAppeal()
                    } label: {
                        Label(viewModel.appealRequested ? "Einspruch vorgemerkt" : "Einspruch starten", systemImage: "arrow.uturn.left.circle")
                    }

                    Button {
                        Task {
                            exportText = await viewModel.makeBackendDataExportText()
                        }
                    } label: {
                        Label(viewModel.dataExportRequested ? "Datenexport geladen" : "Datenexport laden", systemImage: "square.and.arrow.down")
                    }

                    ShareLink(
                        item: exportText.isEmpty ? viewModel.makeDataExportText() : exportText,
                        subject: Text("Kiezio Datenexport")
                    ) {
                        Label("Lokalen Datenexport teilen", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Lokale Accountdaten loeschen", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        Task { await viewModel.resetLocalData() }
                    } label: {
                        Label("Lokale Demo-Daten zuruecksetzen", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Die Loeschung entfernt lokale Daten, sendet die Account-Loeschung ans Backend und startet danach mit einer neuen pseudonymen Identitaet.")
                }

                Section {
                    Link(destination: AppConfiguration.supportMailURL) {
                        Label(AppConfiguration.supportEmail, systemImage: "envelope")
                    }
                    Link(destination: AppConfiguration.supportURL) {
                        Label("Support-Seite", systemImage: "questionmark.circle")
                    }
                    Link(destination: AppConfiguration.privacyPolicyURL) {
                        Label("Datenschutzerklaerung", systemImage: "lock")
                    }
                    Link(destination: AppConfiguration.termsURL) {
                        Label("Nutzungsregeln", systemImage: "doc.text")
                    }
                } header: {
                    Text("Kontakt & Rechtliches")
                } footer: {
                    Text("Diese URLs muessen vor TestFlight/App Store live und mit derselben Developer-Identitaet verknuepft sein.")
                }

                if !viewModel.reports.isEmpty {
                    Section {
                        ForEach(viewModel.reports) { report in
                            HStack(alignment: .top, spacing: KiezioSpacing.sm) {
                                Image(systemName: report.targetKind == .reply ? "text.bubble" : "doc.text")
                                    .foregroundStyle(KiezioColor.red)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: KiezioSpacing.xs) {
                                    Text(report.reason.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                    Text(report.status.displayName)
                                        .font(.caption)
                                        .foregroundStyle(KiezioColor.muted)
                                }
                                Spacer()
                                Text(report.createdAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(KiezioColor.muted)
                            }
                        }
                    } header: {
                        Text("Moderationsliste")
                    }
                }

                if !viewModel.safetyEvents.isEmpty {
                    Section {
                        ForEach(viewModel.safetyEvents) { event in
                            VStack(alignment: .leading, spacing: KiezioSpacing.xs) {
                                Text(event.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(event.detail)
                                    .font(.caption)
                                    .foregroundStyle(KiezioColor.muted)
                                Text(event.createdAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(KiezioColor.muted)
                            }
                            .padding(.vertical, KiezioSpacing.xs)
                        }
                    } header: {
                        Text("Letzte Safety-Aktionen")
                    }
                }
            }
            .navigationTitle("Safety Center")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Lokale Accountdaten loeschen?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Daten & Account loeschen", role: .destructive) {
                    Task {
                        await viewModel.deleteLocalAccountData()
                        dismiss()
                        onAccountDeleted()
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dies entfernt lokale Posts, Meldungen, Blockierungen, Trust-Signale und sendet die Loeschung ans Backend.")
            }
        }
    }
}

private struct SafetyStatusRow: View {
    let systemImage: String
    let title: String
    let value: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: KiezioSpacing.sm) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(KiezioColor.teal)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: KiezioSpacing.xs) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(value)
                        .foregroundStyle(KiezioColor.muted)
                }
                .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(KiezioColor.muted)
            }
        }
    }
}

private struct SafetyMetricRow: View {
    let title: String
    let value: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(value == 0 ? KiezioColor.muted : KiezioColor.teal)
        }
    }
}

#Preview {
    SafetyCenterView(viewModel: HomeViewModel())
}
