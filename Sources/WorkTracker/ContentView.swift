import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("WorkTracker")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Kanban + Notebooks")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
