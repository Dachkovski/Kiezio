import AVFoundation
import SwiftUI

struct VideoChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VideoChatViewModel
    @State private var showReport = false
    let onReport: ((ReportReason) -> Void)?
    let onBlock: (() -> Void)?

    init(peer: VideoPeer, onReport: ((ReportReason) -> Void)? = nil, onBlock: (() -> Void)? = nil) {
        _viewModel = State(initialValue: VideoChatViewModel(peer: peer))
        self.onReport = onReport
        self.onBlock = onBlock
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: KiezioSpacing.md) {
                callStage
                peerSummary
                safetyPanel
                controls
            }
            .padding(KiezioSpacing.md)
            .background(KiezioColor.background)
            .navigationTitle("Videoanruf")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") {
                        Task {
                            await viewModel.endCall()
                            dismiss()
                        }
                    }
                }
            }
            .alert("Videoanruf nicht bereit", isPresented: alertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage ?? "Bitte pruefe die Freigaben.")
            }
            .sheet(isPresented: $showReport) {
                ReportSheetView(targetName: "Videoanruf") { reason in
                    onReport?(reason)
                    viewModel.alertMessage = "Der Videoanruf wurde an die lokale Moderationsliste gemeldet."
                }
            }
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.alertMessage = nil
                }
            }
        )
    }

    private var callStage: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(KiezioColor.ink)
                .overlay {
                    VStack(spacing: KiezioSpacing.sm) {
                        Image(systemName: viewModel.isCallActive ? "person.crop.rectangle" : "video")
                            .font(.system(size: 52, weight: .semibold))
                        Text(viewModel.session?.state.title ?? "Bereit fuer sicheren 1:1 Videochat")
                            .font(.headline)
                        Text(viewModel.isCallActive ? "Mock-Verbindung aktiv. WebRTC-Signaling kann hier spaeter angeschlossen werden." : "Erst nach beidseitigem Opt-in starten.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .foregroundStyle(.white)
                    .padding()
                }

            if viewModel.session?.isCameraEnabled != false {
                CameraPreviewView()
                    .frame(width: 112, height: 152)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.28), lineWidth: 1)
                    }
                    .padding(KiezioSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.74, contentMode: .fit)
    }

    private var peerSummary: some View {
        HStack(spacing: KiezioSpacing.md) {
            Image(systemName: "person.crop.circle.badge.video")
                .font(.title2)
                .foregroundStyle(KiezioColor.teal)
                .frame(width: 48, height: 48)
                .background(KiezioColor.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: KiezioSpacing.xs) {
                Text(viewModel.peer.displayName)
                    .font(.headline)
                Text("\(viewModel.peer.areaLabel) · \(viewModel.peer.trustLabel)")
                    .font(.subheadline)
                    .foregroundStyle(KiezioColor.muted)
            }

            Spacer()
        }
        .kiezioCard()
    }

    private var safetyPanel: some View {
        VStack(alignment: .leading, spacing: KiezioSpacing.sm) {
            Toggle(isOn: $viewModel.safetyAccepted) {
                Text("Ich starte nur freiwillige, respektvolle Gespraeche.")
                    .font(.subheadline.weight(.semibold))
            }

            Label("Blockieren, Melden und Auflegen bleiben jederzeit sichtbar. Keine zufaellige Suche, kein Dating-Modus, keine genaue Standortanzeige.", systemImage: "shield.checkered")
                .font(.footnote)
                .foregroundStyle(KiezioColor.muted)
        }
        .kiezioCard()
    }

    private var controls: some View {
        VStack(spacing: KiezioSpacing.sm) {
            if viewModel.isCallActive {
                HStack(spacing: KiezioSpacing.sm) {
                    iconButton(
                        systemImage: viewModel.session?.isMuted == true ? "mic.slash.fill" : "mic.fill",
                        title: viewModel.session?.isMuted == true ? "Stumm aus" : "Stumm"
                    ) {
                        viewModel.toggleMute()
                    }

                    iconButton(
                        systemImage: viewModel.session?.isCameraEnabled == true ? "video.fill" : "video.slash.fill",
                        title: viewModel.session?.isCameraEnabled == true ? "Kamera aus" : "Kamera an"
                    ) {
                        viewModel.toggleCamera()
                    }

                    iconButton(systemImage: "flag.fill", title: "Melden", tint: KiezioColor.red) {
                        showReport = true
                    }

                    iconButton(systemImage: "hand.raised.fill", title: "Blockieren", tint: KiezioColor.ink) {
                        onBlock?()
                        Task {
                            await viewModel.endCall()
                            viewModel.alertMessage = "Kontakt blockiert. Der Anruf wurde beendet."
                        }
                    }
                }

                Button(role: .destructive) {
                    Task { await viewModel.endCall() }
                } label: {
                    Label("Anruf beenden", systemImage: "phone.down.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button {
                    Task { await viewModel.startCall() }
                } label: {
                    Label(viewModel.isPreparing ? "Freigaben pruefen" : "Videoanfrage starten", systemImage: "video.badge.checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canStartCall)
            }
        }
    }

    private func iconButton(systemImage: String, title: String, tint: Color = KiezioColor.ink, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(tint, in: Circle())
        }
        .accessibilityLabel(title)
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.start()
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        private let session = AVCaptureSession()

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        private var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        func start() {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill

            guard session.inputs.isEmpty,
                  let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  session.canAddInput(input) else { return }

            session.addInput(input)
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
}

#Preview {
    VideoChatView(peer: VideoPeer(id: "demo", displayName: "Kiezio Kontakt", areaLabel: "dein Bezirk", trustScore: 0.78, canReceiveCalls: true))
}
