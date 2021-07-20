//
//  SettingsView.swift
//  The M'Cheyne Plan (iOS)
//
//  Created by Will Walker on 7/20/21.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var startDate: Date = Date()
    @State private var showResetAlert: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("READING PLAN")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Button("Reset Progress") {
                        showResetAlert = true
                    }
                }
                
                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                    }
                }
            }
            .alert(isPresented: $showResetAlert, content: {
                Alert(title: Text("Reset Progress"),
                      message: Text("All reading plan progress will be erased. A new plan will be created starting on today's date."),
                      primaryButton: .cancel({
                        print("Canceled reset!")
                      }),
                      secondaryButton: .destructive(Text("Reset"), action: {
                        print("Reset!")
                      })
                )
            })
            .navigationBarTitle("Settings")
            .toolbar(content: {
                Button(action: close, label: {
                    Text("Close")
                })
            })
        }
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func reset() {
        print("Reset progress")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}