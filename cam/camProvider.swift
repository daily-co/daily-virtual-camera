//
//  camProvider.swift
//  cam
//
//  Created by vanessa pyne on 9/8/22.
//

import Foundation
import CoreMediaIO
import IOKit.audio
import os.log

let kWhiteStripeHeight: Int = 50
let kFrameRate: Int = 60
let myCameraName = "Daily Camera"

// MARK: -

class camDeviceSource: NSObject, CMIOExtensionDeviceSource {
	
	private(set) var device: CMIOExtensionDevice!
	
	private var _streamSource: camStreamSource!
	
	private var _streamingCounter: UInt32 = 0
	
	private var _timer: DispatchSourceTimer?
	
	private let _timerQueue = DispatchQueue(label: "timerQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: .global(qos: .userInteractive))
	
	private var _videoDescription: CMFormatDescription!
	
	private var _bufferPool: CVPixelBufferPool!
	
	private var _bufferAuxAttributes: NSDictionary!
	
	private var _whiteStripeStartRow: UInt32 = 0
	
	private var _whiteStripeIsAscending: Bool = false

	private var _gstBackend: GStreamerBackend!

	private var _settings: [String: Any]!

	private var _width: Int32 = 1280

	private var _height: Int32 = 720

	private var _frameRate: Int32 = 30

	init(localizedName: String) {
		
		super.init()

		do {
			self._settings = try self.loadSettings()!;

			let pipeline = self._settings["pipeline"] as? String
			self._width = self._settings["width"] as! Int32
			self._height = self._settings["height"] as! Int32
			self._frameRate = self._settings["frameRate"] as! Int32

			self._gstBackend = GStreamerBackend.init(pipeline: pipeline, width: self._width, height: self._height, frameRate: self._frameRate)
		} catch let error {
			fatalError("Failed to load settings: \(error.localizedDescription)")
		}


		let deviceID = UUID() // replace this with your device UUID
		self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
		
		let dims = CMVideoDimensions(width: self._width, height: self._height)
		CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType: kCVPixelFormatType_32BGRA, width: dims.width, height: dims.height, extensions: nil, formatDescriptionOut: &_videoDescription)
		
		let pixelBufferAttributes: NSDictionary = [
			kCVPixelBufferWidthKey: dims.width,
			kCVPixelBufferHeightKey: dims.height,
			kCVPixelBufferPixelFormatTypeKey: _videoDescription.mediaSubType,
			kCVPixelBufferIOSurfacePropertiesKey: [:]
		]
		CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &_bufferPool)
		
		let videoStreamFormat = CMIOExtensionStreamFormat.init(formatDescription: _videoDescription, maxFrameDuration: CMTime(value: 1, timescale: self._frameRate), minFrameDuration: CMTime(value: 1, timescale: self._frameRate), validFrameDurations: nil)
		_bufferAuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey: 5]
		
		let videoID = UUID() // replace this with your video UUID
		_streamSource = camStreamSource(localizedName: "\(myCameraName).Video", streamID: videoID, streamFormat: videoStreamFormat, device: device)
		do {
			try device.addStream(_streamSource.stream)
		} catch let error {
			fatalError("Failed to add stream: \(error.localizedDescription)")
		}
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.deviceTransportType, .deviceModel]
	}

	func loadSettings() throws -> [String: Any]? {
		let settingsPath = Bundle.main.path(forResource: "vipyne", ofType: "json")!
		let data = FileManager.default.contents(atPath: settingsPath)!
		let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
		return jsonObject as? [String: Any]
	}

	func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
		
		let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
		if properties.contains(.deviceTransportType) {
			deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
		}
		if properties.contains(.deviceModel) {
			deviceProperties.model = "\(myCameraName) Model"
		}
		
		return deviceProperties
	}
	
	func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
		
		// Handle settable properties here.
	}
	
	func startStreaming() {
		
		guard let _ = _bufferPool else {
			return
		}
		
		_streamingCounter += 1
		
		_timer = DispatchSource.makeTimerSource(flags: .strict, queue: _timerQueue)
			_timer!.schedule(deadline: .now(), repeating: Double(1/self._frameRate), leeway: .seconds(0))
		
		_timer!.setEventHandler {
			
			var err: OSStatus = 0
			let now = CMClockGetTime(CMClockGetHostTimeClock())
			
			var pixelBuffer: CVPixelBuffer?
			err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, self._bufferPool, self._bufferAuxAttributes, &pixelBuffer)
			if err != 0 {
				os_log(.error, "out of pixel buffers \(err)")
			}
			
			if let pixelBuffer = pixelBuffer {
				
				CVPixelBufferLockBaseAddress(pixelBuffer, [])
				
				var bufferPtr = CVPixelBufferGetBaseAddress(pixelBuffer)!
				
				autoreleasepool(invoking: {
					let data = self._gstBackend.nextFrameBuffer()
					if data != nil {
						data!.withUnsafeBytes({
							let unsafeBufferPtr = $0.bindMemory(to: UInt8.self)
							memcpy(bufferPtr, unsafeBufferPtr.baseAddress, data!.count)
						})
					}
				})

//				let width = CVPixelBufferGetWidth(pixelBuffer)
//				let height = CVPixelBufferGetHeight(pixelBuffer)
//				let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
//				memset(bufferPtr, 0, rowBytes * height)
//
//				let whiteStripeStartRow = self._whiteStripeStartRow
//				if self._whiteStripeIsAscending {
//					self._whiteStripeStartRow = whiteStripeStartRow - 1
//					self._whiteStripeIsAscending = self._whiteStripeStartRow > 0
//				}
//				else {
//					self._whiteStripeStartRow = whiteStripeStartRow + 1
//					self._whiteStripeIsAscending = self._whiteStripeStartRow >= (height - kWhiteStripeHeight)
//				}
//				bufferPtr += rowBytes * Int(whiteStripeStartRow)
//				for hi in 0..<kWhiteStripeHeight {
//					for fun in 0..<width {
//						var white: UInt32 = 0x3399CCFF - UInt32(fun * 2) - UInt32(hi)
//						memcpy(bufferPtr, &white, MemoryLayout.size(ofValue: white))
//						bufferPtr += MemoryLayout.size(ofValue: white)
//					}
//				}
//
				CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
				
				var sbuf: CMSampleBuffer!
				var timingInfo = CMSampleTimingInfo()
				timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
				err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: self._videoDescription, sampleTiming: &timingInfo, sampleBufferOut: &sbuf)
				if err == 0 {
					self._streamSource.stream.send(sbuf, discontinuity: [], hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
				}
				os_log(.info, "video time \(timingInfo.presentationTimeStamp.seconds) now \(now.seconds) err \(err)")
			}
		}
		
		_timer!.setCancelHandler {
		}
		
		_timer!.resume()
	}
	
	func stopStreaming() {
		
		if _streamingCounter > 1 {
			_streamingCounter -= 1
		}
		else {
			_streamingCounter = 0
			if let timer = _timer {
				timer.cancel()
				_timer = nil
			}
		}
	}
}

// MARK: -

class camStreamSource: NSObject, CMIOExtensionStreamSource {
	
	private(set) var stream: CMIOExtensionStream!
	
	let device: CMIOExtensionDevice
	
	private let _streamFormat: CMIOExtensionStreamFormat
	
	init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {
		
		self.device = device
		self._streamFormat = streamFormat
		super.init()
		self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: self)
	}
	
	var formats: [CMIOExtensionStreamFormat] {
		
		return [_streamFormat]
	}
	
	var activeFormatIndex: Int = 0 {
		
		didSet {
			if activeFormatIndex >= 1 {
				os_log(.error, "Invalid index")
			}
		}
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
			streamProperties.frameDuration = self._streamFormat.maxFrameDuration
		}
		
		return streamProperties
	}
	
	func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
		
		if let activeFormatIndex = streamProperties.activeFormatIndex {
			self.activeFormatIndex = activeFormatIndex
		}
	}
	
	func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
		
		// An opportunity to inspect the client info and decide if it should be allowed to start the stream.
		return true
	}
	
	func startStream() throws {
		
		guard let deviceSource = device.source as? camDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.startStreaming()
	}
	
	func stopStream() throws {
		
		guard let deviceSource = device.source as? camDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.stopStreaming()
	}
}

// MARK: -

class camProviderSource: NSObject, CMIOExtensionProviderSource {
	
	private(set) var provider: CMIOExtensionProvider!
	
	private var deviceSource: camDeviceSource!
	
	// CMIOExtensionProviderSource protocol methods (all are required)
	
	init(clientQueue: DispatchQueue?) {
		
		super.init()
		
		provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
		deviceSource = camDeviceSource(localizedName: "\(myCameraName) (daily.co)")
		
		do {
			try provider.addDevice(deviceSource.device)
		} catch let error {
			fatalError("Failed to add device: \(error.localizedDescription)")
		}
	}
	
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
			providerProperties.manufacturer = "\(myCameraName) Manufacturer"
		}
		return providerProperties
	}
	
	func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
		
		// Handle settable properties here.
	}
}
