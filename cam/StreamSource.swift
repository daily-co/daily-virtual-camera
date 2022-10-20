import CoreMediaIO

protocol StreamSourceDelegate: AnyObject {
    func streamSource(
        _ source: StreamSource,
        didSetStreamProperties streamProperties: CMIOExtensionStreamProperties
    )
    func streamSourceShouldAuthorizeStartOfStream(_ source: StreamSource) -> Bool
    func streamSourceDidStartStream(_ source: StreamSource)
    func streamSourceDidStopStream(_ source: StreamSource)
}

class StreamSource: NSObject {
    private let source: CMIOExtensionDeviceSource
    private let streamFormat: CMIOExtensionStreamFormat
    private var activeFormatIndex: Int = 0

    weak var delegate: StreamSourceDelegate? = nil

    init(
        streamFormat: CMIOExtensionStreamFormat,
        source: CMIOExtensionDeviceSource
    ) {
        self.streamFormat = streamFormat
        self.source = source
    }
}

extension StreamSource: CMIOExtensionStreamSource {
    var formats: [CMIOExtensionStreamFormat] {
        [self.streamFormat]
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        return [.streamActiveFormatIndex, .streamFrameDuration]
    }

    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])

        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) {
            streamProperties.frameDuration = self.streamFormat.maxFrameDuration
        }

        return streamProperties
    }

    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        self.delegate?.streamSource(self, didSetStreamProperties: streamProperties)
    }

    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        self.delegate?.streamSourceShouldAuthorizeStartOfStream(self) ?? true
    }

    func startStream() throws {
        self.delegate?.streamSourceDidStartStream(self)
    }

    func stopStream() throws {
        self.delegate?.streamSourceDidStopStream(self)
    }
}
