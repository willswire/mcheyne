//
//  SettingsView.swift
//  The M'Cheyne Plan (iOS)
//
//  Created by Will Walker on 7/20/21.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    
    @EnvironmentObject var model: Plan
    @Environment(\.presentationMode) var presentationMode
    @State private var showResetAlert: Bool = false
    @State private var showDateChangeAlert: Bool = false
    @State private var startDate: Date = Date()
    private var YTD: ClosedRange<Date> {
        let today = Date()
        return (today - 31536000)...today
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Start Date", selection: $startDate, in: YTD, displayedComponents: [.date])
                        .onAppear {
                            startDate = model.startDate
                        }
                    
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
    
    func changeStartDate() {
        model.reset()
        model.setStartDate(to: startDate)
        model.markPreviousSelectionsAsRead()
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
        if self.startDate != model.startDate {
            changeStartDate()
        }
    }
    
    func reset() {
        model.reset()
        startDate = model.startDate
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
