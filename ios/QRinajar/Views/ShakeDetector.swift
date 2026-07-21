import SwiftUI
import UIKit

extension UIDevice {
    static let didShakeNotification = Notification.Name("QRinajarDeviceDidShake")
}

// UIKit routes device-motion shake events through the responder chain's
// motionEnded, which only ever reaches the window — there's no SwiftUI
// gesture for it, so this is the standard bridge: override it once here
// and broadcast a notification any view can subscribe to.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.didShakeNotification, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIDevice.didShakeNotification)) { _ in
            action()
        }
    }
}
