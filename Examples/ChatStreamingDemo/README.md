# ChatStreamingDemo (SwiftUI)

Minimal **iOS 17** demo app that shows how the Swift package maps to a real UI layer:

| Pattern | Where |
|---------|--------|
| **SwiftUI** | `ChatDemoView`, tabs, bubbles |
| **Navigation** | `NavigationStack` + `TabView` |
| **MVVM** | `ChatDemoViewModel` |
| **async/await** | `send()` streaming |
| **Dependency Injection** | `AppDependencies` |

## Run

1. Open `ChatStreamingDemo.xcodeproj` in Xcode.
2. Select your **Development Team** for signing (target → Signing).
3. Run on an **iPhone simulator** (iOS 17+).

The app links the local package at the repo root (`../../`).

## Tabs

- **Chat** — live SSE preview using `ToolCallingConversationLoop` + `GetLatestAppleHealthRecords` tool call (mocked).
- **Health** — Apple Health domains + AI tool definition from production.
- **Uploads** — interactive `UploadBatchStateMachine` simulator.

No API keys required.
