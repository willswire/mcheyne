//
//  ReadingSelectionView.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 7/21/21.
//

import SwiftUI

struct ReadingSelectionView: View {
    
    @EnvironmentObject var model: Model
    @Binding var date: Date
    @State var selection = ReadingSelection(["None"])
    
    var body: some View {
        ForEach(selection.getPassages()) { passage in
            PassageView(passage: passage)
        }
        .padding(.horizontal)
        .onAppear(perform: {
            self.selection = model.getSelection(for: date)
        })
        .onChange(of: date, perform: { value in
            self.selection = model.getSelection(for: date)
        })
    }
}

struct PassageView: View {
    @State var passage: Passage
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.secondarySystemBackground))
                .frame(maxHeight: 75)
            HStack {
                Button(action: toggle, label: {
                    Image(systemName: passage.hasRead ?  "largecircle.fill.circle" : "circle")
                        .font(.title2)
                })
                Text(passage.reference)
                    .font(.title2)
                    .padding()
            }
            .padding(.horizontal)
        }
    }
    
    func toggle() {
        passage.hasRead.toggle()
    }
}

struct ReadingSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReadingSelectionView(date: .constant(Date()))
                .environmentObject(Model(Date()))
        }
    }
}
