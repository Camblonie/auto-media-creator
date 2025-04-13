import Foundation
import UIKit
import SwiftData

// Error types for social media service
enum SocialMediaServiceError: Error {
    case notAuthenticated
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case noContent
    case unexpectedError(String)
    
    var description: String {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in to your account."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .apiError(let message):
            return "API error: \(message)"
        case .noContent:
            return "No content was returned."
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        }
    }
}

// Protocol for platform-specific implementations
protocol SocialMediaPlatformService {
    func authenticate(username: String, password: String, completion: @escaping (Result<String, SocialMediaServiceError>) -> Void)
    func checkAuthStatus(token: String, completion: @escaping (Bool) -> Void)
    func post(text: String, image: UIImage?, token: String, completion: @escaping (Result<String, SocialMediaServiceError>) -> Void)
}

// Main service for social media interactions
class SocialMediaService {
    // MARK: - Properties
    private var modelContext: ModelContext
    
    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Authentication
    func authenticatePlatform(platform: SocialMediaPlatform, username: String, password: String, completion: @escaping (Result<Void, SocialMediaServiceError>) -> Void) {
        // Get platform-specific service
        let platformService = getPlatformService(for: platform.type)
        
        // Call authenticate method
        platformService.authenticate(username: username, password: password) { result in
            switch result {
            case .success(let token):
                // Update platform with token and authentication status
                platform.username = username
                platform.authToken = token
                platform.isAuthenticated = true
                
                // Save changes to model context
                do {
                    try self.modelContext.save()
                    completion(.success(()))
                } catch {
                    completion(.failure(.unexpectedError("Failed to save authentication status: \(error.localizedDescription)")))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Check Authentication Status
    func checkAuthenticationStatus(platform: SocialMediaPlatform, completion: @escaping (Bool) -> Void) {
        // Check if we have a token
        guard let token = platform.authToken else {
            platform.isAuthenticated = false
            try? modelContext.save()
            completion(false)
            return
        }
        
        // Get platform-specific service
        let platformService = getPlatformService(for: platform.type)
        
        // Check authentication status
        platformService.checkAuthStatus(token: token) { isAuthenticated in
            // Update platform authentication status
            platform.isAuthenticated = isAuthenticated
            try? self.modelContext.save()
            completion(isAuthenticated)
        }
    }
    
    // MARK: - Post Content
    func postContent(post: Post, completion: @escaping (Result<String, SocialMediaServiceError>) -> Void) {
        // Get the platform
        let platformType = post.platformType
        
        // Use a simpler approach that avoids predicate macros with enums
        let platformDescriptor = FetchDescriptor<SocialMediaPlatform>()
        guard let platforms = try? modelContext.fetch(platformDescriptor),
              let platform = platforms.first(where: { $0.type.rawValue == platformType.rawValue }) else {
            completion(.failure(.unexpectedError("Platform not found")))
            return
        }
        
        // Check if authenticated
        guard platform.isAuthenticated, let token = platform.authToken else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        // Get image if available
        var image: UIImage? = nil
        if let imageData = post.imageData {
            image = UIImage(data: imageData)
        }
        
        // Get platform-specific service
        let platformService = getPlatformService(for: platformType)
        
        // Post content
        platformService.post(text: post.textContent, image: image, token: token) { result in
            switch result {
            case .success(let postUrl):
                // Update post with URL and mark as posted
                post.markAsPosted(url: postUrl)
                
                // Update platform statistics
                platform.recordPost()
                
                // Save changes to model context
                do {
                    try self.modelContext.save()
                    completion(.success(postUrl))
                } catch {
                    completion(.failure(.unexpectedError("Failed to save post status: \(error.localizedDescription)")))
                }
                
            case .failure(let error):
                // Record error
                post.recordError(error.description)
                try? self.modelContext.save()
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getPlatformService(for platformType: PlatformType) -> SocialMediaPlatformService {
        // In a real app, we would return different implementations for each platform
        // For this demo, we'll use a mock implementation that simulates successful operations
        return MockSocialMediaPlatformService(platformType: platformType)
    }
}

// MARK: - Mock Implementation (for simulation)
class MockSocialMediaPlatformService: SocialMediaPlatformService {
    private let platformType: PlatformType
    
    init(platformType: PlatformType) {
        self.platformType = platformType
    }
    
    func authenticate(username: String, password: String, completion: @escaping (Result<String, SocialMediaServiceError>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // For demo purposes, always succeed with a mock token
            // In a real app, this would make an actual API call
            let mockToken = "mock_token_\(self.platformType)_\(UUID().uuidString)"
            completion(.success(mockToken))
        }
    }
    
    func checkAuthStatus(token: String, completion: @escaping (Bool) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // For demo purposes, check if token contains the platform name
            // In a real app, this would verify the token with the platform's API
            let isValid = token.contains(self.platformType.rawValue.lowercased())
            completion(isValid)
        }
    }
    
    func post(text: String, image: UIImage?, token: String, completion: @escaping (Result<String, SocialMediaServiceError>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // For demo purposes, always succeed with a mock post URL
            // In a real app, this would make an actual API call to post the content
            let mockPostUrl = "https://\(self.platformType.rawValue.lowercased()).com/post/\(UUID().uuidString)"
            completion(.success(mockPostUrl))
        }
    }
}
