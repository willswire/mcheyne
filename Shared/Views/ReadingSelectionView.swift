//
//  ReadingSelectionView.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 7/21/21.
//

import SwiftUI

struct ReadingSelectionView: View {
    @EnvironmentObject var model: Plan
    @ObservedObject var selection: ReadingSelection
    
    var body: some View {
        ForEach(selection.getPassages()) { passage in
            PassageView(passage: passage)
        }
        .padding(.horizontal)
    }
}

struct PassageView: View {
    @ObservedObject var passage: Passage
    
    var body: some View {
        Button(action: toggle, label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(.secondarySystemBackground))
                    .frame(maxWidth: 500, maxHeight: 75)
                HStack {
                    
                    Image(systemName: passage.hasRead() ?  "largecircle.fill.circle" : "circle")
                        .font(.title2)
                    
                    Text(passage.description)
                        .font(.title3)
                        .padding()
                }
                .padding(.horizontal)
            }
        })
    }
    
    func toggle() {
        passage.hasRead() ? passage.unread() : passage.read()
    }
}

struct ReadingSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReadingSelectionView(selection: ReadingSelection())
                .environmentObject(Plan())
        }
    }
}
