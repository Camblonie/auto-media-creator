import Foundation
import SwiftUI
import SwiftData
import Combine

class MainViewModel: ObservableObject {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let socialMediaService: SocialMediaService
    
    // MARK: - Published Properties
    @Published var platforms: [SocialMediaPlatform] = []
    @Published var settings: UserSettings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showDraftCreatedAlert = false
    
    // Topic data
    @Published var currentTopic: ResearchContent?
    
    // User input
    @Published var traditionalPostInput = ""
    @Published var memePostInput = ""
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.socialMediaService = SocialMediaService(modelContext: modelContext)
        
        // Check for UserSettings
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(settingsDescriptor).first {
            self.settings = settings
        } else {
            // Create default settings if none exist
            createDefaultSettings()
        }
        
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
        loadLatestTopic()
    }
    
    private func loadUserSettings() {
        let fetchDescriptor = FetchDescriptor<UserSettings>()
        
        do {
            let settings = try modelContext.fetch(fetchDescriptor)
            if let settings = settings.first {
                self.settings = settings
            } else {
                // Create default settings if none exist
                createDefaultSettings()
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
    
    private func loadLatestTopic() {
        // Fetch the latest topic from ResearchContent
        let fetchDescriptor = FetchDescriptor<ResearchContent>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        // Set fetch limit using a separate statement
        var descriptor = fetchDescriptor
        descriptor.fetchLimit = 1
        
        do {
            let topics = try modelContext.fetch(descriptor)
            if let latestTopic = topics.first {
                self.currentTopic = latestTopic
                print("Loaded latest topic: \(latestTopic.headline)")
            }
        } catch {
            print("Failed to load latest topic: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Platform Management
    
    func togglePlatform(_ platform: SocialMediaPlatform) {
        // If we're activating a platform, deactivate all others first
        if !platform.isActive {
            // Deactivate all platforms
            for p in platforms {
                p.isActive = false
            }
        }
        
        // Toggle the selected platform
        platform.isActive = !platform.isActive
        
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
    
    // MARK: - Topic Management
    
    func setCurrentTopic(_ topic: ResearchContent) {
        self.currentTopic = topic
    }
    
    // MARK: - Error Handling
    func dismissError() {
        errorMessage = nil
        showError = false
    }
    
    private func createDefaultSettings() {
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        self.settings = newSettings
        print("Created default user settings")
    }
}
