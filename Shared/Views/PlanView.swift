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
    @State var date = Date()
    @EnvironmentObject var model: Plan
    private let DAY_IN_SECONDS: Double = 86400
    private let today = Date()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: goBack, label: {
                    if (abs(date.distance(to: model.getStartDate())) > DAY_IN_SECONDS) {
                        Image(systemName: "arrow.backward")
                    }
                })
                Spacer()
                Text(self.date, style: .date)
                Spacer()
                Button(action: goForward, label: {
                    Image(systemName: "arrow.forward")
                })
            }
            .padding()
            .padding(.horizontal, 75)
            
            Button(action: returnToToday, label: {
                if (abs(date.distance(to: today)) > (DAY_IN_SECONDS / 2)) {
                    Text("Today")
                } else {
                    Text("Today").hidden()
                }
            })
        }
    }
    
    func goBack() {
        self.date -= DAY_IN_SECONDS
        self.model.currentDate = date
        //print("Go backwards!")
    }
    
    func goForward() {
        self.date += DAY_IN_SECONDS
        self.model.currentDate = date
        //print("Go forwards!")
    }
    
    func returnToToday() {
        self.date = self.today
        self.model.currentDate = date
        //print("Return to today!")
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView()
    }
}
