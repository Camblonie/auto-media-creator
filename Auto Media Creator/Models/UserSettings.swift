import Foundation
import SwiftData
import UIKit

// User settings model to store preferences and configuration
@Model
final class UserSettings {
    // General settings
    var id: UUID
    var onboardingCompleted: Bool
    var businessName: String
    var businessLogo: Data?
    var defaultTags: String
    
    // OpenAI settings
    var openAIApiKey: String
    
    // Auto hashtags from requirements
    static let defaultHashtags = "#tuffy #tuffyauto #tuffyautoservicewalledlake #thatsatuffy #walledlake #walledlaketuffy #tuffywalledlake #autorepairnearme #autorepair #autorepairshop #autorepairs #autorepairservice #LakesAreaChamberOfCommerce"
    
    // Create UserSettings with default values
    init(id: UUID = UUID(), 
         onboardingCompleted: Bool = false,
         businessName: String = "Auto Repair Shop",
         openAIApiKey: String = "") {
        self.id = id
        self.onboardingCompleted = onboardingCompleted
        self.businessName = businessName
        self.openAIApiKey = openAIApiKey
        self.defaultTags = UserSettings.defaultHashtags
    }
    
    // Get the business logo as UIImage
    var logoImage: UIImage? {
        if let logoData = businessLogo {
            return UIImage(data: logoData)
        }
        return nil
    }
    
    // Set the business logo from UIImage
    func setLogo(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            self.businessLogo = data
        }
    }
    
    // Reset hashtags to default
    func resetHashtags() {
        self.defaultTags = UserSettings.defaultHashtags
    }
    
    // Get array of hashtags
    var hashtagArray: [String] {
        return defaultTags.components(separatedBy: " ")
            .filter { $0.hasPrefix("#") && $0.count > 1 }
    }
    
    // Convenience method to get formatted hashtags string
    func formattedHashtags(separator: String = " ") -> String {
        return hashtagArray.joined(separator: separator)
    }
}
