import SwiftUI

struct FaceScanView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var scanResults: [FacialRatio] = []
    @State private var isShowingResults = false
    @State private var isLoading = false
    @State private var faceRect: CGRect?
    @State private var error: Error?
    @State private var showPermissionAlert = false
    
    private var isCameraAvailable: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized && cameraManager.error == nil
    }
    
    var body: some View {
        ZStack {
            if let error = error {
                ErrorView(error: error) {
                    handleRetryAction(for: error)
                }
            } else if !isCameraAvailable {
                CameraUnavailableView()
            } else {
                cameraView
            }
        }
        .sheet(isPresented: $isShowingResults) {
            ResultsDashboard(ratios: scanResults)
        }
        .alert("Camera Access Required", 
               isPresented: $showPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to use this feature")
        }
        .onChange(of: cameraManager.error) { newError in
            handleCameraError(newError)
        }
        .onChange(of: cameraManager.capturedImage) { image in
            if let image = image {
                processImage(image)
            }
        }
        .onAppear {
            checkCameraAuthorization()
        }
    }
    
    private var cameraView: some View {
        ZStack {
            CameraPreview(layer: cameraManager.makePreviewLayer(), faceRect: $faceRect)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                }
                
                ScanButton(action: capturePhoto)
                    .padding(.bottom, 40)
                    .disabled(!isCameraAvailable)
            }
        }
    }
    
    private func capturePhoto() {
        guard isCameraAvailable else {
            error = CameraError.permissionDenied
            return
        }
        
        isLoading = true
        cameraManager.capturePhoto()
    }
    
    private func processImage(_ image: UIImage) {
        isLoading = true
        FaceAnalyzer().analyze(image: image) { result in
            isLoading = false
            switch result {
            case .success(let ratios):
                scanResults = ratios
                isShowingResults = true
            case .failure(let analysisError):
                error = analysisError
            }
        }
    }
    
    private func checkCameraAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied {
            showPermissionAlert = true
        }
    }
    
    private func handleCameraError(_ error: Error?) {
        guard let error = error else { return }
        
        if let cameraError = error as? CameraError,
           case .permissionDenied = cameraError {
            showPermissionAlert = true
        }
        self.error = error
    }
    
    private func handleRetryAction(for error: Error) {
        if let cameraError = error as? CameraError,
           case .permissionDenied = cameraError {
            openAppSettings()
        } else {
            self.error = nil
            cameraManager.setupCamera()
        }
    }
    
    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

struct CameraUnavailableView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Camera Unavailable")
                .font(.title.bold())
            
            Text("Please check your camera permissions or try again later")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.darkBackground)
    }
}

// Add this to your CameraManager's error enum
enum CameraError: Error {
    case permissionDenied
    case configurationFailed
    case captureFailed
    case noFrontCamera
    
    var localizedDescription: String {
        switch self {
        case .permissionDenied: return "Camera access was denied"
        case .configurationFailed: return "Failed to configure camera"
        case .captureFailed: return "Failed to capture photo"
        case .noFrontCamera: return "Front camera not available"
        }
    }
}