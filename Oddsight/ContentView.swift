import SwiftUI

struct ContentView: View {
    let automaticallyRefreshes: Bool

    init(automaticallyRefreshes: Bool = true) {
        self.automaticallyRefreshes = automaticallyRefreshes
    }

    var body: some View {
        RootTabView(automaticallyRefreshes: automaticallyRefreshes)
    }
}

#Preview {
    ContentView(automaticallyRefreshes: false)
}
