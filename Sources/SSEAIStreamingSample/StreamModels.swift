import Foundation

public struct StreamToolCall: Sendable, Equatable {
    public let callID: String
    public let name: String
    public let argumentsJSON: String

    public init(callID: String, name: String, argumentsJSON: String) {
        self.callID = callID
        self.name = name
        self.argumentsJSON = argumentsJSON
    }
}

public struct StreamTurnResult: Sendable, Equatable {
    public var responseID: String?
    public var toolCalls: [StreamToolCall]
    public var finalOutputText: String?
    public var responseStatus: String?
    public var incompleteDetails: String?
    public var failureMessage: String?
    public var hasOutputItems: Bool
    public var eventTypes: [String]

    public init(
        responseID: String? = nil,
        toolCalls: [StreamToolCall] = [],
        finalOutputText: String? = nil,
        responseStatus: String? = nil,
        incompleteDetails: String? = nil,
        failureMessage: String? = nil,
        hasOutputItems: Bool = false,
        eventTypes: [String] = []
    ) {
        self.responseID = responseID
        self.toolCalls = toolCalls
        self.finalOutputText = finalOutputText
        self.responseStatus = responseStatus
        self.incompleteDetails = incompleteDetails
        self.failureMessage = failureMessage
        self.hasOutputItems = hasOutputItems
        self.eventTypes = eventTypes
    }
}

public enum StreamClientError: Error, LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case rateLimited(retryAfter: TimeInterval?)
    case server(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid HTTP response."
        case .httpStatus(let code): return "Unexpected HTTP status: \(code)."
        case .rateLimited: return "Rate limited by upstream API."
        case .server(let message): return message
        }
    }
}
