//
//  SettingsView.swift
//  The M'Cheyne Plan (iOS)
//
//  Created by Will Walker on 7/20/21.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    
    @EnvironmentObject var plan: Plan
    @Environment(\.presentationMode) var presentationMode
    @State private var isSelfPaced: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var startDate: Date = Date()
    private var YTD: ClosedRange<Date> {
        let today = Date()
        return (today - 31536000)...today
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(isOn: $isSelfPaced) {
                        Text("Self-Paced Mode")
                    }
                    .onChange(of: isSelfPaced) { newValue in
                        plan.setSelfPaced(to: newValue)
                    }
                    if (!isSelfPaced) {
                        DatePicker("Start Date", selection: $startDate, in: YTD, displayedComponents: [.date])
                            .onAppear {
                                startDate = plan.startDate
                                isSelfPaced = plan.isSelfPaced
                            }
                    }
                }
                
                Section {
                    Button("Reset Plan") {
                        showResetAlert.toggle()
                    }
                    .alert(isPresented: $showResetAlert, content: {
                        Alert(title: Text("Reset Progress"),
                              message: Text("All reading plan progress will be erased. A new plan will be created starting on today's date."),
                              primaryButton: .cancel(),
                              secondaryButton: .destructive(Text("Reset"), action:
                                                                reset
                                                           )
                        )
                    })
                }
            }
            .navigationBarTitle("Settings")
            .toolbar {
                Button(action: close, label: {
                    Text("Close")
                })
            }
            .interactiveDismissDisabled(true)
        }
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
        if self.startDate != plan.startDate {
            plan.changeStartDate(to: self.startDate)
        }
    }
    
    func reset() {
        plan.reset()
        startDate = plan.startDate
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
