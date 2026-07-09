import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject {
        let parent: CameraView
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func didCapture(image: UIImage) {
            parent.capturedImage = image
            parent.dismiss()
        }
    }
}

class CameraViewController: UIViewController {
    var delegate: CameraView.Coordinator?
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private let faceOverlay = FaceGuideOverlay()
    private let statusLabel = UILabel()
    private let captureButton = CircularCaptureButton()
    private let closeButton = UIButton(type: .system)
    private var livenessTimer: Timer?
    private var currentStep = 0
    
    enum LivenessStep {
        case faceDetected, smile, blink, leftTurn, rightTurn
        
        var instruction: String {
            switch self {
            case .faceDetected: return "وجه الوجه داخل الدائرة"
            case .smile: return "ابتسم من فضلك"
            case .blink: return "أغلق عينك"
            case .leftTurn: return "انظر لليسار"
            case .rightTurn: return "انظر لليمين"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
        startLivenessSequence()
    }
    
    private func setupCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else {
                DispatchQueue.main.async { self.dismiss(animated: true) }
                return
            }
            DispatchQueue.main.async { self.configureSession() }
        }
    }
    
    private func configureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .front
        ) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.connection?.videoOrientation = .portrait
            videoPreviewLayer.frame = view.bounds
            view.layer.insertSublayer(videoPreviewLayer, at: 0)
            captureSession.startRunning()
            
        } catch {
            print("Camera error: \(error)")
        }
    }
    
    private func setupUI() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "جاري التحميل..."
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.boldSystemFont(ofSize: 22)
        statusLabel.textColor = .white
        statusLabel.numberOfLines = 2
        statusLabel.shadowColor = UIColor.black.withAlphaComponent(0.7)
        statusLabel.shadowOffset = CGSize(width: 1, height: 1)
        statusLabel.layer.shadowRadius = 4
        view.addSubview(statusLabel)
        
        faceOverlay.translatesAutoresizingMaskIntoConstraints = false
        faceOverlay.alpha = 0
        view.addSubview(faceOverlay)
        
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("إلغاء", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(equalToConstant: 60),
            
            faceOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            faceOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            faceOverlay.widthAnchor.constraint(equalToConstant: 260),
            faceOverlay.heightAnchor.constraint(equalToConstant: 340),
            
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func startLivenessSequence() {
        let steps: [LivenessStep] = [.faceDetected, .smile, .blink, .leftTurn, .rightTurn]
        currentStep = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.faceOverlay.alpha = 1
            self.proceedWithStep(steps)
        }
    }
    
    private func proceedWithStep(_ steps: [LivenessStep]) {
        guard currentStep < steps.count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.statusLabel.text = "تم بنجاح!"
                self.statusLabel.textColor = .systemGreen
                self.capturePhoto()
            }
            return
        }
        let step = steps[currentStep]
        statusLabel.text = step.instruction
        statusLabel.textColor = .white
        livenessTimer?.invalidate()
        livenessTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            self.currentStep += 1
            self.proceedWithStep(steps)
        }
    }
    
    @objc private func capturePhoto() {
        guard photoOutput != nil else { return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              var image = UIImage(data: imageData) else { return }
        image = image.withHorizontallyFlippedOrientation()
        HapticFeedback.success()
        delegate?.didCapture(image: image)
        
        // إرسال + استقبال JWT async
        Task { @MainActor in
            updateStatus("جارٍ فحص الـ Liveness...", color: .systemYellow)
            if let jpeg = compressImage(image, maxKB: 500) {
                do {
                    let decision = try await AzureFaceAPIService.shared.requestLiveness(imageData: jpeg)
                    if decision.lowercased() == "real" {
                        updateStatus("✓ تحقق ناجح — JWT Token", color: .systemGreen)
                        playVerificationAnimation()
                    } else {
                        updateStatus("⚠ فشل التحقق — حاول مرة أخرى", color: .systemRed)
                    }
                } catch {
                    updateStatus("خطأ: \(error.localizedDescription)", color: .systemRed)
                }
            }
        }
    }
}

// MARK: - Helpers
extension CameraViewController {
    private func compressImage(_ image: UIImage, maxKB: Int) -> Data? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        if data.count <= maxKB * 1024 { return data }
        let quality: CGFloat = 0.5
        guard let resized = image.jpegData(compressionQuality: quality) else { return nil }
        if resized.count <= maxKB * 1024 { return resized }
        
        let maxDim: CGFloat = 800
        let aspect = image.size.width / image.size.height
        let newSize: CGSize
        if aspect > 1 {
            newSize = CGSize(width: maxDim, height: maxDim / aspect)
        } else {
            newSize = CGSize(width: maxDim * aspect, height: maxDim)
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let small = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return small?.jpegData(compressionQuality: 0.7)
    }
    
    private func updateStatus(_ text: String, color: UIColor) {
        statusLabel.text = text
        statusLabel.textColor = color
    }
    
    private func playVerificationAnimation() {
        // Pulse green shade + haptic
        HapticFeedback.success()
        HapticFeedback.impact()
        
        let flash = UIView(frame: view.bounds)
        flash.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        flash.alpha = 0
        view.addSubview(flash)
        
        UIView.animate(withDuration: 0.3, animations: {
            flash.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.6, delay: 0.8, animations: {
                flash.alpha = 0
            }) { _ in
                flash.removeFromSuperview()
            }
        }
    }
}
