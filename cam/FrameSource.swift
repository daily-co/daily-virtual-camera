import CoreMediaIO

protocol FrameSourceDelegate: AnyObject {
    func frameSource(
        _ source: FrameSource,
        didReceiveSampleBuffer sampleBuffer: CMSampleBuffer,
        withDiscontinuity discontinuity: CMIOExtensionStream.DiscontinuityFlags,
        hostTimeInNanoseconds: UInt64
    )
}

class FrameSource {
    typealias PostProcess = (UnsafeMutableRawPointer, Int, Int, Int) -> ()

    let formatDescription: CMFormatDescription

    var postProcess: PostProcess? = nil

    weak var delegate: FrameSourceDelegate? = nil

    private var bufferPool: CVPixelBufferPool
    private let backend: GStreamerBackend
    private let timerInterval: TimeInterval
    private var timer: DispatchSourceTimer? = nil
    private let queue: DispatchQueue = .init(
        label: "timerQueue",
        qos: .userInteractive,
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global(qos: .userInteractive)
    )

    init(
        formatDescription: CMFormatDescription,
        pipeline: String,
        dimensions: CMVideoDimensions,
        frameRate: Int32
    ) throws {
        self.formatDescription = formatDescription
        self.backend = GStreamerBackend(
            pipeline: pipeline,
            width: dimensions.width,
            height: dimensions.height,
            frameRate: frameRate
        )
        self.bufferPool = try Self.pixelBufferPool(
            formatDescription: formatDescription,
            width: dimensions.width,
            height: dimensions.height
        )

        self.timerInterval = 1.0 / TimeInterval(frameRate)
    }

    private static func pixelBufferPool(
        formatDescription: CMFormatDescription,
        width: Int32,
        height: Int32
    ) throws -> CVPixelBufferPool {
        let pixelBufferAttributes: NSDictionary = [
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferPixelFormatTypeKey: formatDescription.mediaSubType,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]

        var pixelBufferPoolOrNil: CVPixelBufferPool?
        let returnCode = CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            nil,
            pixelBufferAttributes,
            &pixelBufferPoolOrNil
        )
        guard returnCode == kCVReturnSuccess, let pixelBufferPool = pixelBufferPoolOrNil else {
            throw VirtualCameraError.pixelBufferPool(returnCode: returnCode)
        }
        return pixelBufferPool
    }

    private func pixelBuffer() throws -> CVPixelBuffer {
        var pixelBufferOrNil: CVPixelBuffer?

        let bufferAuxAttributes: NSDictionary = [
            kCVPixelBufferPoolAllocationThresholdKey: 5
        ]

        var statusCode: OSStatus = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
            kCFAllocatorDefault,
            self.bufferPool,
            bufferAuxAttributes,
            &pixelBufferOrNil
        )

        guard statusCode == 0, let pixelBuffer = pixelBufferOrNil else {
            throw VirtualCameraError.pixelBuffer(statusCode: statusCode)
        }

        return pixelBuffer
    }

    private func sampleBuffer(pixelBuffer: CVPixelBuffer, timingInfo: inout CMSampleTimingInfo) throws -> CMSampleBuffer {
        var sampleBufferOrNil: CMSampleBuffer?

        let statusCode: OSStatus = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: self.formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBufferOrNil
        )

        guard statusCode == 0, let sampleBuffer = sampleBufferOrNil else {
            throw VirtualCameraError.sampleBuffer(statusCode: statusCode)
        }

        return sampleBuffer
    }

    func nextSampleBuffer() throws -> CMSampleBuffer {
        let now = CMClockGetTime(CMClockGetHostTimeClock())

        let pixelBuffer = try self.pixelBuffer()

        CVPixelBufferLockBaseAddress(pixelBuffer, [])

        var bufferPtr = CVPixelBufferGetBaseAddress(pixelBuffer)!

        autoreleasepool {
            if let data = self.backend.nextFrameBuffer() {
                let _ = data.withUnsafeBytes { bytes in
                    memcpy(bufferPtr, bytes.baseAddress, data.count)
                }
            }

            if let postProcess = self.postProcess {
                let width = CVPixelBufferGetWidth(pixelBuffer)
                let height = CVPixelBufferGetHeight(pixelBuffer)
                let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)

                postProcess(bufferPtr, width, height, rowBytes)
            }
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())

        let sampleBuffer = try self.sampleBuffer(
            pixelBuffer: pixelBuffer,
            timingInfo: &timingInfo
        )

        return sampleBuffer
    }

    func startStreaming() {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: self.queue)

        let secondsPerFrame = self.timerInterval
        let millisecondsPerFrame = secondsPerFrame * 1000.0
        let interval = DispatchTimeInterval.milliseconds(Int(millisecondsPerFrame))

        timer.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }

            let sampleBuffer: CMSampleBuffer
            do {
                sampleBuffer = try self.nextSampleBuffer()
            } catch let error {
                logger.error("\(error.localizedDescription)")
                return
            }

            var timingInfo = CMSampleTimingInfo()
            timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())

            let discontinuity: CMIOExtensionStream.DiscontinuityFlags = []
            let nanoseconds = UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))

            self.delegate?.frameSource(
                self,
                didReceiveSampleBuffer: sampleBuffer,
                withDiscontinuity: discontinuity,
                hostTimeInNanoseconds: nanoseconds
            )
        }

        timer.setCancelHandler {
            // do nothing, for now.
        }

        timer.schedule(
            deadline: .now(),
            repeating: interval,
            leeway: .seconds(0)
        )

        timer.resume()

        self.timer = timer
    }

    func stopStreaming() {
        self.timer?.cancel()
        self.timer = nil
    }
}
