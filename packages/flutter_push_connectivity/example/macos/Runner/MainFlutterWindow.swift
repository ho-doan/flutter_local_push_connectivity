import Cocoa
import FlutterMacOS
import flutter_push_connectivity
import UserNotifications
import HDPushKitMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = HDPushKitMOS.shared.setFrame(with: self.frame)
        
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        super.awakeFromNib()
    }
}
