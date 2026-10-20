import SwiftUI

/// The caller's screen: "Calling… / Ringing…" until the callee answers, then the call itself.
struct OutgoingCallView: View {
    @ObservedObject var viewModel: OutgoingCallViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let callSessionViewModel = viewModel.callSessionViewModel {
                // Accepted: the call screen joins the session `initiateCall` prepared.
                CallSessionView(viewModel: callSessionViewModel)
            } else {
                ringingOverlay
            }
        }
        .onAppear { viewModel.start() }
        // Whatever took the screen down, the callee must not be left ringing.
        .onDisappear { viewModel.screenDismissed() }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss { dismiss() }
        }
    }

    // MARK: - Ringing Overlay

    private var ringingOverlay: some View {
        VStack(spacing: 0) {
            Text(viewModel.header.uppercased())
                .font(.system(size: 14))
                .tracking(1.1)
                .foregroundColor(.textSecondary)
                .padding(.top, 48)

            Spacer(minLength: 24)

            avatar

            Text(viewModel.calleeName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            Text(viewModel.statusText)
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
                .padding(.top, 8)

            Spacer(minLength: 24)

            endCallButton
                .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var avatar: some View {
        AsyncImage(url: URL(string: viewModel.calleeAvatarURL ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .fill(Color.borderPrimary)
                .overlay(
                    Text(String(viewModel.calleeName.prefix(1)).uppercased())
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.textSecondary)
                )
        }
        .frame(width: 128, height: 128)
        .clipShape(Circle())
    }

    private var endCallButton: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.cancelTapped()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 76, height: 76)
                    .background(Circle().fill(Color.statusError))
            }
            .disabled(!viewModel.canCancel)
            .opacity(viewModel.canCancel ? 1 : 0.4)

            Text("End call")
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
        }
    }
}
