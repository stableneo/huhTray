//
//  huhTrayApp.swift
//  huhTray
//
//  Created by Neo Werling on 08.09.26.
//

import SwiftUI
import AppKit

@main
struct huhTrayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

/// Manages the menu-bar status item and its popover, and owns the audio engine.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = SoundEngine()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(engine: engine))

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "die.face.5", accessibilityDescription: "huhTray")
            button.toolTip = "Left-click for controls · Right-click to play"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = statusItem
    }

    /// Left-click toggles the controls popover; right-click plays the sound instantly.
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            engine.play()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
