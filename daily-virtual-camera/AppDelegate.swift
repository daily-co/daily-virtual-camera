//
//  AppDelegate.swift
//  daily-virtual-camera
//
//  Created by vanessa pyne on 9/8/22.
//

import Cocoa

import Logging

let logger = Logger(label: "co.daily.DailyVirtualCamera")

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
