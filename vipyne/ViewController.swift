//
//  ViewController.swift
//  vipyne
//
//  Created by vanessa pyne on 9/8/22.
//

import Cocoa
import SystemExtensions

class ViewController: NSViewController {
    @IBOutlet var infoLog: NSTextField!

    @IBAction func startCameraExtension(_ sender: Any) {
        guard let identifier = ViewController._extensionBundle().bundleIdentifier else {
            return
        }
        print("identifier \(identifier)")
        infoLog.stringValue = "identifier \(identifier) \n"
        
        let activationRequest =     OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier:  identifier, queue: .main);
        activationRequest.delegate = self;
        OSSystemExtensionManager.shared.submitRequest(activationRequest);
    }
    
    @IBAction func stopCameraExtension(_ sender: Any) {
        guard let identifier = ViewController._extensionBundle().bundleIdentifier else {
            return
        }
        print("identifier \(identifier)")
        infoLog.stringValue = "identifier \(identifier) \n"

        let deactivationRequest =     OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier:  identifier, queue: .main);
        deactivationRequest.delegate = self;
        OSSystemExtensionManager.shared.submitRequest(deactivationRequest);
    }
    
    private class func _extensionBundle() -> Bundle {
        let extensionsDirectoryURL = URL(fileURLWithPath: "Contents/Library/SystemExtensions", relativeTo: Bundle.main.bundleURL)
        let extensionURLs: [URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(at: extensionsDirectoryURL,
                                                                        includingPropertiesForKeys: nil,
                                                                        options: .skipsHiddenFiles)
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
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        infoLog.stringValue = infoLog.stringValue + "\n request"
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("requestNeedsUserApproval")
        infoLog.stringValue = infoLog.stringValue + "\n requestNeedsUserApproval"
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        print("request overloaded - result) \(result.rawValue)")
        infoLog.stringValue = infoLog.stringValue + "\n request overloaded - result \(result.rawValue)"
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        print("request overloaded - ERROR \(error)")
        infoLog.stringValue = infoLog.stringValue + "\n request overloaded - ERROR \(error)"
    }
}
