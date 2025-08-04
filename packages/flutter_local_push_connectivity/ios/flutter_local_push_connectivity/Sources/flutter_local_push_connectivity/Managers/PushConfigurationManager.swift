/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A central object for coordinating changes to the NEAppPushManager configuration.
*/

import Foundation
import Combine
#if os(iOS)
import NetworkExtension
#endif
import HDPushKit

#if os(iOS)
class PushConfigurationManager: NSObject {
    static let shared = PushConfigurationManager()
    
    // A publisher that returns the active state of the current push manager.
    private(set) lazy var pushManagerIsActivePublisher = {
        pushManagerIsActiveSubject
        .debounce(for: .milliseconds(500), scheduler: dispatchQueue)
        .eraseToAnyPublisher()
    }()

    private let pushManagerDidLoadAllPublisher = PassthroughSubject<Bool, Never>()

    private let dispatchQueue = DispatchQueue(label: "PushConfigurationManager.dispatchQueue")
    private let logger = Logger(prependString: "PushConfigurationManager", subsystem: .general)
    private var pushManager: NEAppPushManager?
    private let pushManagerDescription = "SimplePushDefaultConfiguration"
    private let pushProviderBundleIdentifier = "com.hodoan.apple-samplecode.SimplePush.SimplePushProvider"
    private let pushManagerIsActiveSubject = CurrentValueSubject<Bool, Never>(false)
    private var pushManagerIsActiveCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        // Create, update, or delete the push manager when SettingsManager.hostSSIDPublisher produces a new value.
        SettingsManager.shared.settingsDidWritePublisher
            .compactMap { settings in
                settings.pushManagerSettings
            }
            .removeDuplicates()
            .combineLatest(pushManagerDidLoadAllPublisher)
            .receive(on: dispatchQueue)
            .compactMap { [self] pushManagerSettings, pushManagerDidLoadAll -> AnyPublisher<Result<NEAppPushManager?, Swift.Error>, Never>? in

                // If the NEAppPushManager.loadAllFromPreferences has not yet completed
                // we should stop processing and return.
                guard pushManagerDidLoadAll else {
                    return nil
                }

                var publisher: AnyPublisher<NEAppPushManager?, Swift.Error>?
                if !pushManagerSettings.isEmpty {
                    // Create a new push manager or update the existing instance with the new values from settings.
                    logger.log("Saving new push manager configuration.")
                    publisher = save(pushManager: pushManager ?? NEAppPushManager(), with: pushManagerSettings)
                        .flatMap { [self] pushManager -> AnyPublisher<NEAppPushManager, Error> in
                            // Reload the push manager.
                            logger.log("Loading new push manager configuration.")
                            return pushManager.load()
                        }
                        .map { $0 }
                        .eraseToAnyPublisher()
                } else if let pushManager = pushManager {
                    // Remove the push manager and map its value to nil to indicate removal of the push manager to the downstream subscribers.
                    logger.log("Removing push manager configuration.")
                    publisher = pushManager.remove()
                        .map { _ in nil }
                        .eraseToAnyPublisher()
                }

                return publisher?.unfailable()
            }
            .switchToLatest()
            .receive(on: dispatchQueue)
            .sink { [self] result in
                switch result {
                case .success(let pushManager):
                    if let pushManager = pushManager {
                        prepare(pushManager: pushManager)
                    } else {
                        cleanup()
                    }
                case .failure(let error):
                    logger.log("\(error)")
                }
            }.store(in: &cancellables)
    }

    func initialize() {
        logger.log("Loading existing push manager.")

        // It is important to call loadAllFromPreferences as early as possible during app initialization in order to set the delegate on your
        // NEAppPushManagers. This allows your NEAppPushManagers to receive an incoming call.
        NEAppPushManager.loadAllFromPreferences { managers, error in
            if let error = error {
                self.logger.log("Failed to load all managers from preferences: \(error)")
                self.pushManagerDidLoadAllPublisher.send(true)
                return
            }

            guard let manager = managers?.first else {
                self.pushManagerDidLoadAllPublisher.send(true)
                return
            }
            
            // The manager's delegate must be set synchronously in this closure in order to avoid race conditions when the app launches in response
            // to an incoming call.
            manager.delegate = self
            
            self.dispatchQueue.async {
                self.prepare(pushManager: manager)
                self.pushManagerDidLoadAllPublisher.send(true)
            }
        }
    }
    
    private func prepare(pushManager: NEAppPushManager) {
        self.pushManager = pushManager
        
        if pushManager.delegate == nil {
            pushManager.delegate = self
        }
        
        // Observe changes to the manager's `isActive` property and send the value out on the `pushManagerIsActiveSubject`.
        pushManagerIsActiveCancellable = NSObject.KeyValueObservingPublisher(object: pushManager, keyPath: \.isActive, options: [.initial, .new])
        .subscribe(pushManagerIsActiveSubject)
    }

    typealias SavePublisher = AnyPublisher<NEAppPushManager, Swift.Error>
    private func save(pushManager: NEAppPushManager,
                      with pushManagerSettings: Settings.PushManagerSettings) -> SavePublisher {
        pushManager.localizedDescription = pushManagerDescription
        pushManager.providerBundleIdentifier = pushProviderBundleIdentifier
        pushManager.delegate = self
        pushManager.isEnabled = true
        
        // The provider configuration passes global variables; don't put user-specific info in here (which could expose sensitive user info when
        // running on a shared iPad).
        pushManager.providerConfiguration = [
            "host": pushManagerSettings.host
        ]
        
        if !pushManagerSettings.ssid.isEmpty {
            pushManager.matchSSIDs = [pushManagerSettings.ssid]
        } else {
            pushManager.matchSSIDs = []
        }
        
        if !pushManagerSettings.mobileCountryCode.isEmpty && !pushManagerSettings.mobileNetworkCode.isEmpty {
            let privateLTENetwork = NEPrivateLTENetwork()
            privateLTENetwork.mobileCountryCode = pushManagerSettings.mobileCountryCode
            privateLTENetwork.mobileNetworkCode = pushManagerSettings.mobileNetworkCode
            
            if !pushManagerSettings.trackingAreaCode.isEmpty {
                privateLTENetwork.trackingAreaCode = pushManagerSettings.trackingAreaCode
            } else {
                privateLTENetwork.trackingAreaCode = nil
            }
            
            pushManager.matchPrivateLTENetworks = [privateLTENetwork]
        } else {
            pushManager.matchPrivateLTENetworks = []
        }

        // TODO(ho-doan): accout apple free not support matchEthernet | lib is delete this variable, please check this
        // pushManager.matchEthernet = pushManagerSettings.matchEthernet

        return pushManager.save()
    }
    
    private func cleanup() {
        pushManager = nil
        pushManagerIsActiveCancellable = nil
        pushManagerIsActiveSubject.send(false)
    }
}

extension PushConfigurationManager: NEAppPushDelegate {
    func appPushManager(_ manager: NEAppPushManager, didReceiveIncomingCallWithUserInfo userInfo: [AnyHashable: Any] = [:]) {
        logger.log("NEAppPushDelegate received an incoming call")
        
        guard let senderName = userInfo["senderName"] as? String,
            let senderUUIDString = userInfo["senderUUIDString"] as? String,
            let senderUUID = UUID(uuidString: senderUUIDString) else {
                logger.log("userInfo dictionary is missing a required field")
                return
        }
        
        let sender = User(uuid: senderUUID, deviceName: senderName)
        let routing = Routing(sender: sender, receiver: UserManager.shared.currentUser)
        let invite = Invite(routing: routing)
        
        // Trigger `CallManager` workflow which launches `CallKit` to alert the user to the call.
        CallManager.shared.receiveCall(from: invite)
    }
}

extension NEAppPushManager {
    func load() -> AnyPublisher<NEAppPushManager, Error> {
        Future { [self] promise in
            loadFromPreferences { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(self))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func save() -> AnyPublisher<NEAppPushManager, Error> {
        Future { [self] promise in
            saveToPreferences { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(self))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func remove() -> AnyPublisher<NEAppPushManager, Error> {
        Future { [self] promise in
            removeFromPreferences(completionHandler: { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(self))
            })
        }
        .eraseToAnyPublisher()
    }
}
#endif
