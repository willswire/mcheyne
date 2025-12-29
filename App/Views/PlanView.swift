//
//  PlanView.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 12/29/25.
//


import SwiftUI

struct PlanView: View {
    @EnvironmentObject var plan: Plan
    @State private var selectionIndex: Int = 0
    @State private var indexForTodaysDate: Int = 0
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView()
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                    .frame(maxWidth: 600)
                    .accessibilityElement(children: .combine)

                ReadingSelectionView(selection: plan.getSelection(at: selectionIndex))
                    .frame(maxWidth: 700)

                DateSelectionView(selectedIndex: $selectionIndex, indexForTodaysDate: $indexForTodaysDate)
                    .frame(maxWidth: 700)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            self.selectionIndex = plan.indexForTodaysDate
            self.indexForTodaysDate = plan.indexForTodaysDate
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.indexForTodaysDate = plan.indexForTodaysDate
                }
            }
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text("The M'Cheyne")
                    .font(.largeTitle).bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text("Daily Bible Reading Plan")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 600, alignment: .leading)
    }
}

struct DateSelectionView: View {
    @EnvironmentObject var plan: Plan
    @Binding var selectedIndex: Int
    @Binding var indexForTodaysDate: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Button(action: goBack) {
                    Image(systemName: "chevron.backward")
                }
                .controlSize(.large)
                .accessibilityLabel("Previous Day")
                .disabled(selectedIndex == 0)

                Spacer()

                if plan.isSelfPaced {
                    Spacer(minLength: 200)
                } else {
                    Text(Date() + (Double(selectedIndex - plan.indexForTodaysDate) * DAY_IN_SECONDS), style: .date)
                        .fixedSize()
                        .contentTransition(.numericText())
                }

                Spacer()

                Button(action: goForward) {
                    Image(systemName: "chevron.forward")
                }
                .controlSize(.large)
                .accessibilityLabel("Next Day")
                .disabled(disable(for: selectedIndex))
            }
            .padding(.horizontal)

            if !plan.isSelfPaced && selectedIndex != indexForTodaysDate {
                Button(action: goToToday) {
                    Text("Today")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Go to Today")
            } else {
                Color.clear.frame(height: 0)
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
