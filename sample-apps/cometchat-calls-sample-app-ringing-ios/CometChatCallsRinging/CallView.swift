import SwiftUI
import CometChatSDK
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
        Coordinator(sessionID: sessionID, onEnd: onEnd)
    }

    private func startSession(container: UIView, coordinator: Coordinator) {
        let settings = SessionSettingsBuilder()
            .setTitle("CometChat Call")
            .startVideoPaused(false)
            .startAudioMuted(false)
            .build()

        print("[CallView] Joining session with sessionID: \(sessionID)")

        CometChatCalls.joinSession(
            sessionID: sessionID,
            callSetting: settings,
            container: container
        ) { success in
            print("[CallView] Session started successfully")
            let session = CometChatCallsSDK.CallSession.shared
            session.addSessionStatusListener(coordinator)
            session.addButtonClickListener(coordinator)
            session.addParticipantEventListener(coordinator)
        } onError: { error in
            print("[CallView] joinSession error: \(error?.errorDescription ?? "unknown")")
            DispatchQueue.main.async {
                onError(error?.errorDescription ?? "Failed to join call")
            }
        }
    }

    class Coordinator: NSObject, SessionStatusListener, ButtonClickListener, ParticipantEventListener {
        let sessionID: String
        let onEnd: () -> Void
        private var participantCount = 0

        init(sessionID: String, onEnd: @escaping () -> Void) {
            self.sessionID = sessionID
            self.onEnd = onEnd
        }

        // MARK: - ParticipantEventListener

        func onUserJoined(_ user: CometChatCallsSDK.CallUser) {
            participantCount += 1
            print("[CallView] User joined: \(user.name ?? ""), count: \(participantCount)")
        }

        func onUserLeft(_ user: CometChatCallsSDK.CallUser) {
            participantCount -= 1
            print("[CallView] User left: \(user.name ?? ""), count: \(participantCount)")
            // For 1-on-1 calls, leave when the other user leaves
            if participantCount <= 0 {
                print("[CallView] No participants left, ending session")
                CometChatCallsSDK.CallSession.shared.leaveSession()
            }
        }

        func onUserListChanged(_ users: [CometChatCallsSDK.CallUser]) {
            participantCount = users.count
            print("[CallView] User list changed, count: \(participantCount)")
        }

        func onSessionJoined() {}

        func onSessionLeft() {
            endCallAndDismiss()
        }

        func onConnectionClosed() {
            endCallAndDismiss()
        }

        func onSessionTimedOut() {
            endCallAndDismiss()
        }

        func onConnectionLost() {}
        func onConnectionRestored() {}

        func onLeaveSessionButtonClicked() {
            CometChatCallsSDK.CallSession.shared.leaveSession()
        }

        /// Notify Chat SDK that the call has ended, then dismiss.
        private func endCallAndDismiss() {
            CometChat.endCall(sessionID: sessionID) { _ in
                print("[CallView] endCall success")
            } onError: { error in
                print("[CallView] endCall error: \(error?.errorDescription ?? "")")
            }
            DispatchQueue.main.async { self.onEnd() }
        }
    }
}
