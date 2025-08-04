import Flutter
import Combine
import HDPushKit

class MessageEvent: OnChangedStreamHandler {
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
    
    func success(_ state: TextMessage){
        let messageString = state.message
        let sender = UserPigeon(uuid: state.routing.sender.id.uuidString, deviceName: state.routing.sender.deviceName)
        let receiver = UserPigeon(uuid: state.routing.receiver.id.uuidString, deviceName: state.routing.receiver.deviceName)
        let message = TextMessagePigeon(sender: sender, receiver: receiver, message: messageString)
        
        eventSink?.success(message)
    }
    
    func error(err: String, message: String? = nil){
        eventSink?.error(code: "ERROR", message: err, details: message)
    }
}

class MessagingManagerImlp: NSObject, FlutterPlugin, MessagingManagerHostApi {
    static func register(with registrar: any FlutterPluginRegistrar) {
        let instance = MessagingManagerImlp()
        MessagingManagerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance, messageChannelSuffix: "messaging_manager")
        
        OnChangedStreamHandler.register(with: registrar.messenger(), instanceName: "messaging_manager_message_publisher", streamHandler: instance.messageEvent)
        
        MessagingManager.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink {
                message in
                instance.messageEvent.success(message)
            }
            .store(in: &instance.cancellables)
    }
    
    var messageEvent = MessageEvent()
    var cancellables = Set<AnyCancellable>()
}
