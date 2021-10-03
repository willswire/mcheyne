//
//  ContentView.swift
//  Shared
//
//  Created by Will Walker on 7/19/21.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: Plan
    @State private var showSettingsView: Bool = false
    @AppStorage("onboarded") var onboarded: Bool = false
    
    var body: some View {
        NavigationView {
            if onboarded {
                PlanView()
                    .toolbar(content: {
                        Button(action: toggleSettingsView, label: {
                            Image(systemName: "gear")
                        })
                    })
                    .sheet(isPresented: $showSettingsView, content: {
                        SettingsView()
                    })
            } else {
                OnboardingView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func toggleSettingsView() {
        self.showSettingsView.toggle()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(onboarded: true)
            .environmentObject(Plan())
    }
}
