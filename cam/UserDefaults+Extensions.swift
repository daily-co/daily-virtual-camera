import Foundation

extension UserDefaults {
    enum VirtualCameraKeys {
        static let videoWidth: String = "videoWidth"
        static let videoHeight: String = "videoHeight"
        static let videoFramerate: String = "videoFramerate"
        static let gStreamerPipeline: String = "gStreamerPipeline"
    }

    var videoWidth: Int32 {
        get {
            self.value(forKey: VirtualCameraKeys.videoWidth) as! Int32
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.videoWidth)
        }
    }

    var videoHeight: Int32 {
        get {
            self.value(forKey: VirtualCameraKeys.videoHeight) as! Int32
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.videoHeight)
        }
    }

    var videoFramerate: Int32 {
        get {
            self.value(forKey: VirtualCameraKeys.videoFramerate) as! Int32
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.videoFramerate)
        }
    }

    var gStreamerPipeline: String {
        get {
            self.value(forKey: VirtualCameraKeys.gStreamerPipeline) as! String
        }
        set {
            self.set(newValue, forKey: VirtualCameraKeys.gStreamerPipeline)
        }
    }
}
