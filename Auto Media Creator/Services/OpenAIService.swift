import Foundation
import UIKit

// Error types for OpenAI service
enum OpenAIServiceError: Error {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case invalidImageData
    case invalidURL
    case noContent
    case rateLimited
    case serverError(Int)
    case unexpectedError(String)
    
    var description: String {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key. Please check your settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidImageData:
            return "Could not process image data."
        case .invalidURL:
            return "Invalid URL."
        case .noContent:
            return "No content was returned."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error: \(code)"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        }
    }
}

// Main service for OpenAI API interactions
class OpenAIService {
    private var apiKey: String = ""
    
    // Base URL for OpenAI API
    private let baseURL = "https://api.openai.com/v1"
    
    init(apiKey: String = "") {
        self.apiKey = apiKey
    }
    
    // Set API key
    func setAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    // MARK: - Topic Research
    func researchTopic(topic: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        // Base prompt for automotive research
        let researchPrompt = """
        Your goal is to identify and compile an automotive repair and maintenance topic that is being covered in the news online. This involves conducting a detailed search for Automotive repair news or new products published yesterday.
        Focus on automotive repair and maintenance from reputable sources. Look for exciting trending news or new products that's just launched specifically about automotive products or brands. Look for articles reminding people to have maintenance performed on their vehicles.
        
        Topic to research: \(topic)
        
        Format your response as a summary of the research findings that can be used to create social media posts.
        """
        
        sendChatRequest(
            messages: [
                ["role": "system", "content": "You are a research assistant for an automotive repair shop."],
                ["role": "user", "content": researchPrompt]
            ],
            completion: completion
        )
    }
    
    // MARK: - Generate Traditional Post Text
    func generateSocialPost(topic: String, platform: PlatformType, promptGuidance: String, hashtags: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        let prompt = """
        Using the research topic provided and following the platform-specific guidelines below, create a social media post for an automotive repair shop.
        
        TOPIC:
        \(topic)
        
        PLATFORM GUIDELINES:
        \(promptGuidance)
        
        HASHTAGS TO INCLUDE:
        \(hashtags)
        
        Create an engaging, informative post that follows the guidelines for \(platform.rawValue) and would generate interest and engagement for an automotive repair shop.
        """
        
        sendChatRequest(
            messages: [
                ["role": "system", "content": "You are a social media content creator for an automotive repair shop."],
                ["role": "user", "content": prompt]
            ],
            completion: completion
        )
    }
    
    // MARK: - Generate Image Prompt
    func generateImagePrompt(topic: String, platform: PlatformType, postText: String, graphicGuidance: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        let prompt = """
        Based on the following social media post for \(platform.rawValue), create a detailed image prompt for DALL-E 3 that will generate a compelling, relevant image for the post.
        
        POST TEXT:
        \(postText)
        
        GRAPHIC GUIDELINES:
        \(graphicGuidance)
        
        TOPIC:
        \(topic)
        
        Create a detailed, specific image prompt that will generate a professional, engaging image related to automotive repair and the post content.
        Your prompt should describe the scene, elements, style, mood, and colors in detail.
        The image should look professional and be appropriate for a business social media account.
        """
        
        sendChatRequest(
            messages: [
                ["role": "system", "content": "You are an image prompt creator for an automotive repair shop's social media."],
                ["role": "user", "content": prompt]
            ],
            completion: completion
        )
    }
    
    // MARK: - Generate Meme
    func generateMeme(topic: String, hashtags: String, completion: @escaping (Result<(String, String), OpenAIServiceError>) -> Void) {
        let prompt = """
        Create an automotive related meme that an auto repair shop might post to their social media. Make it edgy, funny and relatable. Don't be afraid to lean on current meme culture for inspiration.
        
        TOPIC (if specified):
        \(topic)
        
        HASHTAGS TO INCLUDE:
        \(hashtags)
        
        Provide two outputs:
        1. A brief text caption for the meme
        2. A detailed DALL-E image prompt that would generate a funny, engaging automotive meme image
        
        Separate these with a triple dash (---) like this:
        Caption: [meme caption]
        ---
        Image Prompt: [detailed image prompt]
        """
        
        sendChatRequest(
            messages: [
                ["role": "system", "content": "You are a meme creator for an automotive repair shop's social media."],
                ["role": "user", "content": prompt]
            ]
        ) { result in
            switch result {
            case .success(let response):
                // Parse the response to separate caption and image prompt
                let parts = response.components(separatedBy: "---").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                
                if parts.count >= 2 {
                    // Extract the caption and image prompt
                    let captionPart = parts[0].replacingOccurrences(of: "Caption:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let promptPart = parts[1].replacingOccurrences(of: "Image Prompt:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    completion(.success((captionPart, promptPart)))
                } else {
                    // If the format is incorrect, return the whole text as caption and generate a generic image prompt
                    let fallbackPrompt = "Create a funny automotive repair meme image based on: \(response)"
                    completion(.success((response, fallbackPrompt)))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Process User Feedback
    func processUserFeedback(originalContent: String, userFeedback: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        let prompt = """
        You are reviewing the following social media post content for an automotive repair shop:
        
        ORIGINAL CONTENT:
        \(originalContent)
        
        USER FEEDBACK:
        \(userFeedback)
        
        Please revise the content based on the user feedback. Maintain the same general topic and purpose, but incorporate the changes requested.
        """
        
        sendChatRequest(
            messages: [
                ["role": "system", "content": "You are a social media content editor for an automotive repair shop."],
                ["role": "user", "content": prompt]
            ],
            completion: completion
        )
    }
    
    // MARK: - Generate Image
    func generateImage(prompt: String, completion: @escaping (Result<UIImage, OpenAIServiceError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        // Ensure the URL is valid
        guard let url = URL(string: "\(baseURL)/images/generations") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "response_format": "b64_json"
        ]
        
        do {
            // Convert the request body to JSON data
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.unexpectedError("Failed to encode request body: \(error.localizedDescription)")))
            return
        }
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            // Check for valid response and data
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noContent))
                return
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                // Try to parse the response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataArray = json["data"] as? [[String: Any]],
                       let firstImage = dataArray.first,
                       let b64Json = firstImage["b64_json"] as? String,
                       let imageData = Data(base64Encoded: b64Json),
                       let image = UIImage(data: imageData) {
                        completion(.success(image))
                    } else {
                        completion(.failure(.invalidImageData))
                    }
                } catch {
                    completion(.failure(.unexpectedError("Failed to decode response: \(error.localizedDescription)")))
                }
            case 401:
                completion(.failure(.invalidAPIKey))
            case 429:
                completion(.failure(.rateLimited))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Helper Methods
    private func sendChatRequest(messages: [[String: String]], completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        // Ensure the URL is valid
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        do {
            // Convert the request body to JSON data
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.unexpectedError("Failed to encode request body: \(error.localizedDescription)")))
            return
        }
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            // Check for valid response and data
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noContent))
                return
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                // Try to parse the response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else {
                        completion(.failure(.invalidResponse))
                    }
                } catch {
                    completion(.failure(.unexpectedError("Failed to decode response: \(error.localizedDescription)")))
                }
            case 401:
                completion(.failure(.invalidAPIKey))
            case 429:
                completion(.failure(.rateLimited))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
}
