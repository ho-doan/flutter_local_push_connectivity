import Cocoa
import UserNotifications
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    override func applicationWillFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        print("applicationWillFinishLaunching \(notification.userInfo?.keys) \(args)")
        
                if let index = args.firstIndex(where: { $0 ==  "--from-helper"}), index + 1 < args.count {
                    let body = args[index + 1]
                    print("body: \(body)")
                    let center = UNUserNotificationCenter.current()
                    let content = UNMutableNotificationContent()
                    content.title = "New message"
                    content.body = body
        
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
                    center.add(request) {
                        _ in
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NSApp.terminate(nil)
                        }
                    }
                } else {
                    NSApp.setActivationPolicy(.regular)
                }

    }
    
    override func applicationWillTerminate(_ notification: Notification) {
        let args = CommandLine.arguments
        print("applicationWillTerminate \(notification.userInfo?.keys) \(args)")
        return super.applicationWillTerminate(notification)
    }
}
