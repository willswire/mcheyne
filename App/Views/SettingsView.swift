//
//  SettingsView.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 12/29/25.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var plan: Plan
    @Environment(\.presentationMode) var presentationMode
    @State private var isSelfPaced: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var startDate: Date = Date()
    private var secondsInAYear: TimeInterval {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date.now)
        return self.plan.isLeapYear(thisYear) ? 31622400 : 31536000
    }
    private var yearToDate: ClosedRange<Date> {
        let today = Date()
        return (today - secondsInAYear)...today
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle(isOn: $isSelfPaced) {
                        Text("Self-Paced Mode")
                    }
                    .onChange(of: isSelfPaced) { oldValue, newValue in
                        plan.setSelfPaced(to: newValue)
                    }
                    if (!isSelfPaced) {
                        DatePicker("Start Date", selection: $startDate, in: yearToDate, displayedComponents: [.date])
                    }
                }

                Section("Danger Zone") {
                    Button(role: .destructive) {
                        showResetAlert.toggle()
                    } label: {
                        Label("Reset Plan", systemImage: "arrow.counterclockwise")
                    }
                    .alert(isPresented: $showResetAlert, content: {
                        Alert(title: Text("Reset Progress"),
                              message: Text("All reading plan progress will be erased. A new plan will be created starting on today's date."),
                              primaryButton: .cancel(),
                              secondaryButton: .destructive(Text("Reset"), action: reset)
                        )
                    })
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: close) {
                        Text("Close")
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel("Close Settings")
                }
            }
            .interactiveDismissDisabled(true)
            .onAppear {
                DispatchQueue.main.async {
                    startDate = plan.startDate
                    isSelfPaced = plan.isSelfPaced
                }
            }
            #if os(macOS)
            .frame(minHeight: 300)
            #endif
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
            .environmentObject(Plan())
    }
}
