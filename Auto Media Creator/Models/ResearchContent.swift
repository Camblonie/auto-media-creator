import Foundation
import SwiftData

@Model
final class ResearchContent {
    // MARK: - Properties
    var headline: String
    var summary: String
    var creationDate: Date
    var source: String
    var additionalDetails: String
    
    // MARK: - Initialization
    init(headline: String, summary: String, source: String = "", additionalDetails: String = "") {
        self.headline = headline
        self.summary = summary
        self.source = source
        self.additionalDetails = additionalDetails
        self.creationDate = Date()
    }
    
    // MARK: - Helper Methods
    
    /// Returns a formatted string with the headline and summary
    func formattedContent() -> String {
        """
        HEADLINE: \(headline)
        
        SUMMARY: \(summary)
        """
    }
    
    /// Returns a short preview of the content
    func preview(maxLength: Int = 100) -> String {
        let content = headline + ": " + summary
        if content.count <= maxLength {
            return content
        }
        return content.prefix(maxLength) + "..."
    }
}
