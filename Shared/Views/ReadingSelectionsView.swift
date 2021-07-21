//
//  ReadingSelectionsView.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 7/21/21.
//

import SwiftUI

struct ReadingSelectionsView: View {
    
    @EnvironmentObject var model: Model
    @Binding var selectedDate: Date
    @State private var isCompleted: Bool = false
    @State private var selections: [String] = [""]
    
    var body: some View {
        ForEach(model.getSelections()[selectedDate]) { reading in
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
                        .font(.title2)
                        .padding()
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    func toggle() {
        print("\(!isCompleted ? "Read" : "Un-read")")
        isCompleted.toggle()
    }
}

struct ReadingSelectionsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReadingSelectionsView(selectedDate: .constant(Date()))
                .environmentObject(Model())
        }
    }
}
