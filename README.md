# SSEAIStreamingSample

Small, **public** Swift package that demonstrates patterns used in production iOS AI chat apps:

- consume **Server-Sent Events (SSE)** over `URLSession`
- parse `data:` lines from streaming HTTP responses
- surface **`response.output_text.delta`** events for live UI updates

This is a **sanitized educational sample** — not production app code. It mirrors the architecture of a real App Store health AI client (line buffering, delta parsing, async streaming) without proprietary business logic, keys, or backend coupling.

## Why it exists

Portfolio reference for recruiters and iOS engineers who want to see how streaming AI chat can be structured on iOS without opening a private repository.

## Features

- `SSELineBuffer` — safe chunk → line reassembly
- `SSEAIStreamParser` — JSON `data:` event parsing (Azure OpenAI Responses-style deltas)
- `StreamingHTTPClient` — async byte/stream consumption with typed events
- XCTest coverage for parser and buffer behavior

## Requirements

- iOS 17+ / macOS 14+
- Swift 5.9+

## Usage (conceptual)

```swift
var request = URLRequest(url: streamURL)
request.httpMethod = "POST"
request.setValue("Bearer <token>", forHTTPHeaderField: "Authorization")
request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

let client = StreamingHTTPClient()
try await client.stream(request: request) { event in
    switch event {
    case .textDelta(let chunk):
        print(chunk, terminator: "")
    case .completed:
        print("\nDone")
    case .unknown:
        break
    }
}
```

## Related work

Built by [Oleksandr Meteliev](https://github.com/Oleksandr19942) while shipping **[2ndOpinions](https://apps.apple.com/us/app/2ndopinions/id6560104742)** — AI health app on the App Store.

## License

MIT
