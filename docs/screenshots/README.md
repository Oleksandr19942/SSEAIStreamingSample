# Screenshots (2ndOpinions — production UI)

All images in this folder are from the **shipped 2ndOpinions** app (UI exports / in-app assets).  
They are used in the public sample README to show real product work, not mock code-only diagrams.

| File | What it shows |
|------|----------------|
| `01-chat-conversations.png` | Chat history / sessions list |
| `02-chat-streaming-input.png` | Active chat input while asking the AI |
| `03-ai-summary-streaming.png` | “Summary is updating…” streaming state |
| `04-medical-records-ai-context.png` | Medical records used as AI context |
| `05-apple-health-ai-summary.png` | Apple Health metrics visual (app asset) |
| `06-chat-health-topic-sheet.png` | Health-topic chat sheet (e.g. hemoglobin) |

## Optional: upload recovery sheet

Capture from the production app (Simulator):

1. Open **Medical Records** → upload files.
2. Show `FileUploadsSheetView` with mixed states (uploading / uploaded / waiting).
3. Save as `07-upload-recovery-sheet.png` and add to README.

Xcode Preview path in private repo:  
`FileUploadsSheetView` → `#Preview` with `.uploading` / `.uploaded` rows.
