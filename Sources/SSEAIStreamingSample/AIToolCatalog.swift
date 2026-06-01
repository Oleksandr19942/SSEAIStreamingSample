import Foundation

/// The seven on-device function tools wired into production `ChatAIConversationRunner`.
public enum AIToolCatalog: CaseIterable, Sendable {
    case changeAdditionInformation
    case searchSpecialistClinic
    case createSummaryInChat
    case getMedicalRecordById
    case getMedicationById
    case getLatestAppleHealthRecords
    case semanticSearch

    public var name: String {
        switch self {
        case .changeAdditionInformation: return "ChangeAdditionInformation"
        case .searchSpecialistClinic: return "SearchSpecialistClinic"
        case .createSummaryInChat: return "CreateSummaryInChat"
        case .getMedicalRecordById: return "GetMedicalRecordById"
        case .getMedicationById: return "GetMedicationById"
        case .getLatestAppleHealthRecords: return AppleHealthAIToolDefinition.toolName
        case .semanticSearch: return SemanticSearchScope.toolName
        }
    }

    public var highlight: String {
        switch self {
        case .changeAdditionInformation:
            return "Profile updates only after explicit user confirmation"
        case .searchSpecialistClinic:
            return "Provider search with real user location context"
        case .createSummaryInChat:
            return "SOAP-style summaries from conversation state"
        case .getMedicalRecordById, .getMedicationById:
            return "Precise fetches when IDs are already known"
        case .getLatestAppleHealthRecords:
            return "Apple Health snapshots (14-day window) for personalized answers"
        case .semanticSearch:
            return "Unified search across records, chat, files, meds, and Health data"
        }
    }
}
