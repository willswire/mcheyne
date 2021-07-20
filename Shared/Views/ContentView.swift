//
//  ContentView.swift
//  Shared
//
//  Created by Will Walker on 7/19/21.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: Model
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            HeaderView()
            ReadingSelectionsView(selectedDate: $selectedDate)
            DateSelectionView(selectedDate: $selectedDate)
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

struct ReadingSelectionsView: View {
    
    @Binding var selectedDate: Date
    @EnvironmentObject var model: Model
    
    @State private var readings: [String] = [""]
    
    var body: some View {
        ForEach(readings) { reading in
            ReadingSelectionView(reading: reading)
        }
        .padding(.horizontal)
        .onAppear(perform: {
            readings = model.getReadingsFor(selectedDate)
        })
        .onChange(of: selectedDate, perform: { value in
            readings = model.getReadingsFor(value)
        })
    }
}

struct ReadingSelectionView: View {
    
    @State private var isCompleted: Bool = false
    var reading: String = ""
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.secondarySystemBackground))
                .frame(maxHeight: 75)
            HStack {
                Button(action: toggle, label: {
                    Image(systemName: isCompleted ?  "largecircle.fill.circle" : "circle")
                        .font(.title2)
                })
                Text(reading)
                    .foregroundColor(isCompleted ? .gray : .black)
                    .font(.title2)
                    .padding()
            }
            .padding(.horizontal)
        }
    }
    
    func toggle() {
        isCompleted.toggle()
    }
}

struct DateSelectionView: View {
    @Binding var selectedDate: Date
    private let DAY_IN_SECONDS: Double = 86400
    private let today = Date()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: goBack, label: {
                    Image(systemName: "arrow.backward")
                })
                Spacer()
                Text(self.selectedDate, style: .date)
                Spacer()
                Button(action: goForward, label: {
                    Image(systemName: "arrow.forward")
                })
            }
            .padding()
            .padding(.horizontal, 75)
            
            Button(action: returnToToday, label: {
                if (abs(selectedDate.distance(to: today)) > (DAY_IN_SECONDS / 2)) {
                    Text("Today")
                } else {
                    Text("Today").hidden()
                }
            })
        }
    }
    
    func goBack() {
        self.selectedDate -= DAY_IN_SECONDS
        print("Go backwards!")
    }
    
    func goForward() {
        self.selectedDate += DAY_IN_SECONDS
        print("Go forwards!")
    }
    
    func returnToToday() {
        self.selectedDate = self.today
        print("Return to today!")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Model())
    }
}
