import AVFoundation
import Foundation

protocol VideoCallService {
    func prepareMediaPermissions() async -> MediaPermissionState
    func requestCall(with peer: VideoPeer) async -> VideoCallSession
    func connect(session: VideoCallSession) async -> VideoCallSession
    func end(session: VideoCallSession) async -> VideoCallSession
}

struct LocalMediaPermissionService {
    func requestPermissions() async -> MediaPermissionState {
        async let camera = AVCaptureDevice.requestAccess(for: .video)
        async let microphone = AVCaptureDevice.requestAccess(for: .audio)
        return await MediaPermissionState(cameraGranted: camera, microphoneGranted: microphone)
    }
}

struct MockVideoCallService: VideoCallService {
    private let mediaPermissionService = LocalMediaPermissionService()

    func prepareMediaPermissions() async -> MediaPermissionState {
        await mediaPermissionService.requestPermissions()
    }

    func requestCall(with peer: VideoPeer) async -> VideoCallSession {
        VideoCallSession(
            id: UUID(),
            peer: peer,
            state: peer.canReceiveCalls ? .requesting : .blocked,
            startedAt: nil,
            endedAt: nil,
            isMuted: false,
            isCameraEnabled: true,
            safetyAccepted: true
        )
    }

    func connect(session: VideoCallSession) async -> VideoCallSession {
        var connected = session
        guard connected.state != .blocked else { return connected }
        connected.state = .active
        connected.startedAt = Date()
        return connected
    }

    func end(session: VideoCallSession) async -> VideoCallSession {
        var ended = session
        ended.state = .ended
        ended.endedAt = Date()
        return ended
    }
}
