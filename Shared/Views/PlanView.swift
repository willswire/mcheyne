//
//  ContentView.swift
//  Shared
//
//  Created by Will Walker on 7/19/21.
//

import SwiftUI

struct PlanView: View {
    
    @EnvironmentObject var model: Plan
    
    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            ReadingSelectionView()
            Spacer()
            DateSelectionView()
            Spacer()
        }
        .padding()
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
    @EnvironmentObject var model: Plan
    
    var body: some View {
        VStack {
            HStack {
                if (model.currentDate.dayOfYear != model.startDate.dayOfYear) {
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
                Text(model.currentDate, style: .date).fixedSize()
                Spacer()
                if (model.currentDate.dayOfYear != 364) {
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
            
            Button(action: returnToToday, label: {
                if (model.currentDate.dayOfYear + model.startDate.dayOfYear > Date().dayOfYear) {
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
    
    func goBack() {
        model.currentDate -= DAY_IN_SECONDS
    }
    
    func goForward() {
        model.currentDate += DAY_IN_SECONDS
    }
    
    func returnToToday() {
        model.currentDate = Date()
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView().environmentObject(Plan())
    }
}
