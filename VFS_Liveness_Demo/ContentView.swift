import SwiftUI

struct ContentView: View {
    @State private var token: String = ""
    @State private var showLiveness = false
    @State private var livenessResult: LivenessResult?
    @State private var resultMessage: String?

    enum LivenessResult {
        case success
        case failure(String)
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if showLiveness {
                LivenessCoordinatorView(
                    token: token,
                    onResult: { success in
                        showLiveness = false
                        if success {
                            livenessResult = .success
                            resultMessage = "✓ Liveness check passed"
                        } else {
                            livenessResult = .failure("Liveness check failed")
                            resultMessage = "✗ Liveness check failed"
                        }
                    },
                    onCancel: {
                        showLiveness = false
                    }
                )
            } else {
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "faceid")
                        .font(.system(size: 72))
                        .foregroundColor(.white.opacity(0.7))

                    Text("VFS Liveness")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("الصق التوكن من VFS Logger ثم اضغط Start")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Token")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        TextEditor(text: $token)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)

                    if let msg = resultMessage {
                        Text(msg)
                            .font(.headline)
                            .foregroundColor(msg.hasPrefix("✓") ? .green : .red)
                            .padding(.horizontal)
                    }

                    Button(action: { showLiveness = true }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Liveness")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(token.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(token.isEmpty)
                    .padding(.horizontal, 40)

                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
