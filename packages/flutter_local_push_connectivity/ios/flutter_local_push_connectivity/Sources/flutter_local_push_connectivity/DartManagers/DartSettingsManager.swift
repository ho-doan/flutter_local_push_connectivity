import Combine
import Flutter
import HDPushKit

class SettingsEvent: OnChangedStreamHandler {
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
    
    func success(_ state: Settings){
        let pushManagerSettings = PushManagerSettingsPigeon(ssid: state.pushManagerSettings.ssid, mobileCountryCode: state.pushManagerSettings.mobileCountryCode, mobileNetworkCode: state.pushManagerSettings.mobileNetworkCode, trackingAreaCode: state.pushManagerSettings.trackingAreaCode, host: state.pushManagerSettings.host, matchEthernet: state.pushManagerSettings.matchEthernet)
        let settings = SettingsPigeon(uuid: state.uuid.uuidString, deviceName: state.deviceName, pushManagerSettings: pushManagerSettings)
        
        eventSink?.success(settings)
    }
    
    func error(err: String, message: String? = nil){
        eventSink?.error(code: "ERROR", message: err, details: message)
    }
}


class SettingsManagerImlp: NSObject, FlutterPlugin, SettingsManagerHostApi {
    static func register(with registrar: any FlutterPluginRegistrar) {
        let instance = SettingsManagerImlp()
        SettingsManagerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance, messageChannelSuffix: "settings_manager")
        
        OnChangedStreamHandler.register(with: registrar.messenger(), instanceName: "settings_manager_settings", streamHandler: instance.settingsEvent)
        
        SettingsManager.shared.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                settings in
                instance.settingsEvent.success(settings)
            }
            .store(in: &instance.cancellables)
    }
    
    var settingsEvent = SettingsEvent()
    var cancellables = Set<AnyCancellable>()
}
