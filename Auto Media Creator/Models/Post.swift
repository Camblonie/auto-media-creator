import Foundation
import SwiftData
import SwiftUI

// Post type enum
enum PostType: String, Codable {
    case traditional = "Traditional"
    case meme = "Meme"
}

// Review status enum
enum ReviewStatus: String, Codable {
    case pendingTextReview = "Pending Text Review"
    case pendingGraphicReview = "Pending Graphic Review" 
    case pendingMemeReview = "Pending Meme Review"
    case approved = "Approved"
    case rejected = "Rejected"
    case posted = "Posted"
}

// Main model for a social media post
@Model
final class Post {
    // Basic properties
    var id: UUID
    var creationDate: Date
    var postType: PostType
    var userInputPrompt: String
    var platformType: PlatformType
    var reviewStatus: ReviewStatus
    
    // Content
    var textContent: String
    var imagePrompt: String
    var imageData: Data?
    var userFeedback: String?
    
    // Post status
    var postDate: Date?
    var postUrl: String?
    var errorMessage: String?
    
    // For memes, we combine text and image together
    var isMeme: Bool {
        return postType == .meme
    }
    
    // Initialize a new post
    init(postType: PostType, 
         userInputPrompt: String,
         platformType: PlatformType, 
         textContent: String = "",
         imagePrompt: String = "") {
        self.id = UUID()
        self.creationDate = Date()
        self.postType = postType
        self.userInputPrompt = userInputPrompt
        self.platformType = platformType
        self.textContent = textContent
        self.imagePrompt = imagePrompt
        
        // Set initial review status based on post type
        if postType == .traditional {
            self.reviewStatus = .pendingTextReview
        } else {
            self.reviewStatus = .pendingMemeReview
        }
    }
    
    // Update review status after text approval
    func approveText() {
        if postType == .traditional {
            reviewStatus = .pendingGraphicReview
        }
    }
    
    // Update with user feedback
    func updateWithFeedback(_ feedback: String) {
        self.userFeedback = feedback
    }
    
    // Set image data
    func setImage(_ imageData: Data) {
        self.imageData = imageData
    }
    
    // Mark as approved
    func approve() {
        reviewStatus = .approved
    }
    
    // Mark as rejected
    func reject() {
        reviewStatus = .rejected
    }
    
    // Mark as posted
    func markAsPosted(url: String?) {
        reviewStatus = .posted
        postDate = Date()
        postUrl = url
    }
    
    // Record an error
    func recordError(_ message: String) {
        errorMessage = message
    }
}

// A group of posts created together across multiple platforms
@Model
final class PostGroup {
    var id: UUID
    var creationDate: Date
    var userInputPrompt: String
    var postType: PostType
    var topic: String
    @Relationship(deleteRule: .cascade) var posts: [Post] = []
    
    init(userInputPrompt: String, postType: PostType, topic: String = "") {
        self.id = UUID()
        self.creationDate = Date()
        self.userInputPrompt = userInputPrompt
        self.postType = postType
        self.topic = topic
    }
    
    func addPost(_ post: Post) {
        posts.append(post)
    }
}
