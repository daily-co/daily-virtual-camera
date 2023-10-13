import Foundation
import CoreMediaIO

import Logging

let logger = Logger(label: "co.daily.DailyVirtualCamera")

let userDefaults = UserDefaults.standard

let width = userDefaults.videoWidth
let height = userDefaults.videoHeight
let frameRate = userDefaults.videoFramerate
let pipeline = userDefaults.gStreamerPipeline

let dimensions = CMVideoDimensions(width: width, height: height)

let virtualCamera: VirtualCamera
do {
    virtualCamera = try .init(
        localizedName: "Daily Virtual Camera",
        pipeline: pipeline,
        dimensions: dimensions,
        frameRate: frameRate
    )
} catch let error {
    logger.error("\(error)")
    exit(1)
}

virtualCamera.start()

CFRunLoopRun()
