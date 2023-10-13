import CoreMediaIO

protocol ProviderSourceDelegate: AnyObject {
    // nothing yet
}

class ProviderSource: NSObject {
    let manufacturerName: String

    weak var delegate: ProviderSourceDelegate? = nil

    init(manufacturerName: String) {
        self.manufacturerName = manufacturerName
    }
}

extension ProviderSource: CMIOExtensionProviderSource {
    func connect(to client: CMIOExtensionClient) throws {
        // Handle client connect
    }

    func disconnect(from client: CMIOExtensionClient) {
        // Handle client disconnect
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        // See full list of CMIOExtensionProperty choices in CMIOExtensionProperties.h
        return [.providerManufacturer]
    }

    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = self.manufacturerName
        }
        return providerProperties
    }

    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        // Handle settable properties here.
    }
}
