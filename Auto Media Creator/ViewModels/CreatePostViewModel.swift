import Foundation
import SwiftUI
import SwiftData
import Combine

class CreatePostViewModel: ObservableObject {
    // Services
    private let openAIService: OpenAIService
    private let modelContext: ModelContext
    
    // Published properties
    @Published var selectedPlatform: PlatformType?
    @Published var textInstruction: String = ""
    @Published var imageInstruction: String = ""
    @Published var generatedText: String = ""
    @Published var imagePrompt: String = ""
    @Published var generatedImage: UIImage?
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
                Using the provided HEADLINE and SUMMARY write a high-engagement Facebook post designed to grab attention and spark conversation. The post should be concise, compelling, and easy to skim. Avoid fluff and get straight to the point. The tone should be confident, conversational, and informative. Stay on topic.
                Start with a bold statement, surprising fact, or direct question. No soft intros.
                Provide value immediately. This could be a list, insight, or key takeaway.
                Keep it practical and actionable. Readers should walk away with something useful.
                Make it feel relevant and current. Tie it to trends, industry shifts, or real-world applications.
                Encourage discussion naturally. End with an open-ended question.
                If appropriate, use emojis sparingly for emphasis (e.g., 🚀🔥🙌).
                """
            case .instagram:
                textInstruction = """
                Using the provided HEADLINE and SUMMARY write an engaging Instagram caption that grabs attention, feels natural, and encourages likes, shares, and comments. The caption should match Instagram's best-performing styles: short, fun, and direct (for reels/carousels) or story-driven and relatable (for longer captions).Key Elements for Instagram Success:
                -A strong hook (first line must grab attention!) -Conversational, like texting a friend—no robotic/formal writing.
                -Brevity—keep it short, snappy, and engaging. -If longer, structure it as a micro-story with a punchline. -Clear CTA—comments, DMs, tags, or actions.
                """
            case .twitter:
                textInstruction = """
                Using the provided HEADLINE and SUMMARY write an engaging tweet for X. You do not have to summarize the entire article
                """
            case .tiktok:
                textInstruction = """
                Using the provided HEADLINE and SUMMARY write an engaging TikTok caption that grabs attention, feels natural, and encourages likes, shares, and comments. The caption should match TikTok's best-performing styles: short, fun, and direct (for reels/carousels) or story-driven and relatable (for longer captions).Key Elements for TikTok Success:
                -A strong hook (first line must grab attention!) -Conversational, like texting a friend—no robotic/formal writing.
                -Brevity—keep it short, snappy, and engaging. -If longer, structure it as a micro-story with a punchline. -Clear CTA—comments, DMs, tags, or actions.
                """
            case .linkedin:
                textInstruction = """
                Using the provided HEADLINE and SUMMARY write a professional LinkedIn post about automotive repair that provides value and industry insights. Use a more formal tone while maintaining readability and engagement. Add relevant industry hashtags.
                """
            }
        } else {
            textInstruction = "Write a social media post based on the provided headline and summary."
        }
    }
    
    // Reset image instruction to default
    func resetImageInstruction() {
        if let platform = selectedPlatform {
            switch platform {
            case .facebook:
                imageInstruction = "Using the Facebook post generated created, write a high converting image prompt and generate the image using DALL-E 3. Graphic should be 1200px x 1200px."
            case .instagram:
                imageInstruction = "Using the instagram caption created, write a high converting image prompt and generate the image using DALL-E 3. Graphic should be 1080px x 1080px."
            case .twitter:
                imageInstruction = "Using the tweet created, write a high converting image prompt and generate the image using DALL-E 3. Graphic should be 1080px x 1080px."
            case .tiktok:
                imageInstruction = "Using the TikTok caption created, write a high converting image prompt and generate the image using DALL-E 3. Graphic should be 1080px x 1080px."
            case .linkedin:
                imageInstruction = "Using the LinkedIn post created, write a high converting image prompt and generate the image using DALL-E 3. Graphic should be 1200px x 628px."
            }
        } else {
            imageInstruction = "Create an engaging image related to the post content."
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
    
    // Generate post text
    func generatePostText(topicHeadline: String, topicSummary: String) {
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
        
        INSTRUCTIONS: \(textInstruction)
        """
        
        // Call OpenAI service
        openAIService.generateSocialPost(
            topic: prompt,
            platform: platform,
            promptGuidance: textInstruction,
            hashtags: hashtags
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let text):
                    self?.generatedText = text
                case .failure(let error):
                    self?.showError = true
                    self?.errorMessage = error.description
                }
            }
        }
    }
    
    // Generate image
    func generateImage(topicHeadline: String, topicSummary: String) {
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
        
        POST TEXT: \(generatedText)
        
        INSTRUCTIONS: \(imageInstruction)
        """
        
        // First generate the image prompt
        openAIService.generateImagePrompt(
            topic: prompt,
            platform: platform,
            postText: generatedText,
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
                                self.generatedImage = image
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
        generatedText = ""
        generatedImage = nil
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
