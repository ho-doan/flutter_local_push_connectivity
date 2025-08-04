import HDPushKit
import Combine
import UIKit
import Foundation

public class FlutterLocalPushConnectivityManager {
    private let dispatchQueue = DispatchQueue(label: "FlutterLocalPushConnectivityManager.dispatchQueue")
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(prependString: "FlutterLocalPushConnectivityManager", subsystem: .general)
    
    public static let shared = FlutterLocalPushConnectivityManager()
    
    public func initialize() {
        PushConfigurationManager.shared.initialize()
        MessagingManager.shared.initialize()
        MessagingManager.shared.requestNotificationPermission()
        
        let currentUser = UserManager.shared.currentUser
        let user = User(uuid: currentUser.uuid, deviceName: currentUser.deviceName)
        ControlChannel.shared.register(user)
        
        isExecutingInBackgroundPublisher
            .combineLatest(CallManager.shared.$state)
            .sink { [weak self] isExecutingInBackground, callManagerState in
                guard let self = self else {
                    return
                }
                
                if isExecutingInBackground {
                    switch callManagerState {
                    case .connecting:
                        self.logger.log("App running in background and the CallManager's state is connecting, connecting to control channel")
                        ControlChannel.shared.connect()
                    case .disconnected:
                        self.logger.log("App running in background and the CallManager's state is disconnected, disconnecting from control channel")
                        ControlChannel.shared.disconnect()
                    default:
                        self.logger.log("App running in background")
                    }
                } else {
                    self.logger.log("App running in foreground, connecting to control channel")
                    ControlChannel.shared.connect()
                }
            }
            .store(in: &cancellables)
    }
    
    public func deinitialize() {
        logger.log("Application is terminating, disconnecting control channel")
        ControlChannel.shared.disconnect()
    }
    
    private(set) lazy var isExecutingInBackgroundPublisher: AnyPublisher<Bool, Never> = {
        Just(true)
            .merge(with:
                    NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                .merge(with: NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
                .map { notification -> Bool in
                    notification.name == UIApplication.didEnterBackgroundNotification
                }
            )
            .debounce(for: .milliseconds(100), scheduler: dispatchQueue)
            .eraseToAnyPublisher()
    }()
}
