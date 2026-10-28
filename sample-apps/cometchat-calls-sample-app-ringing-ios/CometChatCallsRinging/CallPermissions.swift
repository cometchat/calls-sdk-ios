import AVFoundation

/// Asks for what a call needs before it is placed.
enum CallPermissions {
    /// Asks for the microphone, and the camera when `video` is set. Completes on the main queue.
    static func request(video: Bool, completion: @escaping (Bool) -> Void) {
        request(.audio) { micGranted in
            guard micGranted, video else { return completion(micGranted) }
            request(.video, completion: completion)
        }
    }

    private static func request(_ mediaType: AVMediaType, completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: mediaType) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }
}
