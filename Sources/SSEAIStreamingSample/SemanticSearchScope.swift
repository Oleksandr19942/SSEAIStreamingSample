import Foundation

/// Search scopes available to the on-device `SemanticSearch` tool in production.
public enum SemanticSearchScope: String, CaseIterable, Sendable {
    case medicalRecord = "MedicalRecord"
    case chatMessage = "ChatMessage"
    case note = "Note"
    case file = "File"
    case summaryInChat = "SummaryInChat"
    case medication = "Medication"
    case appleHealth = "AppleHealth"

    public static let toolName = "SemanticSearch"

    public static func makeOpenAITool() -> [String: Any] {
        [
            "type": "function",
            "name": toolName,
            "description": """
            Search within the user's stored data: medical records, messages, files, chat summaries, \
            medications, and Apple Health snapshots.
            """,
            "parameters": [
                "type": "object",
                "properties": [
                    "query": ["type": "string"],
                    "searchTypes": [
                        "type": ["array", "null"],
                        "items": [
                            "type": "string",
                            "enum": SemanticSearchScope.allCases.map(\.rawValue)
                        ]
                    ]
                ],
                "required": ["query", "searchTypes"],
                "additionalProperties": false
            ] as [String: Any],
            "strict": true
        ]
    }
}
