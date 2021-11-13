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
            DateSelectionView(selectedIndex: $index)
            Spacer()
        }
        .padding()
        .onAppear {
            self.index = plan.currentIndex
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
    @Binding var selectedIndex: Int
    
    var body: some View {
        VStack {
            HStack {
                
                if (selectedIndex != 0) {
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
                    Text(Date() + (Double(selectedIndex - plan.currentIndex) * DAY_IN_SECONDS), style: .date).fixedSize()
                }
                
                Spacer()
                
                if (selectedIndex != 364) {
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
                Button(action: goToToday, label: {
                    if (selectedIndex != plan.currentIndex) {
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
        selectedIndex -= 1
    }
    
    func goForward() {
        selectedIndex += 1
    }
    
    func goToToday() {
        selectedIndex = plan.currentIndex
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView().environmentObject(Plan())
    }
}
