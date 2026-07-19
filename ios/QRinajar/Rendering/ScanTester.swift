import UIKit
import Vision

// Offline scan self-test using Vision's VNDetectBarcodesRequest, mirroring the
// jsQR self-test in the web app.
enum ScanTester {
    enum Result {
        case ok
        case mismatch(String)
        case failed
    }

    static func test(image: CGImage, expected: String) -> Result {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return .failed
        }
        let results = (request.results ?? [])
        guard let payload = results.compactMap({ $0.payloadStringValue }).first else {
            return .failed
        }
        let want = expected.isEmpty ? " " : expected
        return payload == want ? .ok : .mismatch(payload)
    }
}
