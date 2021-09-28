//
//  SettingsView.swift
//  The M'Cheyne Plan (iOS)
//
//  Created by Will Walker on 7/20/21.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var model: Plan
    @Environment(\.presentationMode) var presentationMode
    @State private var showResetAlert: Bool = false
    @State private var startDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("READING PLAN")) {
                    DatePicker("Start Date", selection: $startDate, in: ...Date(), displayedComponents: [.date])
                        .onChange(of: startDate) { newDate in
                            model.setStartDate(to: newDate)
                        }
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
                      primaryButton: .cancel(),
                      secondaryButton: .destructive(Text("Reset"), action: {
                        reset()
                      })
                )
            })
            .navigationBarTitle("Settings")
            .toolbar {
                Button(action: close, label: {
                    Text("Close")
                })
            }
            .onAppear {
                self.startDate = model.startDate
            }
        }
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func reset() {
        model.reset()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
