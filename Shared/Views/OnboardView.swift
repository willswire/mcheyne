//
//  FirstTimeView.swift
//  myPFA
//
//  Created by Will Walker on 3/31/21.
//

import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var model: Plan
    @State private var importPlan: Bool = false
    @State private var startDate: Date = Date()
    private var YTD: ClosedRange<Date> {
        let today = Date()
        return (today - 31536000)...today
    }
    
    var body: some View {
        VStack {
            HeaderView()
            
            Group {
                Text("Robert Murray M'Cheyne was an early 19th century minister who lived in Scotland. His daily Bible reading plan guides readers through the Old Testament once and the New Testament and Psalms twice per year.")
                    .padding()
                
                VStack {
                    Toggle(isOn: $importPlan) {
                        Text("Import Progress")
                    }
                    .padding()
                    
                    if importPlan {
                        DatePicker("Start Date", selection: $startDate, in: YTD, displayedComponents: [.date])
                            .onChange(of: startDate) { _ in
                                changeStartDate()
                            }
                            .padding()
                    } else {
                        EmptyView()
                    }
                }
                
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding()
            
            Spacer()
            
            Button(action: dismissView){
                Text("Next")
                    .frame(width: 375, height: 50)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            
        }
        .padding()
    }
    
    func changeStartDate() {
        model.reset()
        model.setStartDate(to: startDate)
        model.markPreviousSelectionsAsRead()
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
        //        .preferredColorScheme(.dark)
    }
}
