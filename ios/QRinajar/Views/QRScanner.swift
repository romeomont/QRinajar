import SwiftUI
import UIKit
import AVFoundation

// Persistent floating button, shown on every flow step, that scans a QR
// code with the camera and opens what it encodes in Safari. Requires a real
// device — the Simulator has no camera hardware to test the live feed.
struct ScannerButton: View {
    @State private var showPermissionExplainer = false
    @State private var showScanner = false
    @State private var showSettingsPrompt = false

    var body: some View {
        Button {
            handleTap()
        } label: {
            Image(systemName: "qrcode.viewfinder")
                .font(.title2)
                .frame(width: 52, height: 52)
        }
        .modifier(GlassProminentButtonStyle())
        .clipShape(Circle())
        .shadow(radius: 6, y: 3)
        .accessibilityLabel("Scan a QR code")
        .alert("Camera Access", isPresented: $showPermissionExplainer) {
            Button("Continue") { requestAccess() }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("QRinajar needs your camera to scan a QR code so it can open what it links to. The camera feed is only used live while scanning — nothing is recorded or uploaded.")
        }
        .alert("Camera Access Needed", isPresented: $showSettingsPrompt) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Camera access was previously denied. Enable it in Settings to scan QR codes.")
        }
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerView { payload in
                showScanner = false
                openScanned(payload)
            } onCancel: {
                showScanner = false
            }
        }
    }

    private func handleTap() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            showPermissionExplainer = true
        case .authorized:
            showScanner = true
        case .denied, .restricted:
            showSettingsPrompt = true
        @unknown default:
            showSettingsPrompt = true
        }
    }

    private func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    showScanner = true
                } else {
                    showSettingsPrompt = true
                }
            }
        }
    }

    // Per spec: a scanned code opens in Safari. Bare domains without a
    // scheme (e.g. "example.com") are treated as https.
    private func openScanned(_ payload: String) {
        if let url = URL(string: payload), let scheme = url.scheme,
           ["http", "https"].contains(scheme.lowercased()) {
            UIApplication.shared.open(url)
        } else if payload.contains("."), !payload.contains(" "),
                  let url = URL(string: "https://\(payload)") {
            UIApplication.shared.open(url)
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    var onFound: (String) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onFound = onFound
        vc.onCancel = onCancel
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onFound: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setUpCamera()
        setUpChrome()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setUpCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    private func setUpChrome() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
        ])

        let hint = UILabel()
        hint.text = "Point your camera at a QR code"
        hint.textColor = .white
        hint.font = .preferredFont(forTextStyle: .subheadline)
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)
        NSLayoutConstraint.activate([
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc private func cancelTapped() {
        session.stopRunning()
        onCancel?()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              obj.type == .qr, let payload = obj.stringValue else { return }
        hasScanned = true
        session.stopRunning()
        onFound?(payload)
    }
}
