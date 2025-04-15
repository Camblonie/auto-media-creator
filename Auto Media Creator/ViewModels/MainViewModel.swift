import Foundation
import SwiftUI
import SwiftData
import Combine

class MainViewModel: ObservableObject {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let openAIService: OpenAIService
    private let socialMediaService: SocialMediaService
    
    // MARK: - Published Properties
    @Published var platforms: [SocialMediaPlatform] = []
    @Published var settings: UserSettings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // User input
    @Published var traditionalPostInput = ""
    @Published var memePostInput = ""
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Check for UserSettings
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(settingsDescriptor).first {
            self.settings = settings
            // Initialize OpenAI service with saved API key
            if !settings.openAIApiKey.isEmpty {
                self.openAIService = OpenAIService()
                self.openAIService.setAPIKey(settings.openAIApiKey)
                print("OpenAI service initialized with stored API key")
            } else {
                self.openAIService = OpenAIService()
                print("No OpenAI API key found in settings")
            }
        } else {
            // Create default settings if none exist
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            self.settings = newSettings
            self.openAIService = OpenAIService()
            print("Created default user settings")
        }
        
        self.socialMediaService = SocialMediaService(modelContext: modelContext)
        
        // Initialize available platforms
        for platformType in PlatformType.allCases {
            platforms.append(SocialMediaPlatform(type: platformType))
        }
        
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        loadUserSettings()
        loadPlatforms()
    }
    
    private func loadUserSettings() {
        let fetchDescriptor = FetchDescriptor<UserSettings>()
        
        do {
            let settings = try modelContext.fetch(fetchDescriptor)
            if let settings = settings.first {
                self.settings = settings
                
                // Set OpenAI API key if available
                if !settings.openAIApiKey.isEmpty {
                    openAIService.setAPIKey(settings.openAIApiKey)
                }
            } else {
                // Create default settings if none exist
                let newSettings = UserSettings()
                modelContext.insert(newSettings)
                self.settings = newSettings
                try modelContext.save()
            }
        } catch {
            errorMessage = "Failed to load user settings: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func loadPlatforms() {
        let fetchDescriptor = FetchDescriptor<SocialMediaPlatform>()
        
        do {
            let existingPlatforms = try modelContext.fetch(fetchDescriptor)
            
            if existingPlatforms.isEmpty {
                // Create default platform instances if none exist
                for platformType in PlatformType.allCases {
                    let platform = SocialMediaPlatform(type: platformType)
                    modelContext.insert(platform)
                }
                try modelContext.save()
                
                // Fetch again to get the newly created platforms
                platforms = try modelContext.fetch(fetchDescriptor)
            } else {
                platforms = existingPlatforms
            }
        } catch {
            errorMessage = "Failed to load platforms: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Platform Management
    func updatePlatformStatus(platform: SocialMediaPlatform, isActive: Bool) {
        platform.isActive = isActive
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update platform status: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func getActivePlatforms() -> [SocialMediaPlatform] {
        return platforms.filter { $0.isActive }
    }
    
    // MARK: - Content Generation
    func createTraditionalPost(activePlatforms: [SocialMediaPlatform]) {
        guard !activePlatforms.isEmpty else {
            errorMessage = "Please select at least one platform"
            showError = true
            return
        }
        
        isLoading = true
        
        // Reset retry counter whenever starting a new request
        resetRetryCounter()
        
        // Create post group
        let topic = traditionalPostInput.isEmpty ? "general automotive repair and maintenance" : traditionalPostInput
        let postGroup = PostGroup(userInputPrompt: topic, postType: .traditional, topic: topic)
        modelContext.insert(postGroup)
        
        // Research the topic
        performResearchTopic(topic: topic, postGroup: postGroup, activePlatforms: activePlatforms)
    }
    
    private func performResearchTopic(topic: String, postGroup: PostGroup, activePlatforms: [SocialMediaPlatform]) {
        openAIService.researchTopic(topic: topic) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let researchContent):
                // Reset retry counter on success
                self.resetRetryCounter()
                
                // Create posts for each active platform
                for platform in activePlatforms {
                    let post = Post(postType: .traditional, 
                                   userInputPrompt: topic, 
                                   platformType: platform.type)
                    
                    self.modelContext.insert(post)
                    postGroup.addPost(post)
                    
                    // Generate platform-specific content
                    self.generatePostContent(post: post, 
                                           platform: platform, 
                                           research: researchContent)
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.traditionalPostInput = ""
                    
                    // Ensure posts are saved properly
                    do {
                        try self.modelContext.save()
                        // Explicitly log post creation for debugging
                        print("Created \(postGroup.posts.count) posts successfully")
                    } catch {
                        self.errorMessage = "Failed to save posts: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
                
            case .failure(let error):
                // Handle rate limit errors with exponential backoff
                if case .rateLimitExceeded = error {
                    self.handleRateLimit {
                        // Retry the research topic request
                        self.performResearchTopic(topic: topic, postGroup: postGroup, activePlatforms: activePlatforms)
                    }
                } else {
                    // Handle other errors
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to research topic: \(error.description)"
                        self.showError = true
                    }
                }
            }
        }
    }
    
    private func generatePostContent(post: Post, platform: SocialMediaPlatform, research: String) {
        guard let settings = self.settings else { return }
        
        openAIService.generateSocialPost(
            topic: research,
            platform: platform.type,
            promptGuidance: platform.promptGuidance,
            hashtags: settings.defaultTags) { [weak self] result in
                
                guard let self = self else { return }
                
                switch result {
                case .success(let content):
                    DispatchQueue.main.async {
                        post.textContent = content
                        // Ensure proper saving with error handling
                        do {
                            try self.modelContext.save()
                            print("Post content saved for \(platform.type.rawValue): \(content.prefix(30))...")
                        } catch {
                            print("Error saving post content: \(error.localizedDescription)")
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        post.recordError(error.description)
                        try? self.modelContext.save()
                    }
                }
            }
    }
    
    func createMemePost(activePlatforms: [SocialMediaPlatform]) {
        guard !activePlatforms.isEmpty else {
            errorMessage = "Please select at least one platform"
            showError = true
            return
        }
        
        isLoading = true
        
        // Reset retry counter whenever starting a new request
        resetRetryCounter()
        
        // Create post group for meme
        let topic = memePostInput.isEmpty ? "automotive meme" : memePostInput
        let postGroup = PostGroup(userInputPrompt: topic, postType: .meme, topic: topic)
        modelContext.insert(postGroup)
        
        // Generate meme content
        performGenerateMeme(topic: topic, postGroup: postGroup, activePlatforms: activePlatforms)
    }
    
    private func performGenerateMeme(topic: String, postGroup: PostGroup, activePlatforms: [SocialMediaPlatform]) {
        guard let settings = self.settings else { return }
        
        openAIService.generateMeme(topic: topic, hashtags: settings.defaultTags) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let memeContent):
                // Reset retry counter on success
                self.resetRetryCounter()
                
                let (memeText, memeImagePrompt) = memeContent
                
                // Create a post for each platform
                for platform in activePlatforms {
                    let post = Post(postType: .meme,
                                   userInputPrompt: topic,
                                   platformType: platform.type)
                    
                    // Set content directly for meme
                    post.textContent = memeText
                    post.imagePrompt = memeImagePrompt
                    post.reviewStatus = .pendingMemeReview
                    
                    self.modelContext.insert(post)
                    postGroup.addPost(post)
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.memePostInput = ""
                    
                    // Save posts
                    do {
                        try self.modelContext.save()
                        print("Created \(postGroup.posts.count) meme posts successfully")
                    } catch {
                        self.errorMessage = "Failed to save meme posts: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
                
            case .failure(let error):
                // Handle rate limit errors with exponential backoff
                if case .rateLimitExceeded = error {
                    self.handleRateLimit {
                        // Retry the meme generation
                        self.performGenerateMeme(topic: topic, postGroup: postGroup, activePlatforms: activePlatforms)
                    }
                } else {
                    // Handle other errors
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to generate meme: \(error.description)"
                        self.showError = true
                    }
                }
            }
        }
    }
    
    // MARK: - OpenAI Rate Limit Handling
    
    // Retry parameters
    private var maxRetryAttempts = 3
    private var currentRetryAttempt = 0
    private var retryTimer: Timer?
    
    // Handle rate limit with exponential backoff
    private func handleRateLimit(retryAction: @escaping () -> Void) {
        // Clear any existing retry timer
        retryTimer?.invalidate()
        
        // Check if we've exceeded max retries
        if currentRetryAttempt >= maxRetryAttempts {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "OpenAI rate limit exceeded. Please try again later."
                self.showError = true
                self.currentRetryAttempt = 0
            }
            return
        }
        
        // Increment retry attempt
        currentRetryAttempt += 1
        
        // Calculate backoff time (exponential: 2^attempt seconds)
        let backoffSeconds = pow(2.0, Double(currentRetryAttempt))
        
        // Show user-friendly message
        DispatchQueue.main.async {
            self.errorMessage = "Rate limit exceeded. Retrying in \(Int(backoffSeconds)) seconds... (Attempt \(self.currentRetryAttempt)/\(self.maxRetryAttempts))"
            self.showError = true
        }
        
        // Schedule retry
        retryTimer = Timer.scheduledTimer(withTimeInterval: backoffSeconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Update UI to show we're retrying
            DispatchQueue.main.async {
                self.errorMessage = "Retrying request..."
                self.showError = true
            }
            
            // Execute the retry action
            retryAction()
        }
    }
    
    // Reset retry counter
    private func resetRetryCounter() {
        currentRetryAttempt = 0
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    // MARK: - Error Handling
    func dismissError() {
        errorMessage = nil
        showError = false
    }
}
