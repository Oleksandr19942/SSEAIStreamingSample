# SSEAIStreamingSample

Public Swift package with **production-grade patterns** used in a shipped App Store health AI app ([2ndOpinions](https://apps.apple.com/us/app/2ndopinions/id6560104742)).

This is **not** proprietary app source code. It is a **clean-room reference implementation** of the iOS patterns that matter for streaming AI chat: the same architectural ideas as a large SwiftUI client, extracted into testable modules you can read on GitHub.

Built by [Oleksandr Meteliev](https://github.com/Oleksandr19942).

---

## Why this exists

Recruiters and iOS engineers often ask: *“Show me how you built streaming AI chat.”*  
Most of that work lives in private repositories. This package demonstrates the **strong parts** without leaking business logic, API keys, or backend contracts.

---

## Production patterns included

### 1. Responses SSE accumulator
`ResponsesStreamAccumulator` — parses Azure OpenAI **Responses API** stream events:

- `response.output_text.delta` / refusal deltas  
- `response.function_call_arguments.done` → tool calls  
- `response.completed` / `response.failed` metadata  
- `response_id` chaining for multi-turn conversations  

### 2. Live UI preview from partial JSON
`JSONMessagePreviewExtractor` — extracts the `"message"` field **while JSON is still streaming**, so the chat bubble updates before the model finishes the object. Hides raw `{` noise during streaming.

### 3. Rate-limit resilient streaming
`RateLimitRetryExecutor` + `StreamingHTTPClient` — retries **HTTP 429** with backoff (same idea as production `executeWithRateLimitRetry`).

### 4. Tool-calling conversation loop
`ToolCallingConversationLoop` — orchestrates:

```
stream turn → tool calls? → execute tools (cached) → stream again → final text
```

Includes:

- **Tool output cache** (duplicate calls avoided)  
- **Streaming preview** callbacks during deltas  
- **Non-streaming recovery** when SSE ends without visible text but no terminal completion event  

This mirrors the production `ChatAIConversationRunner` control flow.

---

## Module map

| File | Responsibility |
|------|----------------|
| `ResponsesStreamAccumulator` | SSE JSON → `StreamTurnResult` |
| `StreamingHTTPClient` | URLSession bytes + 429 retry |
| `JSONMessagePreviewExtractor` | Partial JSON → user-visible text |
| `ToolCallingConversationLoop` | Multi-turn tool loop |
| `RateLimitRetryExecutor` | Backoff / retry policy |

---

## Requirements

- iOS 17+ / macOS 14+  
- Swift 5.9+  

## Tests

```bash
swift test
```

Covers stream parsing, JSON preview extraction, tool loop behavior, and recovery heuristics.

---

## What is intentionally **not** here

- Amplify / GraphQL / HealthKit / StoreKit (app-specific integrations)  
- Medical record upload recovery (separate large subsystem)  
- Encrypted API key handling  
- Full UI layer (`ChatViewModel+Streaming`)  

Those remain in the private production app. This repo shows the **core AI streaming engine patterns** that are hardest to fake on a resume.

---

## Related

- [2ndOpinions on the App Store](https://apps.apple.com/us/app/2ndopinions/id6560104742)  
- [StartupSoft case study](https://www.startupsoft.com/cases/2nd-opinion/)  
- [Author GitHub profile](https://github.com/Oleksandr19942)

## License

MIT
