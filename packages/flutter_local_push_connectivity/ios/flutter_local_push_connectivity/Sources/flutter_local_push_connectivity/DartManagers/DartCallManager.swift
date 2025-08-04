import Flutter
import Combine
import HDPushKit

class CallManagerStateEvent: OnChangedStreamHandler {
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
    
    func success(state: CallManager.State){
        var dartState: CallManagerStatePigeonEnum = .disconnected
        var userPigeon: UserPigeon? = nil
        var dartReason: TerminatedReasonPigeon? = nil
        switch state {
        case .disconnected: dartState = .disconnected
        case .connecting(let user):
            dartState = .connecting
            userPigeon = UserPigeon(uuid: user.uuid.uuidString, deviceName: user.deviceName)
        case .connected(let user):
            dartState = .connected
            userPigeon = UserPigeon(uuid: user.uuid.uuidString, deviceName: user.deviceName)
        case .disconnecting(let reason):
            dartState = .disconnecting
            switch reason {
            case .hungUp: dartReason = .hungUp
            case .callFailed: dartReason = .callFailed
            case .unavailable: dartReason = .unavailable
            }
        }
        
        eventSink?.success(CallManagerStatePigeon(state: dartState, user: userPigeon, terminatedReason: dartReason))
    }
    
    func error(err: String, message: String? = nil){
        eventSink?.error(code: "ERROR", message: err, details: message)
    }
}

class CallRuleEvent: OnChangedStreamHandler {
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
    
    func success(state: CallManager.CallRole){
        var dartState: CallRolePigeon = .receiver
        switch state {
        case .receiver: dartState = .receiver
        case .sender: dartState = .sender
        }
        
        eventSink?.success(dartState)
    }
    
    func error(err: String, message: String? = nil){
        eventSink?.error(code: "ERROR", message: err, details: message)
    }
}

class DartCallManagerImlp: NSObject, FlutterPlugin, CallManagerHostApi {
    func setUserAvailability(availability: UserAvailabilityPigeonEnum, completion: @escaping (Result<Void, any Error>) -> Void) {
        switch availability {
        case .available:
            self.userAvailability = .available
        case .unavailable:
            self.userAvailability = .unavailable
        }
    }
    
    let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }
    
    func setUser(user: UserPigeon, completion: @escaping (Result<Void, any Error>) -> Void) {
        let user_ = User(uuid: UUID(uuidString: user.uuid) ?? UUID(), deviceName: user.deviceName)
        self.user = user_
    }
    
    static func register(with registrar: any FlutterPluginRegistrar) {
        let instance = DartCallManagerImlp(messenger: registrar.messenger())
        CallManagerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance, messageChannelSuffix: "call_manager")
        OnChangedStreamHandler.register(with: registrar.messenger(), instanceName: "call_manager_state", streamHandler: instance.stateEvent)
        
        OnChangedStreamHandler.register(with: registrar.messenger(), instanceName: "call_manager_call_role", streamHandler: instance.callRuleEvent)
        
        OnChangedStreamHandler.register(with: registrar.messenger(), instanceName: "call_manager_call_state", streamHandler: instance.callStateEvent)
        
        CallManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink {
                state in
                instance.stateEvent.success(state: state)
            }
            .store(in: &instance.cancellables)
        
        CallManager.shared.callRolePublisher.dropNil().receive(on: DispatchQueue.main)
            .sink {
                rule in
                instance.callRuleEvent.success(state: rule)
            }
            .store(in: &instance.cancellables)
        
        instance.callStatePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { callState in
                instance.callState = callState
                instance.callStateEvent.success(state: callState)
            })
            .store(in: &instance.cancellables)
        
        CallManager.shared.$state
            .combineLatest(ControlChannel.shared.statePublisher, instance.$userAvailability)
            .receive(on: DispatchQueue.main)
            .sink { callManagerState, controlChannelState, userAvailability in
                
                // Disable call actions if the control channel state becomes disconnected.
                switch controlChannelState {
                case .disconnecting, .disconnected, .connecting:
                    instance.setDisableCallActions(true)
                    return
                case .connected:
                    break
                }
                
                // Disable call actions if the user is unavailable.
                guard userAvailability == .available else {
                    instance.setDisableCallActions(true)
                    return
                }
                
                // Disable call button when in a call with a user that is different from the user currently being viewed.
                switch callManagerState {
                case .connected(let user):
                    instance.updateActionsButtonsForConnectedUser(connectedUser: user)
                case .connecting(let user):
                    instance.updateActionsButtonsForConnectedUser(connectedUser: user)
                case .disconnected, .disconnecting:
                    instance.setDisableCallActions(false)
                }
            }
            .store(in: &instance.cancellables)
        
        instance.helpTextPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                text in
                instance.updateHelpText(text)
            }

    }
    
    var stateEvent = CallManagerStateEvent()
    var callRuleEvent = CallRuleEvent()
    var callStateEvent = CallManagerStateEvent()
    var cancellables = Set<AnyCancellable>()
    @Published var userAvailability: UserManager.UserAvailability = .available
    
    @Published var user: User? = nil
    @Published var callState = CallManager.State.disconnected
    
    func updateActionsButtonsForConnectedUser(connectedUser: User) {
        setDisableCallActions(connectedUser.id == user?.id)
    }
    
    private lazy var callManagerChannel =
    FlutterMethodChannel(name: "call_manager_channel", binaryMessenger: messenger)
    
    private func setDisableCallActions(_ value: Bool) {
        callManagerChannel.invokeMethod("updateActionsButtonsForConnectedUser", arguments: value)
    }
    
    private func updateHelpText(_ value: String) {
        callManagerChannel.invokeMethod("updateHelpText", arguments: value)
    }
    
    private lazy var helpTextPublisher = {
        $callState
            .combineLatest(ControlChannel.shared.statePublisher, CallManager.shared.callRolePublisher.replaceNil(with: .sender), $userAvailability)
            .map { callState, controlChannelState, callRole, userAvailability -> String in
                guard controlChannelState == .connected else {
                    return "Connecting to Server"
                }
                
                guard userAvailability == .available else {
                    return "User unavailable"
                }
                
                switch callState {
                case .disconnected:
                    return "Start call"
                case .connecting(let user):
                    switch callRole {
                    case .receiver:
                        return "Receiving call from \(user.deviceName)"
                    case .sender:
                        return "Calling \(user.deviceName)"
                    }
                case .connected(let user):
                    return "Connected with \(user.deviceName)"
                case .disconnecting(let reason) where reason == .unavailable:
                    return "User unavailable"
                case .disconnecting:
                    return "Hanging up"
                }
            }
            .removeDuplicates()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main) // Debounce changes that occur rapidly.
            .eraseToAnyPublisher()
    }()
    
    private lazy var callStatePublisher: AnyPublisher<CallManager.State, Never> = {
        CallManager.shared.$state
            .map { [weak self] state -> CallManager.State in
                var connectedUser: User?
                
                switch state {
                case .connected(let user):
                    connectedUser = user
                case .connecting(let user):
                    connectedUser = user
                case .disconnected, .disconnecting:
                    break
                }
                
                if let connectedUser = connectedUser, connectedUser.uuid != self?.user?.uuid {
                    return .disconnected
                }
                
                return state
            }
            .scan((nil, .disconnected), { cache, state -> (CallManager.State?, CallManager.State) in
                return (cache.1, state)
            })
            .combineLatest(CallManager.shared.callRolePublisher.dropNil())
            .map { callManagerState, callRole -> AnyPublisher<CallManager.State, Never> in
                let (tempPrevious, next) = callManagerState
                guard let previous = tempPrevious else {
                    return Just(next).eraseToAnyPublisher()
                }
                
                switch previous {
                case .disconnecting(let reason) where next == .disconnected:
                    guard reason != .hungUp && callRole == .sender else {
                        break
                    }
                    
                    // Delay transitioning the UI to the disconnected state so the user can see why the call disconnected.
                    let delayedDisconnectPublisher = Just(next)
                        .delay(for: .seconds(3), scheduler: DispatchQueue.main)
                        .eraseToAnyPublisher()
                    
                    return delayedDisconnectPublisher.eraseToAnyPublisher()
                default:
                    break
                }
                
                return Just(next).eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }()
}
