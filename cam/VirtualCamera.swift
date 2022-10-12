import CoreMediaIO

class VirtualCamera {
    let localizedName: String

    private let device: CMIOExtensionDevice
    private var stream: CMIOExtensionStream
    private let provider: CMIOExtensionProvider

    private let frameSource: FrameSource
    private let deviceSource: DeviceSource
    private let streamSource: StreamSource
    private let providerSource: ProviderSource

    init(
        localizedName: String,
        pipeline: String,
        dimensions: CMVideoDimensions,
        frameRate: Int32
    ) throws {
        let formatDescription = try Self.formatDescription(
            dimensions: dimensions
        )
        let streamFormat = Self.streamFormat(
            timeScale: CMTimeScale(frameRate),
            formatDescription: formatDescription
        )

        let frameSource = try FrameSource(
            formatDescription: formatDescription,
            pipeline: pipeline,
            dimensions: dimensions,
            frameRate: frameRate
        )
        let deviceSource = try DeviceSource(
            modelName: "Virtual Camera"
        )
        let streamSource = StreamSource(
            streamFormat: streamFormat,
            source: deviceSource
        )
        let providerSource = ProviderSource(
            manufacturerName: "Daily.co"
        )

//        frameSource.postProcess = { [weak self] bufferPtr, width, height, rowBytes in
//            self?.whiteStripes(bufferPtr: bufferPtr, width: width, height: height, rowBytes: rowBytes)
//        }

        let deviceID = UUID()
        let streamID = UUID()

        self.localizedName = localizedName

        self.stream = CMIOExtensionStream(
            localizedName: localizedName,
            streamID: streamID,
            direction: .source,
            clockType: .hostTime,
            source: streamSource
        )

        self.device = CMIOExtensionDevice(
            localizedName: localizedName,
            deviceID: deviceID,
            legacyDeviceID: nil,
            source: deviceSource
        )

        self.provider = CMIOExtensionProvider(
            source: providerSource,
            clientQueue: nil
        )

        self.frameSource = frameSource
        self.deviceSource = deviceSource
        self.streamSource = streamSource
        self.providerSource = providerSource

        try self.provider.addDevice(self.device)
        try self.device.addStream(self.stream)

        frameSource.delegate = self
        deviceSource.delegate = self
        streamSource.delegate = self
        providerSource.delegate = self
    }

    private static func streamFormat(
        timeScale: CMTimeScale,
        formatDescription: CMFormatDescription
    ) -> CMIOExtensionStreamFormat {
        CMIOExtensionStreamFormat(
            formatDescription: formatDescription,
            maxFrameDuration: CMTime(
                value: 1,
                timescale: timeScale
            ),
            minFrameDuration: CMTime(
                value: 1,
                timescale: timeScale
            ),
            validFrameDurations: nil
        )
    }

    private static func formatDescription(dimensions: CMVideoDimensions) throws -> CMFormatDescription {
        var formatDescriptionOrNil: CMFormatDescription? = nil

        let statusCode: OSStatus = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: dimensions.width,
            height: dimensions.height,
            extensions: nil,
            formatDescriptionOut: &formatDescriptionOrNil
        )

        guard statusCode == 0, let formatDescription = formatDescriptionOrNil else {
            throw VirtualCameraError.formatDescription(statusCode: statusCode)
        }

        return formatDescription
    }

    private func whiteStripes(bufferPtr: UnsafeMutableRawPointer, width: Int, height: Int, rowBytes: Int) {
        var bufferPtr = bufferPtr

        let whiteStripeHeight: Int = 50

        memset(bufferPtr, 0, rowBytes * height)

        var whiteStripeIsAscending = false
        var whiteStripeStartRow = 0

        if whiteStripeIsAscending {
            whiteStripeStartRow = whiteStripeStartRow - 1
            whiteStripeIsAscending = whiteStripeStartRow > 0
        } else {
            whiteStripeStartRow = whiteStripeStartRow + 1
            whiteStripeIsAscending = whiteStripeStartRow >= (height - whiteStripeHeight)
        }

        bufferPtr += rowBytes * Int(whiteStripeStartRow)

        for hi in 0..<whiteStripeHeight {
            for fun in 0..<width {
                var white: UInt32 = 0x3399CCFF - UInt32(fun * 2) - UInt32(hi)
                memcpy(bufferPtr, &white, MemoryLayout.size(ofValue: white))
                bufferPtr += MemoryLayout.size(ofValue: white)
            }
        }
    }

    func start() {
        CMIOExtensionProvider.startService(provider: self.provider)
    }
}

extension VirtualCamera: FrameSourceDelegate {
    func frameSource(
        _ source: FrameSource,
        didReceiveSampleBuffer sampleBuffer: CMSampleBuffer,
        withDiscontinuity discontinuity: CMIOExtensionStream.DiscontinuityFlags,
        hostTimeInNanoseconds: UInt64
    ) {
        self.stream.send(
            sampleBuffer,
            discontinuity: discontinuity,
            hostTimeInNanoseconds: hostTimeInNanoseconds
        )
    }
}

extension VirtualCamera: DeviceSourceDelegate {
    // nothing yet
}

extension VirtualCamera: StreamSourceDelegate {
    func streamSource(
        _ source: StreamSource,
        didSetStreamProperties streamProperties: CMIOExtensionStreamProperties
    ) {
        if let activeFormatIndex = streamProperties.activeFormatIndex {
            logger.debug("activeFormatIndex: \(activeFormatIndex)")
        }
    }

    func streamSourceShouldAuthorizeStartOfStream(_ source: StreamSource) -> Bool {
        true
    }

    func streamSourceDidStartStream(_ source: StreamSource) {
        self.frameSource.startStreaming()
    }

    func streamSourceDidStopStream(_ source: StreamSource) {
        self.frameSource.stopStreaming()
    }
}

extension VirtualCamera: ProviderSourceDelegate {
    // nothing yet
}
