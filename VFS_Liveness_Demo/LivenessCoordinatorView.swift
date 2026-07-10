import SwiftUI

/// Orchestrates liveness detection.
///
/// ## Using the Azure SDK (recommended for real VFS integration):
/// 1. Add the AzureAIVisionFaceUI package via SPM:
///    `https://github.com/Azure/AzureAIVisionFaceUI`
/// 2. Follow setup: PAT token → Git LFS → SPM resolution
/// 3. Replace the body below with FaceLivenessDetectorView (example in comments)
struct LivenessCoordinatorView: View {
    let token: String
    let onResult: (Bool) -> Void
    let onCancel: () -> Void

    var body: some View {
        // ═══════════════════════════════════════════════════════════════
        // Azure SDK PATH (use this for real VFS integration):
        //
        // 1. import AzureAIVisionFaceUI at the top
        // 2. Replace this body with:
        //
        // @State var livenessResult: LivenessDetectionResult? = nil
        //
        // ZStack {
        //     if livenessResult == nil {
        //         FaceLivenessDetectorView(
        //             result: $livenessResult,
        //             sessionAuthorizationToken: token
        //         )
        //     } else if case .success(let success) = livenessResult {
        //         Color.green.overlay(
        //             VStack {
        //                 Image(systemName: "checkmark.circle.fill").font(.largeTitle)
        //                 Text("Liveness passed")
        //             }
        //             .foregroundColor(.white)
        //         ).onAppear { onResult(true) }
        //     } else {
        //         Color.red.overlay(
        //             VStack {
        //                 Image(systemName: "xmark.circle.fill").font(.largeTitle)
        //                 Text("Liveness failed")
        //             }
        //             .foregroundColor(.white)
        //         ).onAppear { onResult(false) }
        //     }
        // }
        // ═══════════════════════════════════════════════════════════════

        // Fallback: manual camera preview (does NOT process the token)
        ManualLivenessView(token: token, onResult: onResult, onCancel: onCancel)
    }
}

// MARK: - Fallback (no Azure SDK)

private struct ManualLivenessView: View {
    let token: String
    let onResult: (Bool) -> Void
    let onCancel: () -> Void

    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var isProcessing = false
    @State private var statusMessage: String?

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if showCamera {
                CameraView(capturedImage: $capturedImage)
            } else if isProcessing {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text(statusMessage ?? "Processing...")
                        .foregroundColor(.white)
                }
            } else if let _ = capturedImage {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("Capture complete")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("(Fallback mode — no Azure SDK)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Done") { onResult(true) }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 24) {
                    Text("Liveness Detection")
                        .font(.title)
                        .foregroundColor(.white)

                    Text("Fallback mode:\nuses manual camera instead of Azure SDK")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text("Token: \(token.prefix(20))...")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)

                    Button(action: { showCamera = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Open Camera")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)

                    Button("Cancel", role: .destructive, action: onCancel)
                }
            }
        }
        .onChange(of: capturedImage) { _ in
            if capturedImage != nil {
                isProcessing = true
                statusMessage = "Simulating liveness check..."

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    statusMessage = "✓ Liveness check passed (simulated)"
                    isProcessing = false
                }
            }
        }
    }
}
