//
//  main.swift
//  cam
//
//  Created by vanessa pyne on 9/8/22.
//

import Foundation
import CoreMediaIO

let providerSource = camProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
