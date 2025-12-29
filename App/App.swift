//
//  App.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 12/29/25.
//

import SwiftUI

@main
struct MCheynePlanApp: App {
    // Create a shared instance of the Plan model to be used throughout the app
    @StateObject var planModel = Plan()
    
    var body: some Scene {
        WindowGroup {
            // Set the ContentView as the main view and pass the Plan model as an environment object
            ContentView()
                .environmentObject(planModel)
            
            // Set a fixed frame size for macOS only
            #if os(macOS)
                .frame(minWidth: 400, maxWidth: 400, minHeight: 500, maxHeight: 500)
            #endif
        }
    }
}
