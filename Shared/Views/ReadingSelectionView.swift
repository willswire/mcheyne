import SwiftUI

struct ReadingSelectionView: View {
    var selection: ReadingSelection
    
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
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color("AppColor"))
                    .frame(maxWidth: 512, maxHeight: 64)
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
