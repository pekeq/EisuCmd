//
//  EisuCmdApp.swift
//  EisuCmd
//
//  Created by hideo-m on 2022/01/01.
//

import AppKit
import SwiftUI

@main
struct EisuCmdApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
