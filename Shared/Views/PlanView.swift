import SwiftUI

struct PlanView: View {
    @EnvironmentObject var plan: Plan
    @State private var selectionIndex: Int = 0
    @State private var indexForTodaysDate: Int = 0
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        VStack {
            Spacer()
            HeaderView()
            Spacer()
            ReadingSelectionView(selection: plan.getSelection(at: selectionIndex))
            Spacer()
            DateSelectionView(selectedIndex: $selectionIndex, indexForTodaysDate: $indexForTodaysDate)
            Spacer()
        }
        .padding()
        .onAppear {
            self.selectionIndex = plan.indexForTodaysDate
            self.indexForTodaysDate = plan.indexForTodaysDate
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                self.indexForTodaysDate = plan.indexForTodaysDate
            }
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
            
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
    @Binding var indexForTodaysDate: Int
    
    var body: some View {
        VStack {
            HStack {
                Button(action: goBack) {
                    Image(systemName: "arrow.backward")
                }
                .disabled(selectedIndex == 0)
                
                Spacer()
                
                if plan.isSelfPaced {
                    Spacer(minLength: 250)
                } else {
                    Text(Date() + (Double(selectedIndex - plan.indexForTodaysDate) * DAY_IN_SECONDS), style: .date).fixedSize()
                }
                
                Spacer()
                
                Button(action: goForward) {
                    Image(systemName: "arrow.forward")
                }
                .disabled(disable(for: selectedIndex))
            }
            .padding()
            .padding(.horizontal, 75)
            
            if !plan.isSelfPaced && selectedIndex != indexForTodaysDate {
                Button(action: goToToday) {
                    Text("Today")
                }
                .buttonStyle(.bordered)
            } else {
                Button("Today", action: {})
                    .buttonStyle(.bordered)
                    .hidden()
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
        selectedIndex = plan.indexForTodaysDate
    }
    
    func disable(for index: Int) -> Bool {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date.now)
        return (selectedIndex == (self.plan.isLeapYear(thisYear) ? 365 : 364))
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView()
            .environmentObject(Plan())
        #if os(macOS)
            .frame(width: 500, height: 500)
        #endif
    }
}
