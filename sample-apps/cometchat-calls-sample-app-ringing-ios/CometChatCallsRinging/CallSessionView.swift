import SwiftUI
import UIKit

/// The call screen: the Calls SDK's call UI, plus a banner while the connection recovers.
struct CallSessionView: View {
    @ObservedObject var viewModel: CallSessionViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            CallContainerView { container in
                viewModel.joinSession(container: container)
            }

            if viewModel.showReconnecting {
                VStack {
                    reconnectingBanner
                    Spacer()
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background: viewModel.enterPiP()
            case .active: viewModel.exitPiP()
            default: break
            }
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss { dismiss() }
        }
    }

    private var reconnectingBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
            Text("Reconnecting…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.statusError.opacity(0.9))
        .cornerRadius(8)
        .padding(.top, 50)
    }
}

// MARK: - CallContainerView

/// The UIView the Calls SDK renders its call UI into.
private struct CallContainerView: UIViewRepresentable {
    /// Called once, with the view to pass to `CometChatCalls.joinSession(container:)`.
    let onContainerReady: (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        onContainerReady(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
