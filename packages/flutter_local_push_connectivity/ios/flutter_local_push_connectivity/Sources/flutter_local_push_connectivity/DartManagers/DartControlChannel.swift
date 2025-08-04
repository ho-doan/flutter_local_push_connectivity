import Flutter
import Combine
import HDPushKit

class ConnectionStateEvent: OnChangedStreamHandler {
    private var eventSink: PigeonEventSink<Any>? = nil
    
    func hasEvent()->Bool{
        return eventSink != nil
    }
    
    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Any>) {
        eventSink = sink
    }
    
    override func onCancel(withArguments arguments: Any?) {
        eventSink = nil
    }
    
    func success(_ state: PushConnectionState){
        eventSink?.success(state)
    }
    
    func error(err: String, message: String? = nil){
        eventSink?.error(code: "ERROR", message: err, details: message)
    }
}

class ControlChannelImlp : NSObject, FlutterPlugin, ControlChannelHostApi {
    static func register(with registrar: any FlutterPluginRegistrar) {
        let instance = ControlChannelImlp()
        ControlChannelHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance, messageChannelSuffix: "control_channel")
        
        OnChangedStreamHandler.register(with: registrar.messenger(), instanceName: "control_channel_connection_state", streamHandler: instance.stateEvent)

        ControlChannel.shared.statePublisher
            .combineLatest(SettingsManager.shared.settingsPublisher,
                           PushConfigurationManager.shared.pushManagerIsActivePublisher, instance.$users)
            .map { controlChannelState, settings, pushManagerIsActive, users -> PushConnectionState in
                guard !settings.pushManagerSettings.isEmpty else {
                    return .configurationNeeded
                }
                
                guard pushManagerIsActive else {
                    return .waitingForActivePushManager
                }
                
                switch controlChannelState {
                case .disconnected:
                    return .connecting
                case .disconnecting:
                    return .connecting
                case .connecting:
                    return .connecting
                case .connected where !users.isEmpty:
                    return .connected
                case .connected where users.isEmpty:
                    return .waitingForUsers
                default:
                    fatalError("Encountered a case that shouldn't happen")
                }
            }
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: instance.dispatchQueue)
            .receive(on: DispatchQueue.main)
            .sink {
                state in
                instance.stateEvent.success(state)
            }
            .store(in: &instance.cancellables)
        
        UserManager.shared.usersPublisher
            .debounce(for: .milliseconds(500), scheduler: instance.dispatchQueue)
            .receive(on: DispatchQueue.main)
            .sink {
                users in
                instance.users = users
            }
            .store(in: &instance.cancellables)
    }
    
    @Published var users = [User]()
    var stateEvent = ConnectionStateEvent()
    var cancellables = Set<AnyCancellable>()
    
    private let dispatchQueue = DispatchQueue(label: "ControlChannelImlp.dispatchQueue")
}
