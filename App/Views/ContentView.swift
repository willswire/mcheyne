//
//  ContentView.swift
//  mcheyne-plan
//
//  Created by Will Walker on 12/29/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var planModel: Plan
    @State private var showSettingsView: Bool = false
    @AppStorage("onboarded") var onboarded: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if onboarded {
                    PlanView()
                        .navigationTitle("Plan")
                        .toolbarTitleDisplayMode(.automatic)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button(action: toggleSettingsView) {
                                    Label("Settings", systemImage: "gear")
                                }
                                .accessibilityLabel("Settings")
                                #if os(macOS)
                                .keyboardShortcut(",")
                                #endif
                            }
                        }
                        .sheet(isPresented: $showSettingsView) {
                            #if os(macOS)
                            SettingsView()
                                .frame(minWidth: 480, minHeight: 360)
                            #else
                            SettingsView()
                                .presentationDetents([.medium, .large])
                                .presentationDragIndicator(.visible)
                            #endif
                        }
                } else {
                    OnboardingView()
                        #if os(macOS)
                        .background(.regularMaterial)
                        #else
                        .background(.thinMaterial)
                        #endif
                }
            }
        }
        #if canImport(UIKit)
        .task {
            if !onboarded {
                UIAccessibility.post(notification: .screenChanged, argument: "Onboarding")
            }
        }
        #endif
    }
    
    func toggleSettingsView() {
        self.showSettingsView.toggle()
    }
}

#Preview {
    ContentView()
        .environmentObject(Plan())
    #if os(macOS)
        .frame(width: 500, height: 500)
    #endif
}
