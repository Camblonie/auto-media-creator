import SwiftUI

// Environment key for OpenAIService
private struct OpenAIServiceKey: EnvironmentKey {
    static let defaultValue: OpenAIService = OpenAIService()
}

// Extension to add OpenAIService to EnvironmentValues
extension EnvironmentValues {
    var openAIService: OpenAIService {
        get { self[OpenAIServiceKey.self] }
        set { self[OpenAIServiceKey.self] = newValue }
    }
}
