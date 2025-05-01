import SwiftUI
import SwiftData

struct TopicView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    // ViewModel
    @ObservedObject var viewModel: TopicViewModel
    
    // State variables
    @State private var userInput: String = ""
    @State private var showResetAlert: Bool = false
    
    init(modelContext: ModelContext, openAIService: OpenAIService) {
        self.viewModel = TopicViewModel(modelContext: modelContext, openAIService: openAIService)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                SectionHeader(
                    title: "Today's Topic",
                    systemImage: "newspaper.fill"
                )
                
                // User input section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Provide additional context (optional)")
                        .font(.headline)
                        .foregroundColor(.primaryColor)
                    
                    TextField("Enter specific topics or interests...", text: $userInput)
                        .padding()
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Generate button
                Button(action: {
                    viewModel.generateTopic(userInput: userInput)
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate")
                    }
                    .frame(maxWidth: .infinity)
                }
                .accentButtonStyle()
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    // Loading indicator
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Researching topic...")
                            .foregroundColor(.secondaryColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if !viewModel.topicHeadline.isEmpty {
                    // Today's topic result
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Topic")
                            .font(.headline)
                            .foregroundColor(.primaryColor)
                            .padding(.bottom, 4)
                        
                        Text(viewModel.topicHeadline)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.darkAccentColor)
                            .padding(.bottom, 4)
                        
                        if !viewModel.topicSummary.isEmpty {
                            Text(viewModel.topicSummary)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBackgroundColor)
                            .shadow(color: Color.darkAccentColor.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
                
                // Model instruction section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Instruction")
                        .font(.headline)
                        .foregroundColor(.primaryColor)
                    
                    TextInputArea(
                        title: "",
                        placeholder: "Enter instructions for the AI model...",
                        text: $viewModel.modelInstruction,
                        height: 200
                    )
                    
                    Button(action: {
                        showResetAlert = true
                    }) {
                        Text("Revert to default instruction")
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color.backgroundColor)
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset Instructions"),
                message: Text("Are you sure you want to reset the model instructions to default?"),
                primaryButton: .destructive(Text("Reset")) {
                    viewModel.resetModelInstruction()
                },
                secondaryButton: .cancel()
            )
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Researching topic...")
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissError()
                }
            )
        }
        .onAppear {
            viewModel.loadDefaultInstruction()
        }
    }
}

// ViewModel for Topic View
class TopicViewModel: ObservableObject {
    // Dependencies
    private let modelContext: ModelContext
    private let openAIService: OpenAIService
    
    // Published properties
    @Published var modelInstruction: String = ""
    @Published var topicHeadline: String = ""
    @Published var topicSummary: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // Current research content
    @Published var currentResearchContent: ResearchContent?
    
    // Default instruction for topic generation
    let defaultInstruction = """
    Generate a headline and summary for a topic relevant to automotive customers and in the news in the past week.
        
        The HEADLINE should be attention-grabbing and concise (5-10 words).
        The SUMMARY should provide key details about the topic (100-150 words).

        Focus on topics like:
        - New repair techniques or technologies
        - Common issues and solutions for popular vehicles
        - Industry trends with car maintenance
        - Maintenance tips that customers should know
        - Emerging trends with owners of used cars

    Format your response exactly as:
    HEADLINE: [Your headline here]
    SUMMARY: [Your detailed summary here]
    """
    
    init(modelContext: ModelContext, openAIService: OpenAIService) {
        self.modelContext = modelContext
        self.openAIService = openAIService
        
        // Load the most recent topic if available
        loadLatestTopic()
    }
    
    // Load default instruction
    func loadDefaultInstruction() {
        if modelInstruction.isEmpty {
            modelInstruction = defaultInstruction
        }
    }
    
    // Reset to default instruction
    func resetModelInstruction() {
        modelInstruction = defaultInstruction
    }
    
    // Load the most recent topic
    private func loadLatestTopic() {
        let fetchDescriptor = FetchDescriptor<ResearchContent>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        // Create a mutable copy of the descriptor to set the fetch limit
        var descriptor = fetchDescriptor
        descriptor.fetchLimit = 1
        
        do {
            let topics = try modelContext.fetch(descriptor)
            if let latestTopic = topics.first {
                self.currentResearchContent = latestTopic
                self.topicHeadline = latestTopic.headline
                self.topicSummary = latestTopic.summary
                print("Loaded latest topic: \(latestTopic.headline)")
            }
        } catch {
            print("Failed to load latest topic: \(error.localizedDescription)")
        }
    }
    
    // Generate topic using OpenAI
    func generateTopic(userInput: String) {
        isLoading = true
        
        // Combine user input with model instruction if provided
        var prompt = modelInstruction
        if !userInput.isEmpty {
            prompt += "\n\nAdditional context from user: \(userInput)"
        }
        
        // Call OpenAI service
        openAIService.researchTopic(topic: prompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.parseTopicResponse(response, userInput: userInput)
                case .failure(let error):
                    self?.showError = true
                    self?.errorMessage = error.description
                }
            }
        }
    }
    
    // Parse the response from OpenAI to extract headline and summary
    private func parseTopicResponse(_ response: String, userInput: String) {
        // Extract headline
        if let headlineRange = response.range(of: "HEADLINE:(.*?)(?=SUMMARY:|$)", options: .regularExpression) {
            let headline = String(response[headlineRange])
                .replacingOccurrences(of: "HEADLINE:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            topicHeadline = headline
        } else if let headlineRange = response.range(of: "HEADLINE\\s*:?\\s*(.*?)(?=SUMMARY|$)", options: .regularExpression) {
            let headline = String(response[headlineRange])
                .replacingOccurrences(of: "HEADLINE", with: "")
                .replacingOccurrences(of: ":", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            topicHeadline = headline
        } else {
            // If no headline format is found, use the first line
            let lines = response.components(separatedBy: "\n")
            if let firstLine = lines.first {
                topicHeadline = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Extract summary
        if let summaryRange = response.range(of: "SUMMARY:(.*?)$", options: [.regularExpression]) {
            let summary = String(response[summaryRange])
                .replacingOccurrences(of: "SUMMARY:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            topicSummary = summary
        } else if let summaryRange = response.range(of: "SUMMARY\\s*:?\\s*(.*?)$", options: [.regularExpression]) {
            let summary = String(response[summaryRange])
                .replacingOccurrences(of: "SUMMARY", with: "")
                .replacingOccurrences(of: ":", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            topicSummary = summary
        } else {
            // If no summary format is found, use the rest of the text after the first line
            let lines = response.components(separatedBy: "\n")
            if lines.count > 1 {
                topicSummary = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Create and save ResearchContent
        saveResearchContent(userInput: userInput)
    }
    
    // Save the research content to SwiftData
    private func saveResearchContent(userInput: String) {
        let source = userInput.isEmpty ? "Auto-generated" : "User prompt: \(userInput)"
        let newContent = ResearchContent(
            headline: topicHeadline,
            summary: topicSummary,
            source: source,
            additionalDetails: ""
        )
        
        modelContext.insert(newContent)
        currentResearchContent = newContent
        
        do {
            try modelContext.save()
            print("Saved new research content: \(topicHeadline)")
        } catch {
            print("Failed to save research content: \(error.localizedDescription)")
        }
    }
    
    // Dismiss error
    func dismissError() {
        showError = false
        errorMessage = ""
    }
}
