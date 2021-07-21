//
//  MCheynePlanApp.swift
//  Shared
//
//  Created by Will Walker on 7/19/21.
//

import SwiftUI

@main
struct MCheynePlanApp: App {
    
    @StateObject var model = Model(Date())
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
