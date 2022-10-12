import Foundation
import CoreVideo

enum VirtualCameraError: Swift.Error {
    case settings(error: DecodingError)
    case formatDescription(statusCode: OSStatus)
    case pixelBuffer(statusCode: OSStatus)
    case pixelBufferPool(returnCode: CVReturn)
    case sampleBuffer(statusCode: OSStatus)

    var localizedDescription: String {
        switch self {
        case .settings(let error):
            return "Failed to read settings (error: \(error)."
        case .formatDescription(let statusCode):
            return "Failed to create video format description (status code: \(statusCode)."
        case .pixelBuffer(let statusCode):
            return "Failed to create pixel buffer (status code: \(statusCode)."
        case .pixelBufferPool(let returnCode):
            return "Failed to create pixel buffer pool (return code: \(returnCode)."
        case .sampleBuffer(let statusCode):
            return "Failed to create sample buffer (status code: \(statusCode)."
        }
    }
}
