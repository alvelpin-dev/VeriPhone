import Foundation
import SwiftUI

/// Orquesta la lista de pruebas para el dispositivo detectado y el progreso
/// del usuario a través de ellas.
@MainActor
final class DiagnosticViewModel: ObservableObject {

    let device: DeviceModel
    @Published private(set) var tests: [DiagnosticTest]
    @Published private(set) var results: [String: TestResult] = [:]

    init(device: DeviceModel) {
        self.device = device
        self.tests = DiagnosticTestFactory.buildTests(for: device)
        for test in tests {
            results[test.id] = TestResult(id: test.id, status: .pending, message: "")
        }
    }

    func tests(in category: DiagnosticCategory) -> [DiagnosticTest] {
        tests.filter { $0.category == category }
    }

    func result(for test: DiagnosticTest) -> TestResult {
        results[test.id] ?? TestResult(id: test.id, status: .pending, message: "")
    }

    func record(status: TestStatus, message: String, for test: DiagnosticTest) {
        results[test.id] = TestResult(id: test.id, status: status, message: message)
    }

    var completedCount: Int {
        results.values.filter { $0.status != .pending }.count
    }

    var progress: Double {
        guard !tests.isEmpty else { return 0 }
        return Double(completedCount) / Double(tests.count)
    }

    var isComplete: Bool {
        completedCount == tests.count
    }

    /// Puntuación global: cada prueba correcta suma 1, atención suma 0.5,
    /// error suma 0, y las omitidas (`skipped`, hardware no presente) no
    /// participan en el cálculo.
    var overallScore: Double {
        let scored = results.values.filter { $0.status != .pending && $0.status != .skipped }
        guard !scored.isEmpty else { return 0 }
        let total = scored.reduce(0.0) { partial, result in
            switch result.status {
            case .pass: return partial + 1.0
            case .warning: return partial + 0.5
            default: return partial
            }
        }
        return total / Double(scored.count)
    }

    var overallScorePercentage: Int {
        Int((overallScore * 100).rounded())
    }

    var failingResults: [(DiagnosticTest, TestResult)] {
        tests.compactMap { test in
            guard let result = results[test.id], result.status == .fail || result.status == .warning else { return nil }
            return (test, result)
        }
    }
}
