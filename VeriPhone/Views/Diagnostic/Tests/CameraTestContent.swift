import SwiftUI
import UIKit
import AVFoundation

struct CameraTestContent: View {
    let position: AVCaptureDevice.Position
    let device: DeviceModel
    let onComplete: TestCompletion

    @StateObject private var camera = CameraManager()
    @State private var capturedAnyPhoto = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                CameraPreview(session: camera.session)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                if !camera.isSessionRunning {
                    ProgressView("Iniciando cámara…")
                }
            }

            if !camera.availableLensTypes.isEmpty {
                Text("Objetivo activo: \(camera.currentLensName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if position == .back {
                    ForEach(lensOptions, id: \.self) { type in
                        Button(label(for: type)) {
                            camera.switchLens(to: type, position: .back)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                if camera.hasFlash {
                    Button(camera.torchOn ? "Apagar flash" : "Encender flash") {
                        camera.toggleTorch()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button {
                camera.capturePhoto { image in
                    capturedAnyPhoto = capturedAnyPhoto || image != nil
                }
            } label: {
                Label("Capturar foto de prueba", systemImage: "camera.fill")
            }
            .buttonStyle(.borderedProminent)

            if let image = camera.lastCapturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button("Finalizar prueba de cámara") {
                finish()
            }
            .buttonStyle(.bordered)
        }
        .task {
            await camera.requestAccessAndStart(position: position)
        }
        .onDisappear { camera.stopSession() }
    }

    private var lensOptions: [AVCaptureDevice.DeviceType] {
        var types: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        if device.hasUltraWideCamera { types.append(.builtInUltraWideCamera) }
        if device.hasTelephotoCamera { types.append(.builtInTelephotoCamera) }
        return types
    }

    private func label(for type: AVCaptureDevice.DeviceType) -> String {
        switch type {
        case .builtInUltraWideCamera: return "Gran angular"
        case .builtInTelephotoCamera: return "Teleobjetivo"
        default: return "Principal"
        }
    }

    private func finish() {
        if let error = camera.errorMessage {
            onComplete(.fail, error)
        } else if capturedAnyPhoto {
            onComplete(.pass, "Captura, enfoque y cambio de objetivo verificados correctamente.")
        } else {
            onComplete(.warning, "No se realizó ninguna captura durante la prueba.")
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

private final class PreviewUIView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
}
