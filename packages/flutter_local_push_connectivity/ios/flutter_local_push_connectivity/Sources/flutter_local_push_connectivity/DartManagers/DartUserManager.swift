import Combine
import Flutter
import HDPushKit

class UsersEvent: OnChangedStreamHandler {
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
    
    func success(_ state: [User]){
        let users: [UserPigeon] = state.map {
            UserPigeon(uuid: $0.id.uuidString, deviceName: $0.deviceName)
        }
                
        eventSink?.success(users)
    }
    
    func error(err: String, message: String? = nil){
        eventSink?.error(code: "ERROR", message: err, details: message)
    }
}


class UserManagerImlp: NSObject, FlutterPlugin, UserManagerHostApi {
    static func register(with registrar: any FlutterPluginRegistrar) {
        let instance = UserManagerImlp()
        UserManagerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance, messageChannelSuffix: "user_manager")
        
        OnChangedStreamHandler.register(with: registrar.messenger(), instanceName: "user_manager_users", streamHandler: instance.usersEvent)
        
        UserManager.shared.usersPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                users in
                instance.usersEvent.success(users)
            }
            .store(in: &instance.cancellables)
    }
    
    var usersEvent = UsersEvent()
    var cancellables = Set<AnyCancellable>()
}
