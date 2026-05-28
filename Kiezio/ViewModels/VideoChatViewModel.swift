import Foundation
import Observation

@MainActor
@Observable
final class VideoChatViewModel {
    var peer: VideoPeer
    var session: VideoCallSession?
    var permissionState = MediaPermissionState(cameraGranted: false, microphoneGranted: false)
    var isPreparing = false
    var safetyAccepted = false
    var alertMessage: String?

    private let service: VideoCallService

    init(peer: VideoPeer, service: VideoCallService? = nil) {
        self.peer = peer
        self.service = service ?? MockVideoCallService()
    }

    var canStartCall: Bool {
        safetyAccepted && peer.canReceiveCalls && !isPreparing
    }

    var isCallActive: Bool {
        session?.state == .active
    }

    func startCall() async {
        guard canStartCall else { return }
        isPreparing = true
        permissionState = await service.prepareMediaPermissions()

        guard permissionState.isReady else {
            alertMessage = "Kamera und Mikrofon muessen fuer einen Videoanruf freigegeben sein."
            isPreparing = false
            return
        }

        var requested = await service.requestCall(with: peer)
        session = requested

        if requested.state == .blocked {
            alertMessage = "Dieser Kontakt kann aktuell keine Videoanfragen erhalten."
            isPreparing = false
            return
        }

        requested = await service.connect(session: requested)
        session = requested
        isPreparing = false
    }

    func endCall() async {
        guard let session else { return }
        self.session = await service.end(session: session)
    }

    func toggleMute() {
        session?.isMuted.toggle()
    }

    func toggleCamera() {
        session?.isCameraEnabled.toggle()
    }
}
