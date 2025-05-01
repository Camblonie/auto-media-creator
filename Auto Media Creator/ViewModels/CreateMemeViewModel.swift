import Foundation
import SwiftUI
import SwiftData
import Combine

class CreateMemeViewModel: ObservableObject {
    // Services
    private let openAIService: OpenAIService
    private let modelContext: ModelContext
    
    // Published properties
    @Published var selectedPlatform: PlatformType?
    @Published var textInstruction: String = ""
    @Published var imageInstruction: String = ""
    @Published var memeText: String = ""
    @Published var imagePrompt: String = ""
    @Published var memeImage: UIImage?
    @Published var hashtags: String = ""
    
    // UI state
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccessAlert: Bool = false
    @Published var successMessage: String = ""
    
    // Modal state
    @Published var showTextInstructionModal: Bool = false
    @Published var showImageInstructionModal: Bool = false
    @Published var showResetTextInstructionAlert: Bool = false
    @Published var showResetImageInstructionAlert: Bool = false
    
    init(openAIService: OpenAIService, modelContext: ModelContext) {
        self.openAIService = openAIService
        self.modelContext = modelContext
        
        // Set default instructions
        resetTextInstruction()
        resetImageInstruction()
    }
    
    // Reset text instruction to default
    func resetTextInstruction() {
        if let platform = selectedPlatform {
            switch platform {
            case .facebook:
                textInstruction = """
                Create a humorous meme text for Facebook that relates to automotive repair. The text should be concise, witty, and relatable to both car owners and mechanics. It should be formatted in the typical meme style with a setup and punchline. Avoid technical jargon that average car owners wouldn't understand. Make it shareable and likely to get reactions.
                """
            case .instagram:
                textInstruction = """
                Create a humorous meme text for Instagram that relates to automotive repair. The text should be concise, witty, and relatable to both car owners and mechanics. It should be formatted in the typical meme style with a setup and punchline. Avoid technical jargon that average car owners wouldn't understand. Make it shareable and likely to get reactions.
                """
            case .twitter:
                textInstruction = """
                Create a humorous meme text for X (Twitter) that relates to automotive repair. The text should be concise, witty, and relatable to both car owners and mechanics. It should be formatted in the typical meme style with a setup and punchline. Avoid technical jargon that average car owners wouldn't understand. Make it shareable and likely to get reactions.
                """
            case .tiktok:
                textInstruction = """
                Create a humorous meme text for TikTok that relates to automotive repair. The text should be concise, witty, and relatable to both car owners and mechanics. It should be formatted in the typical meme style with a setup and punchline. Avoid technical jargon that average car owners wouldn't understand. Make it shareable and likely to get reactions.
                """
            case .linkedin:
                textInstruction = """
                Create a professional but humorous meme text for LinkedIn that relates to automotive repair. The text should be concise, witty, and relatable to both car owners and mechanics while maintaining a professional tone appropriate for LinkedIn. It should be formatted in the typical meme style with a setup and punchline. Avoid overly casual language but still make it engaging and shareable.
                """
            }
        } else {
            textInstruction = "Create a humorous meme text related to automotive repair."
        }
    }
    
    // Reset image instruction to default
    func resetImageInstruction() {
        if let platform = selectedPlatform {
            switch platform {
            case .facebook:
                imageInstruction = """
                Create a meme image for Facebook that complements the meme text about automotive repair. The image should be humorous, visually appealing, and relate directly to the text. It should be in a standard meme format with clear, readable text overlay. The image should be 1200px x 1200px.
                """
            case .instagram:
                imageInstruction = """
                Create a meme image for Instagram that complements the meme text about automotive repair. The image should be humorous, visually appealing, and relate directly to the text. It should be in a standard meme format with clear, readable text overlay. The image should be 1080px x 1080px.
                """
            case .twitter:
                imageInstruction = """
                Create a meme image for X (Twitter) that complements the meme text about automotive repair. The image should be humorous, visually appealing, and relate directly to the text. It should be in a standard meme format with clear, readable text overlay. The image should be 1200px x 675px.
                """
            case .tiktok:
                imageInstruction = """
                Create a meme image for TikTok that complements the meme text about automotive repair. The image should be humorous, visually appealing, and relate directly to the text. It should be in a standard meme format with clear, readable text overlay. The image should be 1080px x 1920px.
                """
            case .linkedin:
                imageInstruction = """
                Create a professional but humorous meme image for LinkedIn that complements the meme text about automotive repair. The image should be visually appealing, relate directly to the text, and maintain a professional appearance appropriate for LinkedIn. It should be in a standard meme format with clear, readable text overlay. The image should be 1200px x 627px.
                """
            }
        } else {
            imageInstruction = "Create a meme image related to automotive repair."
        }
    }
    
    // MARK: - Platform Handling
    
    /// Get the first active platform from the user settings
    func getFirstActivePlatform() -> PlatformType? {
        // Fetch all platforms
        let platformDescriptor = FetchDescriptor<SocialMediaPlatform>()
        
        do {
            let platforms = try modelContext.fetch(platformDescriptor)
            
            // Find the first active platform
            if let firstActive = platforms.first(where: { $0.isActive }) {
                return firstActive.type
            }
            
            return nil
        } catch {
            print("Error fetching platforms: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Generate meme text
    func generateMemeText(topicHeadline: String, topicSummary: String) {
        guard selectedPlatform != nil else {
            showError = true
            errorMessage = "Please select a platform first."
            return
        }
        
        isLoading = true
        
        // Create the prompt
        let prompt = """
        HEADLINE: \(topicHeadline)
        
        SUMMARY: \(topicSummary)
        
        INSTRUCTIONS: \(textInstruction)
        """
        
        // Call OpenAI service with the hashtags parameter
        openAIService.generateMeme(
            topic: prompt,
            hashtags: hashtags
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let (text, _)):
                    // We only need the text part for now
                    self.memeText = text
                case .failure(let error):
                    self.showError = true
                    self.errorMessage = error.description
                }
            }
        }
    }
    
    // Generate meme image
    func generateMemeImage(topicHeadline: String, topicSummary: String) {
        guard let platform = selectedPlatform else {
            showError = true
            errorMessage = "Please select a platform first."
            return
        }
        
        isLoading = true
        
        // Create the prompt
        let prompt = """
        HEADLINE: \(topicHeadline)
        
        SUMMARY: \(topicSummary)
        
        MEME TEXT: \(memeText)
        
        INSTRUCTIONS: \(imageInstruction)
        """
        
        // First generate the image prompt
        openAIService.generateImagePrompt(
            topic: prompt,
            platform: platform,
            postText: memeText,
            graphicGuidance: imageInstruction
        ) { [weak self] result in
            // Ensure UI updates happen on the main thread
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let imagePrompt):
                    self.imagePrompt = imagePrompt
                    
                    // Now generate the actual image
                    self.openAIService.generateImage(prompt: imagePrompt) { [weak self] imageResult in
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            
                            self.isLoading = false
                            
                            switch imageResult {
                            case .success(let image):
                                self.memeImage = image
                            case .failure(let error):
                                self.showError = true
                                self.errorMessage = error.description
                            }
                        }
                    }
                    
                case .failure(let error):
                    self.isLoading = false
                    self.showError = true
                    self.errorMessage = error.description
                }
            }
        }
    }
    
    // Reset all state
    func reset() {
        selectedPlatform = nil
        memeText = ""
        memeImage = nil
        imagePrompt = ""
        resetTextInstruction()
        resetImageInstruction()
    }
    
    // Dismiss error
    func dismissError() {
        showError = false
        errorMessage = ""
    }
}
