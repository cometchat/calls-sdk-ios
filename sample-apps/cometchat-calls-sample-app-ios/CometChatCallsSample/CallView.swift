import SwiftUI
import CometChatCallsSDK

struct CallView: View {
    let sessionID: String
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CallContainerView(sessionID: sessionID, onEnd: { dismiss() }, onError: { msg in
                errorMessage = msg
            })
        }
        .alert("Call Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil; dismiss() } }
        )) {
            Button("OK") { errorMessage = nil; dismiss() }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

// MARK: - UIKit container for the call view

struct CallContainerView: UIViewRepresentable {
    let sessionID: String
    let onEnd: () -> Void
    let onError: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        startSession(container: container, coordinator: context.coordinator)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onEnd: onEnd)
    }

    private func startSession(container: UIView, coordinator: Coordinator) {
        let settings = SessionSettingsBuilder()
            .setTitle("CometChat Meeting")
            .startVideoPaused(false)
            .startAudioMuted(false)
            .build()

        print("[CallView] Joining session with sessionID: \(sessionID)")

        // Use the convenience joinSession(sessionID:) which handles token generation internally
        // This matches the CometChat Connect app pattern
        CometChatCalls.joinSession(
            sessionID: sessionID,
            callSetting: settings,
            container: container
        ) { success in
            print("[CallView] Session started successfully")
            let session = CometChatCallsSDK.CallSession.shared
            session.addSessionStatusListener(coordinator)
            session.addButtonClickListener(coordinator)
        } onError: { error in
            print("[CallView] joinSession error: \(error?.errorDescription ?? "unknown")")
            DispatchQueue.main.async {
                onError(error?.errorDescription ?? "Failed to join call")
            }
        }
    }

    class Coordinator: NSObject, SessionStatusListener, ButtonClickListener {
        let onEnd: () -> Void

        init(onEnd: @escaping () -> Void) {
            self.onEnd = onEnd
        }

        func onSessionJoined() {}

        func onSessionLeft() {
            DispatchQueue.main.async { self.onEnd() }
        }

        func onConnectionClosed() {
            DispatchQueue.main.async { self.onEnd() }
        }

        func onSessionTimedOut() {
            DispatchQueue.main.async { self.onEnd() }
        }

        func onConnectionLost() {}
        func onConnectionRestored() {}

        func onLeaveSessionButtonClicked() {
            CometChatCallsSDK.CallSession.shared.leaveSession()
        }
    }
}
