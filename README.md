# SSEAIStreamingSample

Public Swift package with **production-grade patterns** used in a shipped App Store health AI app ([2ndOpinions](https://apps.apple.com/us/app/2ndopinions/id6560104742)).

This is **not** proprietary app source code. It is a **clean-room reference implementation** of the iOS patterns that matter for streaming AI chat and health workflows: the same architectural ideas as a large SwiftUI client, extracted into testable modules you can read on GitHub.

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

### 2. Rate-limit resilient streaming
`RateLimitRetryExecutor` + `StreamingHTTPClient` — retries **HTTP 429** with backoff (same idea as production `executeWithRateLimitRetry`).

### 3. Tool-calling conversation loop
`ToolCallingConversationLoop` — orchestrates:

```
stream turn → tool calls? → execute tools (cached) → stream again → final text
```

Includes tool output cache, streaming preview callbacks, and non-streaming recovery when SSE ends without visible text.

### 4. Apple Health ↔ AI chat (HealthKit integration)
Production connects **HealthKit on device** to **personalized AI answers**:

```
HealthKit reads → typed sync payload → backend snapshots
       ↓
GetLatestAppleHealthRecords (function tool) + SemanticSearch(AppleHealth)
```

Reference modules:

- `AppleHealthAIToolDefinition` — model tool schema (`GetLatestAppleHealthRecords`, 14-day window)  
- `HealthDataDomain` — heart, activity, sleep, nutrition, mobility, body, …  
- `SemanticSearchScope` — unified search including `AppleHealth`  
- `AIToolCatalog` — all **7 on-device tools** in the production runner  

The app syncs dozens of metric families (HR, HRV, SpO₂, steps, sleep stages, nutrition, mobility, etc.) — not a toy `stepCount` demo.

### 5. Resilient medical-record upload recovery
`UploadBatchStateMachine` + `UploadRecovery` — S3 upload → GraphQL persistence with **orphan job recovery**:

- **Orphan timeout** (3 min) when the app dies mid-upload  
- **In-flight grace period** (2 min) so foreground GraphQL is not double-fired  
- **Batch deduplication** keys and TTL pruning (7-day retention, max 50 batches)  

Same decision logic as production medical-record uploads (background tasks + reconciliation).

---

## Module map

| File | Responsibility |
|------|----------------|
| `ResponsesStreamAccumulator` | SSE JSON → `StreamTurnResult` |
| `StreamingHTTPClient` | URLSession bytes + 429 retry |
| `ToolCallingConversationLoop` | Multi-turn tool loop |
| `RateLimitRetryExecutor` | Backoff / retry policy |
| `AppleHealthAIToolDefinition` | HealthKit → AI tool bridge |
| `SemanticSearchScope` / `AIToolCatalog` | Search + 7-tool surface |
| `UploadBatchStateMachine` | Upload orphan recovery |

---

## Requirements

- iOS 17+ / macOS 14+  
- Swift 5.9+  

## Tests

```bash
swift test
```

Covers SSE parsing, tool loop, Health AI tool definitions, and upload recovery state machine.

---

## What is intentionally **not** here

- Full `HealthKitService` queries (large, permission-heavy)  
- Amplify / GraphQL / StoreKit implementations  
- Encrypted API key handling  
- Full SwiftUI chat layer  

Those remain in the private production app. This repo shows **reference logic** for patterns that are hard to fake on a resume.

---

## Related

- [2ndOpinions on the App Store](https://apps.apple.com/us/app/2ndopinions/id6560104742)  
- [StartupSoft case study](https://www.startupsoft.com/cases/2nd-opinion/)  
- [Author GitHub profile](https://github.com/Oleksandr19942)

## License

MIT
