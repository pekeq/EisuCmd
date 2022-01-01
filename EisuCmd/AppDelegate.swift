//
//  AppDelegate.swift
//  EisuCmd
//
//  Created by hideo-m on 2021/12/31.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var statusMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        showStatusBar()

        waitForTrusted(callback: {
            print("Got permission")
            if let m = self.statusMenuItem {
                m.title = "Running"
                m.action = nil
            }
            let tap = KeyEventTap()
            tap.listen()
            
            // TODO: start timer for checking permission
        })
    }

    func showStatusBar() {
        if let button = statusItem.button {
            button.title = "英⌘"

            let mi = NSMenuItem(title: "Waiting for permission...", action: #selector(AppDelegate.showTrustDialogWhenUntrusted(_:)), keyEquivalent: "")
            statusMenuItem = mi

            let menu = NSMenu()
            menu.addItem(mi)
            menu.addItem(NSMenuItem(title: "About", action: #selector(AppDelegate.showAboutDialog(_:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem.menu = menu
        }
    }
    
    @objc func showTrustDialogWhenUntrusted(_ sender: NSMenuItem) {
        _ = isProcessTrustedWithDialog()
    }
    
    @objc func showAboutDialog(_ sender: NSMenuItem) {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String

        let alert = NSAlert()
        alert.messageText = "英数⌘"
        alert.informativeText = "Version \(version) (Build \(build))\n\ngithub.com/pekeq/EisuCmd\n© Hideo Matsumoto"
        alert.alertStyle = NSAlert.Style.informational
        alert.runModal()
    }
    
    func isProcessTrustedWithDialog() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        return AXIsProcessTrustedWithOptions(options)
    }

    func waitForTrusted(callback: @escaping () -> Void) {
        if isProcessTrustedWithDialog() {
            callback()
            return
        }

        print("Waiting for permission...")

        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true, block: { (timer: Timer) in
            if AXIsProcessTrusted() {
                timer.invalidate()
                callback()
                return
            }
            print("Still waiting...")
        })
    }
}
