import Foundation

extension UserDefaults {
    enum VirtualCameraKeys {
        static let videoWidth: String = "videoWidth"
        static let videoHeight: String = "videoHeight"
        static let videoFramerate: String = "videoFramerate"
        static let gStreamerPipeline: String = "gStreamerPipeline"
    }

    enum VirtualCameraDefaults {
        static let videoWidth: Int32 = 1280
        static let videoHeight: Int32 = 720
        static let videoFramerate: Int32 = 30
        static let gStreamerPipeline: String = "videotestsrc pattern=ball ! capsfilter caps=video/x-raw,width=1280,height=720"
    }
    var videoWidth: Int32 {
        get {
            if let value = self.value(forKey: VirtualCameraKeys.videoWidth) {
                return value as! Int32
            }
            self.set(VirtualCameraDefaults.videoWidth, forKey: VirtualCameraKeys.videoWidth)
            return VirtualCameraDefaults.videoWidth
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.videoWidth)
        }
    }

    var videoHeight: Int32 {
        get {
            if let value = self.value(forKey: VirtualCameraKeys.videoHeight) {
                return value as! Int32
            }
            self.set(VirtualCameraDefaults.videoHeight, forKey: VirtualCameraKeys.videoHeight)
            return VirtualCameraDefaults.videoHeight
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.videoHeight)
        }
    }

    var videoFramerate: Int32 {
        get {
            if let value = self.value(forKey: VirtualCameraKeys.videoFramerate) {
                return value as! Int32
            }
            self.set(VirtualCameraDefaults.videoFramerate, forKey: VirtualCameraKeys.videoFramerate)
            return VirtualCameraDefaults.videoFramerate
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.videoFramerate)
        }
    }

    var gStreamerPipeline: String {
        get {
            if let value = self.value(forKey: VirtualCameraKeys.gStreamerPipeline) {
                return value as! String
            }
            self.set(VirtualCameraDefaults.gStreamerPipeline, forKey: VirtualCameraKeys.gStreamerPipeline)
            return VirtualCameraDefaults.gStreamerPipeline
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.gStreamerPipeline)
        }
    }
}
