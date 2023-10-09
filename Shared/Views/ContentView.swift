import SwiftUI

struct ContentView: View {
    @EnvironmentObject var planModel: Plan
    @State private var showSettingsView: Bool = false
    @AppStorage("onboarded") var onboarded: Bool = false
    
    var body: some View {
        NavigationStack {
            if onboarded {
                PlanView()
                    .toolbar {
                        Button(action: toggleSettingsView) {
                            Image(systemName: "gear")
                        }
                    }
                    .sheet(isPresented: $showSettingsView) {
                        SettingsView()
                    }
            } else {
                OnboardingView()
            }
        }
    }
    
    func toggleSettingsView() {
        self.showSettingsView.toggle()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(onboarded: false)
            .environmentObject(Plan())
        #if os(macOS)
            .frame(width: 500, height: 500)
        #endif
    }
}
