//
//  huhTrayApp.swift
//  huhTray
//
//  Created by Neo Werling on 08.09.26.
//

import SwiftUI

@main
struct huhTrayApp: App {
    @State private var engine = SoundEngine()

    var body: some Scene {
        MenuBarExtra("huhTray", systemImage: "die.face.5") {
            ContentView(engine: engine)
        }
        .menuBarExtraStyle(.window)
    }
}
