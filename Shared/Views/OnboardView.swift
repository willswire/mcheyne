//
//  FirstTimeView.swift
//  myPFA
//
//  Created by Will Walker on 3/31/21.
//

import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var plan: Plan
    @State private var importPlan: Bool = false
    @State private var isSelfPaced: Bool = false
    @State private var startDate: Date = Date()
    private var YTD: ClosedRange<Date> {
        let today = Date()
        return (today - 31536000)...today
    }
    
    var body: some View {
        VStack {
            
            Form {
                Section {
                    HeaderView()
                        .listRowInsets(.init())
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                
                Text("Robert Murray M'Cheyne was an early 19th century minister who lived in Scotland. His daily Bible reading plan guides readers through the Old Testament once and the New Testament and Psalms twice per year.")
                
                Section {
                    Toggle(isOn: $isSelfPaced) {
                        Text("Self-Paced Mode")
                    }
                    .onChange(of: isSelfPaced) { newValue in
                        plan.setSelfPaced(to: newValue)
                    }
                    
                    Toggle(isOn: $importPlan) {
                        Text("Import Progress")
                    }
                    
                    if importPlan {
                        DatePicker("Start Date", selection: $startDate, in: YTD, displayedComponents: [.date])
                            .onChange(of: startDate) { _ in
                                plan.changeStartDate(to: startDate)
                            }
                    } else {
                        EmptyView()
                    }
                }
                
                Section {
                    Button(action: dismissView){
                        Text("Next")
                    }
                }
                
            }
        }
    }
    
    func dismissView() {
        UserDefaults.standard.set(true, forKey: "onboarded")
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnboardingView()
            
        }
    }
}
