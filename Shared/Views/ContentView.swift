//
//  ContentView.swift
//  Shared
//
//  Created by Will Walker on 7/19/21.
//

import SwiftUI

struct ContentView: View {
    
    @State private var showSettingsView: Bool = false
    
    var body: some View {
        NavigationView {
            PlanView()
                .toolbar(content: {
                    Button(action: toggleSettingsView, label: {
                        Image(systemName: "gear")
                    })
                })
                .sheet(isPresented: $showSettingsView, content: {
                    SettingsView()
                })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func toggleSettingsView() {
        self.showSettingsView.toggle()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Plan())
    }
}
