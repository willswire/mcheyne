//
//  ContentView.swift
//  Shared
//
//  Created by Will Walker on 7/19/21.
//

import SwiftUI

struct PlanView: View {
    
    @EnvironmentObject var plan: Plan
    @State private var index: Int = 0
    
    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            ReadingSelectionView(selection: plan.getSelection(at: index))
            Spacer()
            DateSelectionView(index: $index)
            Spacer()
        }
        .padding()
        .onAppear {
            setIndex()
        }
    }
    
    func setIndex() {
        if (plan.isSelfPaced) {
            if let index = plan.selections.firstIndex(where: { !$0.isComplete() }) {
                self.index = index
            }
        } else {
            if (Calendar.current.component(.year, from: Date()) > Calendar.current.component(.year, from: plan.startDate)) {
                self.index = Date().dayOfYear - plan.startDate.dayOfYear + 365
            } else {
                self.index = Date().dayOfYear - plan.startDate.dayOfYear
            }
        }
    }
    
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
            
            VStack(alignment: .leading) {
                Text("The M'Cheyne")
                    .font(.largeTitle)
                    .bold()
                
                Text("Daily Bible Reading Plan")
                    .font(.title3)
                    .bold()
            }
            .padding()
        }
    }
}

struct DateSelectionView: View {
    @EnvironmentObject var plan: Plan
    @Binding var index: Int
    
    var body: some View {
        VStack {
            HStack {
                
                if (plan.currentDate.dayOfYear != plan.startDate.dayOfYear) {
                    Button(action: goBack, label: {
                        Image(systemName: "arrow.backward")
                    })
                } else {
                    Button(action: {}, label: {
                        Image(systemName: "arrow.backward")
                    })
                        .hidden()
                        .disabled(true)
                }
                Spacer()
                if(plan.isSelfPaced) {
                    Spacer(minLength: 250)
                } else {
                    Text(plan.currentDate, style: .date).fixedSize()
                }
                Spacer()
                if (plan.currentDate.dayOfYear != 364) {
                    Button(action: goForward, label: {
                        Image(systemName: "arrow.forward")
                    })
                } else {
                    Button(action: {}, label: {
                        Image(systemName: "arrow.forward")
                    })
                        .hidden()
                        .disabled(true)
                }
            }
            .padding()
            .padding(.horizontal, 75)
            
            if(!plan.isSelfPaced) {
            Button(action: returnToToday, label: {
                if (plan.currentDate.dayOfYear != Date().dayOfYear) {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.secondarySystemBackground))
                        .frame(maxWidth: 75, maxHeight: 25)
                        .overlay(Text("Today"))
                } else {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.secondarySystemBackground))
                        .frame(maxWidth: 75, maxHeight: 25)
                        .overlay(Text("Today"))
                        .hidden()
                        .disabled(true)
                }
            })
            }
        }
    }
    
    func goBack() {
        plan.currentDate -= DAY_IN_SECONDS
        index -= 1
    }
    
    func goForward() {
        plan.currentDate += DAY_IN_SECONDS
        index += 1
    }
    
    func returnToToday() {
        plan.currentDate = Date()
        
        if (plan.isSelfPaced) {
            if let index = plan.selections.firstIndex(where: { !$0.isComplete() }) {
                self.index = index
            }
        } else {
            if (Calendar.current.component(.year, from: Date()) > Calendar.current.component(.year, from: plan.startDate)) {
                self.index = Date().dayOfYear - plan.startDate.dayOfYear + 365
            } else {
                self.index = Date().dayOfYear - plan.startDate.dayOfYear
            }
        }
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView().environmentObject(Plan())
    }
}
