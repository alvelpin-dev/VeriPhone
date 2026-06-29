import SwiftUI
import UIKit
import Combine

// MARK: - Frecuencia de actualización

private final class RefreshRateProbe: ObservableObject {
    @Published var measuredFPS: Double = 0
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount = 0
    private var accumulatedTime: CFTimeInterval = 0

    func start() {
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        frameCount += 1
        accumulatedTime += link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        if accumulatedTime >= 1.0 {
            measuredFPS = Double(frameCount) / accumulatedTime
            frameCount = 0
            accumulatedTime = 0
        }
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

struct DisplayRefreshTestContent: View {
    let device: DeviceModel
    let onComplete: TestCompletion

    @StateObject private var probe = RefreshRateProbe()

    private var maxSupportedFPS: Int { UIScreen.main.maximumFramesPerSecond }

    var body: some View {
        VStack(spacing: 16) {
            Text("\(Int(probe.measuredFPS)) Hz")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text("Máximo admitido por hardware: \(maxSupportedFPS) Hz")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if device.hasProMotion {
                Text("ProMotion detectado")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }

            Button("Confirmar resultado") {
                evaluate()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { probe.start() }
        .onDisappear { probe.stop() }
    }

    private func evaluate() {
        if device.hasProMotion && maxSupportedFPS < 90 {
            onComplete(.warning, "El dispositivo debería admitir ProMotion (120 Hz) pero el sistema reporta un máximo de \(maxSupportedFPS) Hz.")
        } else {
            onComplete(.pass, "Frecuencia máxima detectada: \(maxSupportedFPS) Hz.")
        }
    }
}

// MARK: - Píxeles muertos / manchas (pantallas de color sólido)

struct ColorPatternTestContent: View {
    let onComplete: TestCompletion

    private let colors: [Color] = [.black, .white, .red, .green, .blue]
    @State private var index = 0
    @State private var isFullscreen = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Se mostrarán \(colors.count) colores sólidos a pantalla completa. Observa con atención si aparecen píxeles muertos, manchas o variaciones de color.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Comenzar prueba de color") {
                index = 0
                isFullscreen = true
            }
            .buttonStyle(.borderedProminent)
        }
        .fullScreenCover(isPresented: $isFullscreen) {
            ColorPatternFullscreenView(colors: colors, index: $index, isFullscreen: $isFullscreen, onFinish: { sawDefect in
                if sawDefect {
                    onComplete(.fail, "El usuario detectó manchas o píxeles muertos durante la prueba de color.")
                } else {
                    onComplete(.pass, "No se detectaron defectos visuales durante la prueba de color.")
                }
            })
        }
    }
}

private struct ColorPatternFullscreenView: View {
    let colors: [Color]
    @Binding var index: Int
    @Binding var isFullscreen: Bool
    let onFinish: (Bool) -> Void

    var body: some View {
        ZStack {
            colors[index].ignoresSafeArea()
            VStack {
                Spacer()
                HStack {
                    Button("¿Hay defectos?") {
                        isFullscreen = false
                        onFinish(true)
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button(index == colors.count - 1 ? "Finalizar" : "Siguiente") {
                        if index == colors.count - 1 {
                            isFullscreen = false
                            onFinish(false)
                        } else {
                            index += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .foregroundStyle(colors[index] == .white ? .black : .white)
        .animation(.snappy, value: index)
    }
}

// MARK: - Multitáctil / ghost touch

struct MultitouchTestContent: View {
    let onComplete: TestCompletion
    @State private var touchPoints: [CGPoint] = []
    @State private var maxSimultaneous = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Coloca varios dedos sobre el recuadro a la vez para comprobar el multitáctil.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            MultitouchCanvas(touchPoints: $touchPoints, maxSimultaneous: $maxSimultaneous)
                .frame(height: 280)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

            Text("Máximo de toques simultáneos detectados: \(maxSimultaneous)")
                .font(.footnote)

            Button("Finalizar prueba") {
                if maxSimultaneous >= 5 {
                    onComplete(.pass, "Se detectaron \(maxSimultaneous) toques simultáneos.")
                } else if maxSimultaneous >= 2 {
                    onComplete(.warning, "Solo se detectaron \(maxSimultaneous) toques simultáneos. Intenta repetir la prueba con más dedos.")
                } else {
                    onComplete(.fail, "No se detectaron múltiples toques simultáneos.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct MultitouchCanvas: UIViewRepresentable {
    @Binding var touchPoints: [CGPoint]
    @Binding var maxSimultaneous: Int

    func makeUIView(context: Context) -> MultitouchUIView {
        let view = MultitouchUIView()
        view.onTouchesChanged = { points in
            touchPoints = points
            maxSimultaneous = max(maxSimultaneous, points.count)
        }
        return view
    }

    func updateUIView(_ uiView: MultitouchUIView, context: Context) {}
}

private final class MultitouchUIView: UIView {
    var onTouchesChanged: (([CGPoint]) -> Void)?
    private var activeTouches: Set<UITouch> = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.formUnion(touches)
        reportTouches()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        reportTouches()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.subtract(touches)
        reportTouches()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.subtract(touches)
        reportTouches()
    }

    private func reportTouches() {
        let points = activeTouches.map { $0.location(in: self) }
        onTouchesChanged?(points)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.systemBlue.cgColor)
        for touch in activeTouches {
            let point = touch.location(in: self)
            context.fillEllipse(in: CGRect(x: point.x - 20, y: point.y - 20, width: 40, height: 40))
        }
    }
}
