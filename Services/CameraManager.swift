import AVFoundation
import UIKit
import os.log

class CameraManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let logger = Logger(subsystem: "com.you.MirrorMind", category: "camera")
    
    @Published var capturedImage: UIImage?
    @Published var error: CameraError?
    @Published var isCameraReady = false
    @Published var faceRect: CGRect?
    
    enum CameraError: Error {
        case permissionDenied
        case configurationFailed
        case captureFailed
        case noFrontCamera
    }
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    deinit {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            requestPermission()
        default:
            error = .permissionDenied
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupCamera()
                } else {
                    self?.error = .permissionDenied
                }
            }
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.configureCaptureSession()
                DispatchQueue.main.async {
                    self.isCameraReady = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error as? CameraError ?? .configurationFailed
                    self.logger.error("Camera setup failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // ... rest of your existing CameraManager implementation ...
}