//
//  OnboardingView.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 12/29/25.
//


import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var plan: Plan
    @State private var importPlan: Bool = false
    @State private var isSelfPaced: Bool = false
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
        Form {
            Section {
                HeaderView()
                    .listRowInsets(.init())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(.thinMaterial)
                    )
            }

            Text("Robert Murray M'Cheyne was an early 19th century minister who lived in Scotland. His daily Bible reading plan guides readers through the Old Testament once and the New Testament and Psalms twice per year.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 4)

            Section("Preferences") {
                Toggle(isOn: $isSelfPaced) {
                    Text("Self-Paced Mode")
                }
                .onChange(of: isSelfPaced) { oldValue, newValue in
                    plan.setSelfPaced(to: newValue)
                }

                Toggle(isOn: $importPlan) {
                    Text("Import Progress")
                }

                if importPlan {
                    DatePicker("Start Date", selection: $startDate, in: yearToDate, displayedComponents: [.date])
                        .onChange(of: startDate) {
                            plan.changeStartDate(to: startDate)
                        }
                }
            }

            Section {
                Button(action: dismissView){
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Continue to Plan")
            }
        }
        .navigationTitle("Welcome")
        .formStyle(.grouped)
    }
    
    func dismissView() {
        UserDefaults.standard.set(true, forKey: "onboarded")
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
        }
    }
}
