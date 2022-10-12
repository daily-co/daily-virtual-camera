//
//  ViewController.swift
//  daily-virtual-camera
//
//  Created by vanessa pyne on 9/8/22.
//

import Cocoa
import SystemExtensions

class ViewController: NSViewController {
    @IBOutlet var infoLogField: NSTextField!

    var logs: [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.infoLogField.stringValue = self.logs.joined(separator: "\n")
            }
        }
    }

    @IBAction func startCameraExtension(_ sender: Any) {
        guard let identifier = Self.extensionBundle().bundleIdentifier else {
            return
        }

        let logString = "identifier \(identifier)"
        logger.info("\(logString)")
        self.logs.append(logString)

        let activationRequest = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier:  identifier,
            queue: .main
        )
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }
    
    @IBAction func stopCameraExtension(_ sender: Any) {
        guard let identifier = Self.extensionBundle().bundleIdentifier else {
            return
        }

        let logString = "identifier \(identifier)"
        logger.info("\(logString)")
        self.logs.append(logString)

        let deactivationRequest = OSSystemExtensionRequest.deactivationRequest(
            forExtensionWithIdentifier: identifier,
            queue: .main
        )
        deactivationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(deactivationRequest)
    }
    
    private class func extensionBundle() -> Bundle {
        let extensionsDirectoryURL = URL(
            fileURLWithPath: "Contents/Library/SystemExtensions",
            relativeTo: Bundle.main.bundleURL
        )

        let extensionURLs: [URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(
                at: extensionsDirectoryURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
        } catch let error {
            fatalError("fatal 1 \(error)")
        }

        guard let extensionURL = extensionURLs.first else {
            fatalError("fatal 2")
        }
        
        guard let extensionBundle = Bundle(url: extensionURL) else {
            fatalError("fatal 3 \(extensionURL.absoluteString)")
        }

        return extensionBundle
    }
}

extension ViewController: OSSystemExtensionRequestDelegate {
    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        let logString = "\(#function): (request: \(request.identifier))"
        logger.trace("\(logString)")
        self.logs.append(logString)

        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        let logString = "\(#function): (request: \(request.identifier))"
        logger.trace("\(logString)")
        self.logs.append(logString)
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        let logString = "\(#function): (request: \(request.identifier), result: \(result.rawValue))"
        logger.trace("\(logString)")
        self.logs.append(logString)
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        let logString = "\(#function): (request: \(request.identifier), error: \(error))"
        logger.trace("\(logString)")
        self.logs.append(logString)
    }
}
