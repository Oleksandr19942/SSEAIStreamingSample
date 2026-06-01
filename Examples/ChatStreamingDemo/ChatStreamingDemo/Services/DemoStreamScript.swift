import Foundation

/// Scripted SSE lines that mirror Azure OpenAI Responses API events.
enum DemoStreamScript {
    static let healthAnswerLines: [String] = [
        #"data: {"type":"response.output_text.delta","delta":"Based on your recent "}"#,
        #"data: {"type":"response.output_text.delta","delta":"Apple Health data, your resting "}"#,
        #"data: {"type":"response.output_text.delta","delta":"heart rate trend looks stable."}"#,
        #"data: {"type":"response.completed","response":{"id":"resp-demo","status":"completed","output":[{"type":"message","content":[{"type":"output_text","text":"Based on your recent Apple Health data, your resting heart rate trend looks stable."}]}]}}"#
    ]
}
