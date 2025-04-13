import Foundation
import SwiftData

// Defines the supported social media platforms
enum PlatformType: String, Codable, CaseIterable {
    case facebook = "Facebook"
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case twitter = "X" // X (formerly Twitter)
    case linkedin = "LinkedIn"
    
    var icon: String {
        switch self {
        case .facebook:
            return "f.square.fill"
        case .instagram:
            return "camera.fill"
        case .tiktok:
            return "music.note"
        case .twitter:
            return "x.square.fill"
        case .linkedin:
            return "linkedin"
        }
    }
    
    var defaultPromptGuidance: String {
        switch self {
        case .facebook:
            return """
            Write a high-engagement Facebook post designed to grab attention and spark conversation. The post should be concise, compelling, and easy to skim. Avoid fluff and get straight to the point. The tone should be confident, conversational, and informative.
            Instructions for AI:
            Start with a bold statement, surprising fact, or direct question. No soft intros.
            Provide value immediately. This could be a list, insight, or key takeaway.
            Keep it practical and actionable. Readers should walk away with something useful.
            Make it feel relevant and current. Tie it to trends, industry shifts, or real-world applications.
            Encourage discussion naturally. End with an open-ended question, not just a generic CTA.
            Tone & Style:
            Conversational and natural, as if speaking to a friend.
            Use contractions and avoid overly formal language.
            Keep sentences concise and easy to read.
            If appropriate, use emojis sparingly for emphasis (e.g., 🚀🔥🙌).
            """
        case .instagram:
            return """
            You are a skilled Instagram content strategist. Your goal is to write an engaging Instagram caption that grabs attention, feels natural, and encourages likes, shares, and comments. The caption should match Instagram's best-performing styles: short, fun, and direct (for reels/carousels) or story-driven and relatable (for longer captions).
            Key Elements for Success:
            ✅ A strong hook (first line must grab attention!) ✅ Conversational, like texting a friend—no robotic/formal writing. ✅ Brevity—keep it short, snappy, and engaging. ✅ If longer, structure it as a micro-story with a punchline. ✅ Clear CTA—comments, DMs, tags, or actions.
            Best-Performing Instagram Caption Styles & Examples
            1️⃣ Punchy & Fun (For Reels & Carousels)
            These captions are quick, witty, and spark engagement.
            2️⃣ Relatable & Conversational (For Personal Branding)
            More storytelling, personal insights, and engagement-driven.
            """
        case .tiktok:
            return "Create a short, engaging TikTok caption that's catchy and relevant to automotive repair. Include trending hashtags and keep it under 150 characters."
        case .twitter:
            return "Create a concise, engaging post for X (Twitter) about automotive repair that fits within character limits. Use hashtags strategically and include a clear call to action."
        case .linkedin:
            return "Create a professional LinkedIn post about automotive repair that provides value and industry insights. Use a more formal tone while maintaining readability and engagement. Add relevant industry hashtags."
        }
    }
    
    var graphicPromptGuidance: String {
        switch self {
        case .facebook, .instagram:
            return """
            Using the summary of the article created, write a high converting image prompt and generate the image using DALL-E 3.
            Graphic should be 1080px x 1080px
            """
        case .tiktok:
            return """
            Create a vertical format (9:16) eye-catching image related to automotive repair that would work well on TikTok. Make it vibrant and attention-grabbing.
            """
        case .twitter:
            return """
            Create a clear, high-impact image for X (Twitter) with a 16:9 ratio that conveys the post message at a glance.
            """
        case .linkedin:
            return """
            Create a professional, polished image for LinkedIn that conveys automotive expertise and professionalism. Use a 1200x628px ratio.
            """
        }
    }
}

// Main model for social media platform configuration
@Model
final class SocialMediaPlatform {
    // Basic properties
    var type: PlatformType
    var isActive: Bool
    var isAuthenticated: Bool
    
    // Authentication info (would use Keychain in production)
    var username: String?
    var authToken: String?
    
    // Customization
    var customPromptGuidance: String
    var customGraphicPromptGuidance: String
    
    // For statistics
    var postCount: Int
    var lastPostDate: Date?
    
    init(type: PlatformType, 
         isActive: Bool = false,
         isAuthenticated: Bool = false,
         username: String? = nil,
         authToken: String? = nil) {
        self.type = type
        self.isActive = isActive
        self.isAuthenticated = isAuthenticated
        self.username = username
        self.authToken = authToken
        self.customPromptGuidance = type.defaultPromptGuidance
        self.customGraphicPromptGuidance = type.graphicPromptGuidance
        self.postCount = 0
    }
    
    // Returns the appropriate prompt guidance (custom if set, otherwise default)
    var promptGuidance: String {
        return customPromptGuidance.isEmpty ? type.defaultPromptGuidance : customPromptGuidance
    }
    
    // Returns the appropriate graphic prompt guidance
    var graphicGuidance: String {
        return customGraphicPromptGuidance.isEmpty ? type.graphicPromptGuidance : customGraphicPromptGuidance
    }
    
    // Reset to default prompts
    func resetToDefaultPrompts() {
        customPromptGuidance = type.defaultPromptGuidance
        customGraphicPromptGuidance = type.graphicPromptGuidance
    }
    
    // Record a successful post
    func recordPost() {
        postCount += 1
        lastPostDate = Date()
    }
}
