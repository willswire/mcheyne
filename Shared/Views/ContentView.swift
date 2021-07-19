//
//  ContentView.swift
//  Shared
//
//  Created by Will Walker on 7/19/21.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: Model
    @State private var date = Date()
    
    private let DAY_IN_SECONDS: Double = 86400
    private let today = Date()
    
    var body: some View {
        VStack {

            HeaderView()
            
            ForEach(model.getReadings()[1]!, id: \.self) { reading in
                Button(action: {}, label: {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(.secondarySystemBackground))
                            .frame(maxHeight: 75)
                        HStack {
                            Image(systemName: "circle")
                                .font(.title2)
                            Text(reading)
                                .foregroundColor(.black)
                                .font(.title2)
                                .padding()
                        }
                        .padding(.horizontal)
                    }
                })
            }
            .padding(.horizontal)
            
            HStack {
                Button(action: goBack, label: {
                    Image(systemName: "arrow.backward")
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
            
            if (abs(date.distance(to: today)) > (DAY_IN_SECONDS / 2)) {
                Button(action: returnToToday, label: {
                    Text("Today")
                })
            }
        }
        .padding()
    }
    
    func goBack() {
        self.date -= DAY_IN_SECONDS
        print("Go backwards!")
    }
    
    func goForward() {
        self.date += DAY_IN_SECONDS
        print("Go forwards!")
    }
    
    func returnToToday() {
        self.date = self.today
        print("Return to today!")
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
            
            VStack {
                Text("The M'Cheyne")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                
                Text("Daily Bible Reading Plan")
                    .font(.title3)
                    .bold()
            }
        }
        .padding(.bottom)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Model())
    }
}
