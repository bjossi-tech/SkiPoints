import SwiftUI

/// An error display view with a retry button
struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Convenience initializer with error message string
extension ErrorView {
    init(message: String, retryAction: @escaping () -> Void) {
        self.init(
            error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message]),
            retryAction: retryAction
        )
    }
}

#Preview {
    ErrorView(message: "Failed to load races. Please check your internet connection.") {
        print("Retry tapped")
    }
}
