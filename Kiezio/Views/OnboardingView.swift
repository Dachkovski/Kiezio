import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var selection = 0
    @State private var acceptedRules = false

    private let pages = [
        OnboardingPage(title: "Deine Umgebung, ohne Laerm.", text: "Kiezio verbindet Fragen, Empfehlungen, Hilfe, Events und Humor aus deiner realen Umgebung.", image: "location.magnifyingglass"),
        OnboardingPage(title: "Grobe Naehe reicht.", text: "Wir zeigen keine exakten Entfernungen und keine oeffentliche Identitaet. Demo-Modus funktioniert ohne Standortfreigabe.", image: "hand.raised"),
        OnboardingPage(title: "Hilfreich, lokal, respektvoll.", text: "Gute Beitraege bekommen mehr Reichweite. Meldungen sind transparent und nachvollziehbar.", image: "checkmark.seal")
    ]

    var body: some View {
        VStack(spacing: KiezioSpacing.lg) {
            TabView(selection: $selection) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: KiezioSpacing.lg) {
                        Image(systemName: pages[index].image)
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 96, height: 96)
                            .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(spacing: KiezioSpacing.sm) {
                            Text(pages[index].title)
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)
                            Text(pages[index].text)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.78))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }

                        if index == pages.count - 1 {
                            rulesAcceptance
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(pages[index].surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal, KiezioSpacing.lg)
                    .tag(index)
                }
            }
            .onboardingPageStyle()

            Button(selection == pages.count - 1 ? "Loslegen" : "Weiter") {
                if selection == pages.count - 1 {
                    UserDefaults.standard.set(true, forKey: AppConfiguration.onboardingCompletedKey)
                    isCompleted = true
                } else {
                    withAnimation(.snappy) {
                        selection += 1
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selection == pages.count - 1 && !acceptedRules)
            .opacity(selection == pages.count - 1 && !acceptedRules ? 0.45 : 1)
            .padding(.horizontal, KiezioSpacing.lg)
            .padding(.bottom, KiezioSpacing.lg)
        }
        .background(KiezioColor.background)
    }

    private var rulesAcceptance: some View {
        VStack(alignment: .leading, spacing: KiezioSpacing.sm) {
            Toggle(isOn: $acceptedRules) {
                Text("Ich akzeptiere die Regeln: keine Belästigung, kein Doxxing, keine Drohungen, keine Hate Speech.")
                    .font(.subheadline.weight(.semibold))
            }
            .toggleStyle(.switch)

            HStack(spacing: KiezioSpacing.md) {
                Link("Regeln", destination: AppConfiguration.termsURL)
                Link("Datenschutz", destination: AppConfiguration.privacyPolicyURL)
                Link("Support", destination: AppConfiguration.supportURL)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(KiezioSpacing.md)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct OnboardingPage {
    let title: String
    let text: String
    let image: String
    var surface: Color {
        switch image {
        case "location.magnifyingglass": KiezioColor.teal
        case "hand.raised": KiezioColor.blue
        default: KiezioColor.green
        }
    }
}

private extension View {
    @ViewBuilder
    func onboardingPageStyle() -> some View {
        #if os(iOS)
        tabViewStyle(.page(indexDisplayMode: .always))
        #else
        self
        #endif
    }
}
