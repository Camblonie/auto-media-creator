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
    func createTraditionalPost() {
        guard let settings = self.settings, !settings.openAIApiKey.isEmpty else {
            errorMessage = "OpenAI API key is not set. Please update your settings."
            showError = true
            return
        }
        
        let activePlatforms = getActivePlatforms()
        if activePlatforms.isEmpty {
            errorMessage = "Please select at least one social media platform."
            showError = true
            return
        }
        
        isLoading = true
        
        // Create post group
        let topic = traditionalPostInput.isEmpty ? "general automotive repair and maintenance" : traditionalPostInput
        let postGroup = PostGroup(userInputPrompt: topic, postType: .traditional, topic: topic)
        modelContext.insert(postGroup)
        
        // Research the topic
        openAIService.researchTopic(topic: topic) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let researchContent):
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
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to research topic: \(error.description)"
                    self.showError = true
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
    
    func createMemePost() {
        guard let settings = self.settings, !settings.openAIApiKey.isEmpty else {
            errorMessage = "OpenAI API key is not set. Please update your settings."
            showError = true
            return
        }
        
        let activePlatforms = getActivePlatforms()
        if activePlatforms.isEmpty {
            errorMessage = "Please select at least one social media platform."
            showError = true
            return
        }
        
        isLoading = true
        
        // Create post group
        let topic = memePostInput.isEmpty ? "automotive humor" : memePostInput
        let postGroup = PostGroup(userInputPrompt: topic, postType: .meme, topic: topic)
        modelContext.insert(postGroup)
        
        // Generate meme for each active platform
        for platform in activePlatforms {
            // Create post object
            let post = Post(postType: .meme, 
                           userInputPrompt: topic, 
                           platformType: platform.type)
            
            self.modelContext.insert(post)
            postGroup.addPost(post)
            
            // Generate meme content
            openAIService.generateMeme(topic: topic, hashtags: settings.defaultTags) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let (caption, imagePrompt)):
                    DispatchQueue.main.async {
                        post.textContent = caption
                        post.imagePrompt = imagePrompt
                        // Ensure proper saving with explicit error handling
                        do {
                            try self.modelContext.save()
                            print("Meme content saved for \(platform.type.rawValue)")
                        } catch {
                            print("Error saving meme content: \(error.localizedDescription)")
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
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.memePostInput = ""
            // Ensure proper saving of post group with error handling
            do {
                try self.modelContext.save()
                print("Meme post group created with \(postGroup.posts.count) posts")
            } catch {
                self.errorMessage = "Failed to save meme posts: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    // MARK: - Error Handling
    func dismissError() {
        errorMessage = nil
        showError = false
    }
}
