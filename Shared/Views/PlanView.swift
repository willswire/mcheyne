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
    @State var date: Date = Date()
    
    var body: some View {
        VStack {
            HStack {
                if (model.selectionIndex != 0) {
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
                Text(date, style: .date).fixedSize()
                Spacer()
                if (model.selectionIndex != 364) {
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
                if (model.selectionIndex + model.startDate.dayOfYear > Date().dayOfYear) {
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
        self.date -= DAY_IN_SECONDS
        model.decreaseSelectionIndex()
    }
    
    func goForward() {
        self.date += DAY_IN_SECONDS
        model.increaseSelectionIndex()
    }
    
    func returnToToday() {
        self.date = Date()
        model.rebaseSelectionIndex()
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView().environmentObject(Plan())
    }
}
