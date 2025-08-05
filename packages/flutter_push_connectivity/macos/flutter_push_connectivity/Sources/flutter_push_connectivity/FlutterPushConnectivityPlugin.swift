import Cocoa
import FlutterMacOS

public class FlutterPushConnectivityPlugin: NSObject, FlutterPlugin, PushConnectivityHostApi {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let api = FlutterPushConnectivityPlugin()
        PushConnectivityHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: api, messageChannelSuffix: "flutter_push_connectivity")
    }
    
    // MARK: - PushConnectivityHostApi Implementation
    
    public func initialize(host: String, portNotification: Int64, portControl: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement initialization logic
        // For now, just return success
        lauchProcess()
        completion(.success(()))
    }
    
    public func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement connection logic
        // For now, just return success
        completion(.success(()))
    }
    
    public func disconnect(completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement disconnection logic
        // For now, just return success
        completion(.success(()))
    }
    
    private func lauchProcess() {
        let process = Process()
//        let path = "\(Bundle.main.bundlePath)/Contents/MacOS/\(ProcessInfo.processInfo.processName)"
        let path = "\(Bundle.main.bundlePath)/Contents/MacOS/\(Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "")"
        print("path: \(path)")
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--from-parent"]
        process.standardOutput = nil
        process.standardError = nil
        process.standardInput = nil
        
        process.terminationHandler = nil
        process.qualityOfService = .background
//        process.standardOutput = FileHandle.nullDevice
//        process.standardError = FileHandle.nullDevice
//        process.standardInput = FileHandle.nullDevice
        
        do {
            try process.run()
            print("✅ Detached process started with PID \(process.processIdentifier)")
        } catch {
            print("❌ Failed to start detached process: \(error)")
        }
    }
}
