import Foundation
import UIKit

// Helper extensions for logging
extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
}

// OpenAI Service Error types
enum OpenAIServiceError: Error {
    case invalidAPIKey
    case networkError(Error)
    case rateLimitExceeded
    case decodingError(Error)
    case unexpectedError(String)
    case invalidResponse
    case invalidImageData
    case invalidURL
    case noContent
    case serverError(Int)
    
    var description: String {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "OpenAI rate limit exceeded. Please wait a few moments before trying again."
        case .decodingError(let error):
            return "Error processing the response: \(error.localizedDescription)"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidImageData:
            return "Could not process image data."
        case .invalidURL:
            return "Invalid URL."
        case .noContent:
            return "No content was returned."
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

// OpenAI Service for handling AI-related operations
class OpenAIService {
    // MARK: - Properties
    private var apiKey: String = ""
    
    // Rate limiting properties
    private var requestTimestamps: [Date] = []
    private let maxRequestsPerMinute = 20 // Adjust based on your API tier
    private let requestWindow: TimeInterval = 60 // 1 minute in seconds
    
    // Logging configuration
    private let enableDetailedLogging = true // Set to false to disable detailed logs
    private let logResponses = true // Log response bodies
    
    // Base URL for OpenAI API
    private let baseURL = "https://api.openai.com/v1"
    
    // MARK: - Initialization
    init(apiKey: String = "") {
        self.apiKey = apiKey
        print("📱 OpenAIService initialized")
    }
    
    // Set the OpenAI API key
    func setAPIKey(_ key: String) {
        self.apiKey = key
        print("📱 API key updated")
        
        // Log key status (partial key for security)
        if !key.isEmpty {
            let lastFour = key.suffix(4)
            print("API key set successfully (ending with ....\(lastFour))")
        } else {
            print("Warning: Empty API key set")
        }
    }
    
    // Test API connection with the provided API key
    func testAPIConnection(apiKey: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Create a simple request to test if the API key is valid
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        // Validate API key minimally by checking the models endpoint
        let url = URL(string: "https://api.openai.com/v1/models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        // Make a simple API call to verify the key
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for basic errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check for HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // API key is valid
                    completion(.success(true))
                } else if httpResponse.statusCode == 401 {
                    // Unauthorized - Invalid API key
                    completion(.failure(NSError(domain: "com.automediamaker.openai", 
                                             code: 401, 
                                             userInfo: [NSLocalizedDescriptionKey: "Invalid API key"])))
                } else {
                    // Other HTTP error
                    completion(.failure(NSError(domain: "com.automediamaker.openai", 
                                             code: httpResponse.statusCode, 
                                             userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                }
            } else {
                // Unknown response format
                completion(.failure(NSError(domain: "com.automediamaker.openai", 
                                         code: -1, 
                                         userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Topic Research
    func researchTopic(topic: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        retryWithBackoff(maxRetries: 3, operation: { [weak self] innerCompletion in
            self?.performResearchTopic(topic: topic, completion: innerCompletion)
        }, completion: completion)
    }
    
    private func performResearchTopic(topic: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        // Check rate limiting first
        guard checkRateLimit() else {
            completion(.failure(.rateLimitExceeded))
            return
        }
        
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
        retryWithBackoff(maxRetries: 3, operation: { [weak self] innerCompletion in
            self?.performGenerateSocialPost(topic: topic, platform: platform, promptGuidance: promptGuidance, hashtags: hashtags, completion: innerCompletion)
        }, completion: completion)
    }
    
    private func performGenerateSocialPost(topic: String, platform: PlatformType, promptGuidance: String, hashtags: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        // Check rate limiting first
        guard checkRateLimit() else {
            completion(.failure(.rateLimitExceeded))
            return
        }
        
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
        retryWithBackoff(maxRetries: 3, operation: { [weak self] innerCompletion in
            self?.performGenerateImagePrompt(topic: topic, platform: platform, postText: postText, graphicGuidance: graphicGuidance, completion: innerCompletion)
        }, completion: completion)
    }
    
    private func performGenerateImagePrompt(topic: String, platform: PlatformType, postText: String, graphicGuidance: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        // Check rate limiting first
        guard checkRateLimit() else {
            completion(.failure(.rateLimitExceeded))
            return
        }
        
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
        retryWithBackoff(maxRetries: 3, operation: { [weak self] innerCompletion in
            self?.performGenerateMeme(topic: topic, hashtags: hashtags, completion: innerCompletion)
        }, completion: completion)
    }
    
    private func performGenerateMeme(topic: String, hashtags: String, completion: @escaping (Result<(String, String), OpenAIServiceError>) -> Void) {
        // Check rate limiting first
        guard checkRateLimit() else {
            completion(.failure(.rateLimitExceeded))
            return
        }
        
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
        retryWithBackoff(maxRetries: 3, operation: { [weak self] innerCompletion in
            self?.performProcessUserFeedback(originalContent: originalContent, userFeedback: userFeedback, completion: innerCompletion)
        }, completion: completion)
    }
    
    private func performProcessUserFeedback(originalContent: String, userFeedback: String, completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        // Check rate limiting first
        guard checkRateLimit() else {
            completion(.failure(.rateLimitExceeded))
            return
        }
        
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
    
    // MARK: - Image Generation
    func generateImage(prompt: String, completion: @escaping (Result<Data, OpenAIServiceError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        // Check rate limit
        if !checkRateLimit() {
            completion(.failure(.rateLimitExceeded))
            return
        }
        
        // Log request start
        logRequest("Generating image with DALL-E", details: "Prompt: \(prompt.truncated(to: 100))")
        
        // Prepare the request
        let endpoint = "\(baseURL)/images/generations"
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the request body
        let requestBody: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "standard",
            "response_format": "url"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            // Log outgoing request details
            logRequestDetails(request: request, body: ["prompt": prompt.truncated(to: 100), "model": "dall-e-3"])
        } catch {
            logError("Failed to create image generation request", error: error)
            completion(.failure(.unexpectedError("Failed to create request: \(error.localizedDescription)")))
            return
        }
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle network errors
            if let error = error {
                self.logError("Network error in image generation", error: error)
                completion(.failure(.networkError(error)))
                return
            }
            
            // Check if we received data
            guard let data = data, !data.isEmpty else {
                self.logError("No data received from image generation", error: nil)
                completion(.failure(.noContent))
                return
            }
            
            // Log response data if enabled (but abbreviated for images)
            if self.enableDetailedLogging {
                self.log("📨 Image generation response received - \(data.count) bytes")
            }
            
            // Process the HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logError("Invalid response type from image generation", error: nil)
                completion(.failure(.invalidResponse))
                return
            }
            
            // Process response based on status code
            switch httpResponse.statusCode {
            case 200...299:
                // Handle successful response
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let data = jsonResponse["data"] as? [[String: Any]],
                       let firstImage = data.first,
                       let url = firstImage["url"] as? String {
                        
                        self.log("✅ Successfully received image URL: \(url.truncated(to: 50))")
                        
                        // Download the image
                        self.downloadImage(from: url) { result in
                            switch result {
                            case .success(let imageData):
                                self.log("✅ Successfully downloaded image - \(imageData.count) bytes")
                                completion(.success(imageData))
                            case .failure(let error):
                                self.logError("Failed to download image", error: error)
                                completion(.failure(error))
                            }
                        }
                    } else {
                        self.logError("Failed to parse image response", error: nil)
                        completion(.failure(.invalidResponse))
                    }
                } catch {
                    self.logError("JSON parsing error in image response", error: error)
                    completion(.failure(.decodingError(error)))
                }
                
            case 401:
                self.logError("Authentication error (401) in image generation", error: nil)
                completion(.failure(.invalidAPIKey))
            case 429:
                self.logError("Rate limit exceeded (429) in image generation", error: nil)
                completion(.failure(.rateLimitExceeded))
            default:
                self.logError("Server error (\(httpResponse.statusCode)) in image generation", error: nil)
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }

    private func downloadImage(from urlString: String, completion: @escaping (Result<Data, OpenAIServiceError>) -> Void) {
        guard let url = URL(string: urlString) else {
            logError("Invalid image URL", error: nil)
            completion(.failure(.invalidURL))
            return
        }
        
        log("📥 Downloading image from: \(urlString.truncated(to: 50))")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logError("Error downloading image", error: error)
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                self.logError("Invalid HTTP response when downloading image", error: nil)
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                self.logError("No image data received", error: nil)
                completion(.failure(.invalidImageData))
                return
            }
            
            self.log("✅ Image download complete - \(data.count) bytes")
            completion(.success(data))
        }
        
        task.resume()
    }
    
    // MARK: - Rate Limiting and Retry Helpers
    
    // Check if we're within rate limits
    private func checkRateLimit() -> Bool {
        // Get the current timestamp
        let now = Date()
        
        // Remove timestamps older than the request window
        requestTimestamps.removeAll(where: { $0.timeIntervalSinceNow < -requestWindow })
        
        // Check if the number of requests within the window exceeds the limit
        if requestTimestamps.count >= maxRequestsPerMinute {
            print("⚠️ Rate limit reached: \(requestTimestamps.count) requests in the last \(requestWindow) seconds")
            return false
        }
        
        // Add the current timestamp to the list
        requestTimestamps.append(now)
        print("✓ Rate limit check passed: \(requestTimestamps.count)/\(maxRequestsPerMinute) requests in the last minute")
        
        return true
    }
    
    // Reset rate limit counter
    func resetRateLimits() {
        requestTimestamps.removeAll()
        print("Rate limit counters have been reset")
    }
    
    // Get estimated wait time before next request is allowed
    func getEstimatedWaitTime() -> TimeInterval {
        guard !requestTimestamps.isEmpty else { return 0 }
        
        // Sort timestamps to get the oldest one
        let sortedTimestamps = requestTimestamps.sorted()
        
        // Calculate when the oldest timestamp will expire
        if requestTimestamps.count >= maxRequestsPerMinute {
            let oldestTimestamp = sortedTimestamps.first!
            let expiryTime = oldestTimestamp.addingTimeInterval(requestWindow)
            let waitTime = expiryTime.timeIntervalSinceNow
            return max(waitTime, 0)
        }
        
        return 0
    }
    
    // Retry an operation with exponential backoff
    func retryWithBackoff<T>(
        maxRetries: Int = 3,
        operation: @escaping (@escaping (Result<T, OpenAIServiceError>) -> Void) -> Void,
        completion: @escaping (Result<T, OpenAIServiceError>) -> Void
    ) {
        var retries = 0
        
        func attempt() {
            operation { result in
                switch result {
                case .success:
                    completion(result)
                    
                case .failure(let error):
                    if case .rateLimitExceeded = error, retries < maxRetries {
                        retries += 1
                        let delay = pow(2.0, Double(retries)) // Exponential backoff: 2, 4, 8, etc. seconds
                        print("Rate limit hit, retrying in \(delay) seconds (attempt \(retries)/\(maxRetries))")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            attempt()
                        }
                    } else {
                        completion(result)
                    }
                }
            }
        }
        
        attempt()
    }
    
    // MARK: - Helper Methods
    private func sendChatRequest(messages: [[String: String]], completion: @escaping (Result<String, OpenAIServiceError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        // Check rate limit
        if !checkRateLimit() {
            completion(.failure(.rateLimitExceeded))
            return
        }
        
        // Log request start
        logRequest("Sending chat request to OpenAI", details: "Messages: \(truncateMessagesForLogging(messages))")
        
        // Prepare the request
        let endpoint = "\(baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the request body
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": messages,
            "max_tokens": 800
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            // Log outgoing request details
            logRequestDetails(request: request, body: requestBody)
        } catch {
            logError("Failed to create request", error: error)
            completion(.failure(.unexpectedError("Failed to create request: \(error.localizedDescription)")))
            return
        }
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle network errors
            if let error = error {
                self.logError("Network error", error: error)
                completion(.failure(.networkError(error)))
                return
            }
            
            // Check if we received data
            guard let data = data, !data.isEmpty else {
                self.logError("No data received", error: nil)
                completion(.failure(.noContent))
                return
            }
            
            // Log response data if enabled
            self.logResponseData(data: data)
            
            // Process the HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logError("Invalid response type", error: nil)
                completion(.failure(.invalidResponse))
                return
            }
            
            // Process response based on status code
            switch httpResponse.statusCode {
            case 200...299:
                // Handle successful response
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        self.log("✅ Received successful response from OpenAI chat API")
                        completion(.success(content))
                    } else {
                        self.logError("Failed to parse response", error: nil)
                        completion(.failure(.invalidResponse))
                    }
                } catch {
                    self.logError("JSON parsing error", error: error)
                    completion(.failure(.decodingError(error)))
                }
                
            case 401:
                self.logError("Authentication error (401)", error: nil)
                completion(.failure(.invalidAPIKey))
            case 429:
                self.logError("Rate limit exceeded (429)", error: nil)
                completion(.failure(.rateLimitExceeded))
            default:
                self.logError("Server error (\(httpResponse.statusCode))", error: nil)
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Logging
    private func log(_ message: String) {
        if enableDetailedLogging {
            print("📝 \(message)")
        }
    }
    
    private func logRequest(_ message: String, details: String) {
        if enableDetailedLogging {
            print("📨 \(message) - \(details)")
        }
    }
    
    private func logRequestDetails(request: URLRequest, body: [String: Any]) {
        if enableDetailedLogging {
            print("📨 Request to \(request.url?.absoluteString ?? "")")
            print("📨 Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("📨 Body: \(body)")
        }
    }
    
    private func logResponseData(data: Data) {
        if enableDetailedLogging && logResponses {
            if let responseString = String(data: data, encoding: .utf8) {
                print("📨 Response: \(responseString)")
            }
        }
    }
    
    private func logError(_ message: String, error: Error?) {
        if enableDetailedLogging {
            if let error = error {
                print("🚨 \(message) - \(error.localizedDescription)")
            } else {
                print("🚨 \(message)")
            }
        }
    }
    
    private func truncateMessagesForLogging(_ messages: [[String: String]]) -> String {
        return messages.map { message in
            if let content = message["content"] {
                return "\(message["role"] ?? ""): \(content.truncated(to: 50))"
            } else {
                return "\(message["role"] ?? ""): \(message)"
            }
        }.joined(separator: "\n")
    }
}
