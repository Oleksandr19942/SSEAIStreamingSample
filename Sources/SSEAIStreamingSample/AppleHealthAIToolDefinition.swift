import Foundation

/// Reference for how Apple Health data reaches the AI layer in a shipped health app.
///
/// Production flow:
/// 1. `HealthKitService` reads authorized samples (heart, activity, sleep, nutrition, mobility, …).
/// 2. `AppleHealthViewModel` builds a typed sync payload and uploads snapshots via GraphQL.
/// 3. `GetLatestAppleHealthRecords` is exposed to the model as a **function tool** so chat answers use real user metrics.
public enum AppleHealthAIToolDefinition {
    public static let toolName = "GetLatestAppleHealthRecords"

    /// Mirrors production tool guidance: prefer real Health data over generic advice.
    public static func makeOpenAITool() -> [String: Any] {
        [
            "type": "function",
            "name": toolName,
            "description": """
            Fetch the user's Apple Health snapshots for the last 14 days. Always call this tool first \
            when the user asks about their own health, activity, sleep, steps, heart, workouts, recovery, \
            or trends. Prefer retrieving real Apple Health data over giving generic advice.
            """,
            "parameters": [
                "type": "object",
                "properties": [
                    "limit": [
                        "type": ["integer", "null"],
                        "description": "Maximum number of daily snapshots to return (default 30)."
                    ]
                ],
                "required": ["limit"],
                "additionalProperties": false
            ] as [String: Any],
            "strict": true
        ]
    }

    public static func normalizedLimit(from arguments: [String: Any], defaultValue: Int = 30) -> Int {
        guard let raw = arguments["limit"] else { return defaultValue }
        if raw is NSNull { return defaultValue }
        if let value = raw as? Int { return min(max(value, 1), 90) }
        if let value = raw as? Double { return min(max(Int(value), 1), 90) }
        return defaultValue
    }
}

/// Domains covered by production HealthKit sync (not an exhaustive HK type list).
public enum HealthDataDomain: String, CaseIterable, Sendable {
    case heart
    case activity
    case sleep
    case nutrition
    case mobility
    case body
    case vitals
    case reproductive
    case hearing
    case mindfulness

    public var productionExamples: String {
        switch self {
        case .heart:
            return "HR, HRV, SpO₂, blood pressure, cardio events, VO₂ max"
        case .activity:
            return "steps, energy, exercise time, stand hours, distance"
        case .sleep:
            return "sleep stages, duration, schedule"
        case .nutrition:
            return "macros, water, caffeine"
        case .mobility:
            return "walking speed, steadiness, stair speed"
        case .body:
            return "weight, BMI, body fat, temperature"
        case .vitals:
            return "respiratory rate, perfusion index"
        case .reproductive, .hearing, .mindfulness:
            return "category-specific samples when authorized"
        }
    }
}
