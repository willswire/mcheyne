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
                Button(action: goBack, label: {
                    if (abs(model.currentDate.distance(to: model.startDate)) > DAY_IN_SECONDS) {
                        Image(systemName: "arrow.backward")
                    }
                })
                Spacer()
                Text(model.currentDate, style: .date).fixedSize()
                Spacer()
                Button(action: goForward, label: {
                    Image(systemName: "arrow.forward")
                })
            }
            .padding()
            .padding(.horizontal, 75)
            
            Button(action: returnToToday, label: {
                if (abs(model.currentDate.distance(to: Date())) > (DAY_IN_SECONDS / 2)) {
                    Text("Today")
                } else {
                    Text("Today").hidden()
                }
            })
        }
    }
    
    func goBack() {
        model.currentDate -= DAY_IN_SECONDS
        //print("Go backwards!")
    }
    
    func goForward() {
        model.currentDate += DAY_IN_SECONDS
        //print("Go forwards!")
    }
    
    func returnToToday() {
        model.currentDate = Date()
        //print("Return to today!")
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView()
    }
}
