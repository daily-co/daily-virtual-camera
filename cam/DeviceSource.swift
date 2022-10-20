import CoreMediaIO
import IOKit.audio

protocol DeviceSourceDelegate: AnyObject {
    // nothing yet
}

class DeviceSource: NSObject {
    let modelName: String

    weak var delegate: DeviceSourceDelegate? = nil

	init(modelName: String) throws {
        self.modelName = modelName
	}
}

extension DeviceSource: CMIOExtensionDeviceSource {
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.deviceTransportType, .deviceModel]
    }

    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])

        if properties.contains(.deviceTransportType) {
            deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
        }
        if properties.contains(.deviceModel) {
            deviceProperties.model = self.modelName
        }

        return deviceProperties
    }

    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // Handle settable properties here.
    }
}
