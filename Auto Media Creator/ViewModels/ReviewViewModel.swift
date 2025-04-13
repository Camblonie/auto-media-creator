import Foundation
import SwiftUI
import SwiftData
import Combine

class ReviewViewModel: ObservableObject {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let openAIService: OpenAIService
    private let socialMediaService: SocialMediaService
    
    // MARK: - Published Properties
    @Published var pendingPosts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var userFeedback = ""
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.openAIService = OpenAIService()
        self.socialMediaService = SocialMediaService(modelContext: modelContext)
        
        // Load user settings to get OpenAI API key
        loadUserSettings()
        
        // Load pending posts
        loadPendingPosts()
    }
    
    // MARK: - Data Loading
    private func loadUserSettings() {
        let fetchDescriptor = FetchDescriptor<UserSettings>()
        
        do {
            let settings = try modelContext.fetch(fetchDescriptor)
            if let settings = settings.first, !settings.openAIApiKey.isEmpty {
                openAIService.setAPIKey(settings.openAIApiKey)
            }
        } catch {
            errorMessage = "Failed to load user settings: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func loadPendingPosts() {
        let pendingStatuses = [
            ReviewStatus.pendingTextReview.rawValue,
            ReviewStatus.pendingGraphicReview.rawValue,
            ReviewStatus.pendingMemeReview.rawValue
        ]
        
        let fetchDescriptor = FetchDescriptor<Post>(
            predicate: #Predicate {
                pendingStatuses.contains($0.reviewStatus.rawValue)
            },
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        
        do {
            pendingPosts = try modelContext.fetch(fetchDescriptor)
            print("Found \(pendingPosts.count) pending posts for review")
            
            // Print details of found posts for debugging
            for (index, post) in pendingPosts.enumerated() {
                print("Post \(index + 1): Type: \(post.postType.rawValue), Platform: \(post.platformType.rawValue), Status: \(post.reviewStatus.rawValue)")
            }
            
        } catch {
            errorMessage = "Failed to load pending posts: \(error.localizedDescription)"
            showError = true
            print("Error loading pending posts: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Post Management
    func getPost(id: UUID) -> Post? {
        return pendingPosts.first { $0.id == id }
    }
    
    // MARK: - Review Actions
    func approveTextContent(post: Post) {
        isLoading = true
        
        // Update post status
        post.approveText()
        
        // Generate image prompt based on the approved text
        // Check if we have OpenAI API key configured
        let fetchDescriptor = FetchDescriptor<UserSettings>()
        guard let _ = try? modelContext.fetch(fetchDescriptor).first else {
            isLoading = false
            return
        }
        
        // Use a more compatible approach for finding the platform
        let platformDescriptor = FetchDescriptor<SocialMediaPlatform>()
        guard let platforms = try? modelContext.fetch(platformDescriptor),
              let platform = platforms.first(where: { $0.type.rawValue == post.platformType.rawValue }) else {
            isLoading = false
            return
        }
        
        // Generate image prompt
        openAIService.generateImagePrompt(
            topic: post.userInputPrompt,
            platform: post.platformType,
            postText: post.textContent,
            graphicGuidance: platform.graphicGuidance
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let imagePrompt):
                    post.imagePrompt = imagePrompt
                    
                    // Generate the actual image
                    self.generateImage(for: post)
                    
                case .failure(let error):
                    self.isLoading = false
                    post.recordError(error.description)
                    try? self.modelContext.save()
                    
                    self.errorMessage = "Failed to generate image prompt: \(error.description)"
                    self.showError = true
                }
            }
        }
    }
    
    func generateImage(for post: Post) {
        guard !post.imagePrompt.isEmpty else {
            isLoading = false
            errorMessage = "No image prompt available"
            showError = true
            return
        }
        
        // Generate image from prompt
        openAIService.generateImage(prompt: post.imagePrompt) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let image):
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        post.setImage(imageData)
                        try? self.modelContext.save()
                        self.loadPendingPosts()
                    } else {
                        post.recordError("Failed to convert image to data")
                        try? self.modelContext.save()
                        
                        self.errorMessage = "Failed to process generated image"
                        self.showError = true
                    }
                    
                case .failure(let error):
                    post.recordError(error.description)
                    try? self.modelContext.save()
                    
                    self.errorMessage = "Failed to generate image: \(error.description)"
                    self.showError = true
                }
            }
        }
    }
    
    func approveMeme(post: Post) {
        isLoading = true
        
        // Generate image from image prompt
        openAIService.generateImage(prompt: post.imagePrompt) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let image):
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        post.setImage(imageData)
                        post.approve()
                        try? self.modelContext.save()
                        self.loadPendingPosts()
                    } else {
                        post.recordError("Failed to convert image to data")
                        try? self.modelContext.save()
                        
                        self.errorMessage = "Failed to process generated image"
                        self.showError = true
                    }
                    
                case .failure(let error):
                    post.recordError(error.description)
                    try? self.modelContext.save()
                    
                    self.errorMessage = "Failed to generate meme image: \(error.description)"
                    self.showError = true
                }
            }
        }
    }
    
    func approveGraphic(post: Post) {
        post.approve()
        try? modelContext.save()
        loadPendingPosts()
    }
    
    func rejectPost(post: Post) {
        post.reject()
        try? modelContext.save()
        loadPendingPosts()
    }
    
    func postToSocialMedia(post: Post) {
        isLoading = true
        
        socialMediaService.postContent(post: post) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let _):
                    // Successfully posted
                    self.loadPendingPosts()
                    
                case .failure(let error):
                    self.errorMessage = "Failed to post content: \(error.description)"
                    self.showError = true
                }
            }
        }
    }
    
    // MARK: - Apply User Feedback
    func applyFeedback(post: Post) {
        guard !userFeedback.isEmpty else {
            errorMessage = "Please provide feedback before submitting"
            showError = true
            return
        }
        
        isLoading = true
        post.updateWithFeedback(userFeedback)
        
        // Process different types of revisions based on the post type and status
        switch (post.postType, post.reviewStatus) {
        case (.traditional, .pendingTextReview):
            revisePostText(post: post)
            
        case (.traditional, .pendingGraphicReview):
            reviseImagePrompt(post: post)
            
        case (.meme, .pendingMemeReview):
            reviseMeme(post: post)
            
        default:
            isLoading = false
            errorMessage = "Cannot process feedback for this post status"
            showError = true
        }
    }
    
    private func revisePostText(post: Post) {
        openAIService.processUserFeedback(originalContent: post.textContent, userFeedback: userFeedback) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.userFeedback = ""
                
                switch result {
                case .success(let revisedContent):
                    post.textContent = revisedContent
                    try? self.modelContext.save()
                    
                case .failure(let error):
                    self.errorMessage = "Failed to revise post: \(error.description)"
                    self.showError = true
                }
            }
        }
    }
    
    private func reviseImagePrompt(post: Post) {
        openAIService.processUserFeedback(originalContent: post.imagePrompt, userFeedback: userFeedback) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let revisedPrompt):
                    post.imagePrompt = revisedPrompt
                    try? self.modelContext.save()
                    
                    // Generate new image with revised prompt
                    self.generateImage(for: post)
                    self.userFeedback = ""
                    
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = "Failed to revise image prompt: \(error.description)"
                    self.showError = true
                }
            }
        }
    }
    
    private func reviseMeme(post: Post) {
        openAIService.generateMeme(topic: post.userInputPrompt + " " + userFeedback, hashtags: "") { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.userFeedback = ""
                
                switch result {
                case .success(let (caption, imagePrompt)):
                    post.textContent = caption
                    post.imagePrompt = imagePrompt
                    try? self.modelContext.save()
                    
                case .failure(let error):
                    self.errorMessage = "Failed to revise meme: \(error.description)"
                    self.showError = true
                }
            }
        }
    }
    
    // MARK: - Error Handling
    func dismissError() {
        errorMessage = nil
        showError = false
    }
}
