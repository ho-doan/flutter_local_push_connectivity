//
//  main.swift
//  AppNotificationHelper
//
//  Created by TPS-User on 6/8/25.
//

import Foundation
//import HDPushKitMacOS
import Network
import AppKit

public class HDPushKitMOS: NSObject {
    public static let shared = HDPushKitMOS()
    
    public override init() {}
    
    public func setFrame(with frame: NSRect) -> NSRect {
        let args = CommandLine.arguments
        if args.contains("--from-helper") {
            return NSRect(x: 0, y: 0, width: 0, height: 0)
        }
        return frame
    }
    
    public func start() -> Bool {
        let args = CommandLine.arguments
        if !args.contains("--from-app") {
            return false
        }
        
        let indexApp = args.firstIndex(where: { $0 == "--from-app" })
        
        let indexHost = args.firstIndex(where: { $0 == "--host" })
        
        let indexPortNoti = args.firstIndex(where: { $0 == "--portNoti" })
        
        let indexPortControl = args.firstIndex(where: { $0 == "--portControl" })
        
        if let indexApp = indexApp, indexApp + 1 < args.count,
           let indexHost = indexHost, indexHost + 1 < args.count,
           let indexPortNoti = indexPortNoti, indexPortNoti + 1 < args.count,
           let indexPortControl = indexPortControl, indexPortControl + 1 < args.count {
            self.appPath = args[indexApp + 1]
            let host = args[indexHost + 1]
            let portNoti = Int64(args[indexPortNoti + 1])
            let portControl = Int64(args[indexPortControl + 1])
            
            self.host = NWEndpoint.Host(host)
            self.notificationPort = NWEndpoint.Port(rawValue: UInt16(exactly: portNoti!)!)
            self.controlPort = NWEndpoint.Port(rawValue: UInt16(exactly: portControl!)!)
            print("host: \(host), notificationPort: \(notificationPort), controlPort: \(controlPort)")
            connect()
            return true
        }
        
        return false
    }
    
    private var appPath: String!
    
    private var host: NWEndpoint.Host? = nil
    private var notificationPort: NWEndpoint.Port? = nil
    private var controlPort: NWEndpoint.Port? = nil
    
    private var connectionNotification: NWConnection? = nil
    private var connectionControl: NWConnection? = nil
    
    private var deviceName = UUID().uuidString
    
    private func connect() {
        var options : NWProtocolTCP.Options {
            let option = NWProtocolTCP.Options()
            option.noDelay = true
            return option
        }
        let parameters = NWParameters(tls: nil, tcp: options)
        print("state: connectionNotification")
        connectionNotification = NWConnection(host: host!, port: notificationPort!, using: parameters)
        
            print("state: connectionNotification \(connectionNotification != nil)")
        connectionNotification?.stateUpdateHandler = {
            state in
            print("state: connectionNotification \(state)")
            if state == .ready {
                self.register(self.connectionNotification, isNoti: true)
                self.receive(on: self.connectionNotification, isNoti: true)
            }
        }
        
        connectionNotification?.start(queue: .global())
        
        connectionControl = NWConnection(host: host!, port: controlPort!, using: parameters)
        
        connectionControl?.stateUpdateHandler = {
            state in
            print("state: connectionControl \(state)")
            if state == .ready {
                self.register(self.connectionControl, isNoti: false)
                self.receive(on: self.connectionControl, isNoti: false)
                self.startHeartbeat()
            }
        }
        connectionControl?.start(queue: .global())
    }
    private var heartbeatTimer: Timer? = nil
    private var heartbeatCount = 0
    private var lastHeartbeatResponse: Date?
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
        sendHeartbeat()
    }
    
    private func sendHeartbeat() {
        guard let conn = connectionControl else {
            heartbeatTimer?.invalidate()
            return
        }
        
        heartbeatCount += 1
        sendMessage(conn, ["count": heartbeatCount])
        
        if let last = lastHeartbeatResponse, Date().timeIntervalSince(last) > 30 {
            print("No heartbeat response in 30 seconds")
            handleSocketError(isNotification: false)
        }
    }
    
    private func handleSocketClosed(isNotification: Bool) {
            handleSocketError(isNotification: isNotification)
        }
    
    private func handleSocketError(isNotification: Bool) {
        if isNotification {
            connectionNotification?.cancel()
            connectionNotification = nil
        } else {
            connectionControl?.cancel()
            connectionControl = nil
            heartbeatTimer?.invalidate()
        }
        
        if connectionNotification == nil || connectionControl == nil {
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                self.connect()
            }
        }
    }
    
    
    private func register(_ connection: NWConnection?, isNoti: Bool) {
        let registration = ["deviceName": deviceName,"deviceId": deviceName]
        sendMessage(connection, registration)
        
    }
    
    private func handleControlMessage(_ message: [String: Any]) {
        if let count = message["count"] {
            print("Heartbeat respose received #\(count)")
        }
    }
    
    private func handleMessageNoti(_ message: [String: Any]) {
        // TODO: hodoan send bundleid
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.hodoan.flutterPushConnectivityExample")
        
        if apps.count > 1 {
            UserDefaults.standard.setValue("\(message)", forKey: "notification")
        } else {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: appPath)
            process.arguments = [appPath, "--args", "--from-helper","\(message)"]
            do {
                try process.run()
                print("sended")
            } catch {
                print("error \(error)")
            }
        }
    }
    
    private func handleData(_ data: Data, isNoti: Bool) {
        var buffer = data
        while buffer.count >= 4 {
            let length = buffer.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            
            guard buffer.count >= 4 + Int(length) else { break }
            let jsonData = buffer.subdata(in: 4..<4 + Int(length))
            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if isNoti {
                    handleMessageNoti(json)
                } else {
                    handleControlMessage(json)
                }
            }
            buffer.removeSubrange(0..<4 + Int(length))
        }
    }
    
    private func receive(on connection: NWConnection?, isNoti: Bool) {
        connection?.receive(minimumIncompleteLength: 4, maximumLength: 4096) {
            (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                self.handleData(data, isNoti: isNoti)
            }
            
            if isComplete {
                print("completed message")
            } else if error != nil {
                self.handleSocketClosed(isNotification: isNoti)
            } else {
                self.receive(on: connection, isNoti: isNoti)
            }
        }
    }
    
    private func sendMessage<T: Encodable>(_ connection: NWConnection?, _ message: T) {
        do {
            let data = try JSONEncoder().encode(message)
            var lengthPrefix = withUnsafeBytes(of: UInt32(data.count).bigEndian, Array.init)
            lengthPrefix.append(contentsOf: data)
            if #available(macOS 10.15, *) {
                connection?.send(content: lengthPrefix, completion: .contentProcessed({ _ in }))
            }
        } catch {
            print("Failed to encode/send message: \(error)")
        }
    }
}


func start() {
    do {
        let args = CommandLine.arguments
        print("aaa \(args)")
        
     try? HDPushKitMOS.shared.start()
    } catch {
        print(error)
    }
}
//let mos = HDPushKitMOS.shared.start()
//    let success: Bool = HDPushKitMOS().start()
    //if !success {
    //    exit(0)
    //}

start()

RunLoop.main.run()
