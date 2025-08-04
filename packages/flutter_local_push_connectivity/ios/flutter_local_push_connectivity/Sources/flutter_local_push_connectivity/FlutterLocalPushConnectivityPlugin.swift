import Flutter
import UIKit

public class FlutterLocalPushConnectivityPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_local_push_connectivity", binaryMessenger: registrar.messenger())
        let instance = FlutterLocalPushConnectivityPlugin()
        DartCallManagerImlp.register(with: registrar)
        MessagingManagerImlp.register(with: registrar)
        ControlChannelImlp.register(with: registrar)
        UserManagerImlp.register(with: registrar)
        SettingsManagerImlp.register(with: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
