/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary conduit through which the app communicates with the server's control channel.
*/

import Foundation
import Combine
import HDPushKit

class ControlChannel: BaseChannel {
    static let shared = ControlChannel()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Port.control = 5060
        super.init(port: 5060, heartbeatTimeout: .seconds(20), logger: Logger(prependString: "Control Channel", subsystem: .networking))
        
        SettingsManager.shared.settingsPublisher
        .sink { [self] settings in
            setHost(settings.pushManagerSettings.host)
        }
        .store(in: &cancellables)
    }
}
