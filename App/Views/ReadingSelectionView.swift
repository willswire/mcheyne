//
//  ReadingSelectionView.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 12/29/25.
//

import SwiftUI

struct ReadingSelectionView: View {
    var selection: ReadingSelection
    
    var body: some View {
        VStack(spacing: 12) {
            if selection.isLeap {
                VStack {
                    Label("Happy Leap Year!", systemImage: "figure.gymnastics")
                }
                .padding()
                .frame(maxWidth: 700)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(selection.getPassages()) { passage in
                    PassageView(passage: passage)
                }
            }
        }
    }
}

struct PassageView: View {
    @ObservedObject var passage: Passage
    
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: passage.hasRead() ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(passage.hasRead() ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))

                Text(passage.localizedDescription())
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 700, minHeight: 56, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(passage.localizedDescription())
            .accessibilityValue(passage.hasRead() ? "Read" : "Unread")
        }
        .buttonStyle(.plain)
    }
    
    func toggle() {
        if passage.hasRead() {
            passage.unread()
        } else {
            passage.read()
        }
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
