import SwiftUI

@main
struct ChatStreamingDemoApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(dependencies)
        }
    }
}
