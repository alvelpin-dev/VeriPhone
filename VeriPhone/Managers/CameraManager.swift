import AVFoundation
import SwiftUI
import UIKit

/// Gestiona la sesión de captura para las pruebas de cámara trasera y frontal.
@MainActor
final class CameraManager: NSObject, ObservableObject {

    @Published var isSessionRunning = false
    @Published var lastCapturedImage: UIImage?
    @Published var availableLensTypes: [AVCaptureDevice.DeviceType] = []
    @Published var currentLensName: String = ""
    @Published var hasFlash = false
    @Published var torchOn = false
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var captureCompletion: ((UIImage?) -> Void)?

    func requestAccessAndStart(position: AVCaptureDevice.Position) async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else {
            errorMessage = "Permiso de cámara denegado."
            return
        }
        configureSession(position: position)
    }

    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .photo
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera, .builtInTrueDepthCamera],
            mediaType: .video, position: position
        )
        availableLensTypes = discovery.devices.map(\.deviceType)

        guard let device = discovery.devices.first ?? AVCaptureDevice.default(for: .video) else {
            errorMessage = "No se encontró ninguna cámara disponible."
            session.commitConfiguration()
            return
        }
        currentLensName = device.localizedName
        hasFlash = device.hasFlash

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
            currentInput = input
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        } catch {
            errorMessage = error.localizedDescription
        }
        session.commitConfiguration()

        Task.detached { [session] in
            session.startRunning()
            await MainActor.run { self.isSessionRunning = session.isRunning }
        }
    }

    func switchLens(to deviceType: AVCaptureDevice.DeviceType, position: AVCaptureDevice.Position) {
        guard let device = AVCaptureDevice.default(deviceType, for: .video, position: position) else { return }
        session.beginConfiguration()
        if let currentInput { session.removeInput(currentInput) }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
            currentInput = input
            currentLensName = device.localizedName
            hasFlash = device.hasFlash
        } catch {
            errorMessage = error.localizedDescription
        }
        session.commitConfiguration()
    }

    func toggleTorch() {
        guard let device = currentInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = torchOn ? .off : .on
            torchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stopSession() {
        session.stopRunning()
        isSessionRunning = false
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        Task { @MainActor in
            self.lastCapturedImage = image
            self.captureCompletion?(image)
        }
    }
}
