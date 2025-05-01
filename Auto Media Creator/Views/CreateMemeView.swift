import SwiftUI
import SwiftData

struct CreateMemeView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    
    // ViewModel
    @ObservedObject var viewModel: CreateMemeViewModel
    
    // State variables
    @State private var selectedPlatform: PlatformType?
    @State private var showPlatformSelection: Bool = true
    @State private var showTextGeneration: Bool = false
    @State private var showTextReview: Bool = false
    @State private var showImageGeneration: Bool = false
    @State private var showImageReview: Bool = false
    @State private var showFinalReview: Bool = false
    
    // Topic data passed from parent
    let topicHeadline: String
    let topicSummary: String
    
    init(openAIService: OpenAIService, modelContext: ModelContext, topicHeadline: String, topicSummary: String) {
        self.viewModel = CreateMemeViewModel(openAIService: openAIService, modelContext: modelContext)
        self.topicHeadline = topicHeadline
        self.topicSummary = topicSummary
    }
    
    var body: some View {
        VStack {
            // Header
            SectionHeader(
                title: "Create Meme",
                systemImage: "face.smiling.fill"
            )
            
            // Workflow steps
            workflowStepsView
            
            // Content based on current step
            ScrollView {
                VStack(spacing: 20) {
                    // Platform selection
                    if showPlatformSelection {
                        platformSelectionView
                    }
                    
                    // Text generation
                    if showTextGeneration {
                        textGenerationView
                    }
                    
                    // Text review
                    if showTextReview {
                        textReviewView
                    }
                    
                    // Image generation
                    if showImageGeneration {
                        imageGenerationView
                    }
                    
                    // Image review
                    if showImageReview {
                        imageReviewView
                    }
                    
                    // Final review
                    if showFinalReview {
                        finalReviewView
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .background(Color.backgroundColor)
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Creating your meme...")
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
        .alert(isPresented: $viewModel.showSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text(viewModel.successMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Initialize hashtags from user settings
            if let settings = userSettings.first {
                viewModel.hashtags = settings.defaultTags
            }
        }
    }
    
    // MARK: - Subviews
    
    // Workflow steps view
    private var workflowStepsView: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                let isActive = getStepActiveStatus(index)
                
                Button(action: {
                    navigateToStep(index)
                }) {
                    Rectangle()
                        .fill(isActive ? Color.primaryColor : Color.gray.opacity(0.3))
                        .frame(height: 8)
                }
                .disabled(!canNavigateToStep(index))
            }
        }
        .padding(.horizontal)
    }
    
    // Platform selection view
    private var platformSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Today's topic display
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Topic")
                    .font(.headline)
                
                Text(topicHeadline)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
                
                Text("Summary")
                    .font(.headline)
                
                Text(topicSummary)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Continue button
            HStack {
                Spacer()
                
                Button(action: {
                    // Get the first active platform from user settings
                    if let activePlatform = viewModel.getFirstActivePlatform() {
                        selectedPlatform = activePlatform
                        moveToNextStep()
                    } else {
                        viewModel.showError = true
                        viewModel.errorMessage = "Please activate at least one platform in the Active Platforms section above."
                    }
                }) {
                    Text("Continue")
                        .primaryButtonStyle()
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Text generation view
    private var textGenerationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Platform indicator
            platformIndicator
            
            // Today's topic - show only headline, not summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Topic")
                    .font(.headline)
                    .foregroundColor(.primaryColor)
                
                Text(topicHeadline)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.darkAccentColor)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Text instruction - show and allow editing
            VStack(alignment: .leading, spacing: 8) {
                Text("Meme Text Instruction")
                    .font(.headline)
                    .foregroundColor(.primaryColor)
                
                TextEditor(text: $viewModel.textInstruction)
                    .frame(minHeight: 120)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primaryColor.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            
            // Generate button
            Button(action: {
                viewModel.generateMemeText(topicHeadline: topicHeadline, topicSummary: topicSummary)
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate")
                }
                .frame(maxWidth: .infinity)
            }
            .accentButtonStyle()
            .padding(.horizontal)
            .disabled(viewModel.isLoading)
            
            // Generated text (if available)
            if !viewModel.memeText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meme Text")
                        .font(.headline)
                        .foregroundColor(.primaryColor)
                    
                    Text(viewModel.memeText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Action buttons
                HStack {
                    Button("Regenerate") {
                        viewModel.generateMemeText(topicHeadline: topicHeadline, topicSummary: topicSummary)
                    }
                    .secondaryButtonStyle()
                    
                    Button("Continue") {
                        moveToNextStep()
                    }
                    .primaryButtonStyle()
                }
                .padding(.horizontal)
            }
            
            // Navigation buttons (if no text generated yet)
            if viewModel.memeText.isEmpty {
                HStack {
                    Button("Back") {
                        moveToPreviousStep()
                    }
                    .secondaryButtonStyle()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // Text review view
    private var textReviewView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Platform indicator
            platformIndicator
            
            // Today's topic
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Topic")
                    .font(.headline)
                    .foregroundColor(.primaryColor)
                
                Text(topicHeadline)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.darkAccentColor)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Text("Review the meme text")
                .font(.headline)
                .padding(.horizontal)
            
            // Text editor
            TextInputArea(
                title: "Meme Text",
                placeholder: "Enter meme text...",
                text: $viewModel.memeText,
                height: 150
            )
            .padding(.horizontal)
            
            // Navigation buttons
            HStack {
                Button("Back") {
                    moveToPreviousStep()
                }
                .secondaryButtonStyle()
                
                Button("Cancel") {
                    resetWorkflow()
                }
                .secondaryButtonStyle()
                
                Button("Continue") {
                    moveToNextStep()
                }
                .primaryButtonStyle()
                .disabled(viewModel.memeText.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Image generation view
    private var imageGenerationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Platform indicator
            platformIndicator
            
            // Today's topic and meme text
            VStack(alignment: .leading, spacing: 8) {
                Text("Meme Text")
                    .font(.headline)
                
                Text(viewModel.memeText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Text("This will generate the image portion for the Meme")
                .font(.headline)
                .padding(.horizontal)
            
            // Modify image instruction button
            Button(action: {
                viewModel.showImageInstructionModal = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Modify Image Instruction")
                }
                .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
            .padding(.horizontal)
            .sheet(isPresented: $viewModel.showImageInstructionModal) {
                imageInstructionModalView
            }
            
            // Generate button
            Button(action: {
                viewModel.generateMemeImage(topicHeadline: topicHeadline, topicSummary: topicSummary)
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Image")
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .padding(.horizontal)
            .disabled(viewModel.isLoading)
            
            // Generated image (if available)
            if let image = viewModel.memeImage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meme Image")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                // Action buttons
                HStack {
                    Button("Regenerate") {
                        viewModel.generateMemeImage(topicHeadline: topicHeadline, topicSummary: topicSummary)
                    }
                    .secondaryButtonStyle()
                    
                    Button("Continue") {
                        moveToNextStep()
                    }
                    .primaryButtonStyle()
                }
                .padding(.horizontal)
            }
            
            // Navigation buttons (if no image generated yet)
            if viewModel.memeImage == nil {
                HStack {
                    Button("Back") {
                        moveToPreviousStep()
                    }
                    .secondaryButtonStyle()
                    
                    Button("Cancel") {
                        resetWorkflow()
                    }
                    .secondaryButtonStyle()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // Image instruction modal view
    private var imageInstructionModalView: some View {
        VStack(spacing: 20) {
            Text("Modify Image Instruction")
                .font(.title2)
                .fontWeight(.bold)
            
            TextInputArea(
                title: "Instructions for generating image",
                placeholder: "Enter instructions...",
                text: $viewModel.imageInstruction,
                height: 200
            )
            .padding(.horizontal)
            
            Button("Revert to default instruction") {
                viewModel.showResetImageInstructionAlert = true
            }
            .padding()
            
            HStack {
                Button("Cancel") {
                    viewModel.showImageInstructionModal = false
                }
                .secondaryButtonStyle()
                
                Button("Save") {
                    viewModel.showImageInstructionModal = false
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .alert(isPresented: $viewModel.showResetImageInstructionAlert) {
            Alert(
                title: Text("Reset Instructions"),
                message: Text("Are you sure you want to reset the image instructions to default?"),
                primaryButton: .destructive(Text("Reset")) {
                    viewModel.resetImageInstruction()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Image review view
    private var imageReviewView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Platform indicator
            platformIndicator
            
            // Today's topic and meme text
            VStack(alignment: .leading, spacing: 8) {
                Text("Meme Text")
                    .font(.headline)
                
                Text(viewModel.memeText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Generated image
            if let image = viewModel.memeImage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated Image")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            
            // Navigation buttons
            HStack {
                Button("Back") {
                    moveToPreviousStep()
                }
                .secondaryButtonStyle()
                
                Button("Regenerate") {
                    viewModel.generateMemeImage(topicHeadline: topicHeadline, topicSummary: topicSummary)
                }
                .secondaryButtonStyle()
                
                Button("Continue") {
                    moveToNextStep()
                }
                .primaryButtonStyle()
                .disabled(viewModel.memeImage == nil)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Final review view
    private var finalReviewView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Platform indicator
            platformIndicator
            
            Text("Review Your Meme")
                .font(.headline)
                .padding(.horizontal)
            
            // Meme preview
            VStack(alignment: .center, spacing: 16) {
                // Image with text overlay
                if let image = viewModel.memeImage {
                    ZStack(alignment: .center) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(10)
                        
                        // Text overlay
                        Text(viewModel.memeText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                            .padding()
                            .shadow(color: .black, radius: 2)
                    }
                    .padding(.horizontal)
                }
                
                // Hashtags
                Text(viewModel.hashtags)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Text("Click on the steps above to modify any part of your meme")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    resetWorkflow()
                }
                .secondaryButtonStyle()
                
                Button("Save Draft") {
                    saveMeme(post: false)
                }
                .secondaryButtonStyle()
                
                Button("Post") {
                    saveMeme(post: true)
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Platform indicator
    private var platformIndicator: some View {
        HStack {
            if let platform = selectedPlatform {
                Image(systemName: platform.icon)
                    .foregroundColor(.primaryColor)
                
                Text(platform.rawValue)
                    .font(.headline)
                    .foregroundColor(.primaryColor)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // Topic indicator
    private var topicIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Topic")
                .font(.headline)
            
            Text(topicHeadline)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primaryColor)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardBackgroundColor)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    // Check if a step is active
    private func getStepActiveStatus(_ step: Int) -> Bool {
        switch step {
        case 0: return showPlatformSelection
        case 1: return showTextGeneration
        case 2: return showTextReview
        case 3: return showImageGeneration
        case 4: return showImageReview || showFinalReview
        default: return false
        }
    }
    
    // Check if we can navigate to a step
    private func canNavigateToStep(_ step: Int) -> Bool {
        // Can only navigate to steps we've already visited or the next step
        if step == 0 { return true }
        if selectedPlatform == nil { return false }
        if step == 1 && !viewModel.memeText.isEmpty { return true }
        if step == 2 && !viewModel.memeText.isEmpty { return true }
        if step == 3 && !viewModel.memeText.isEmpty { return true }
        if step == 4 && viewModel.memeImage != nil { return true }
        return false
    }
    
    // Navigate to a specific step
    private func navigateToStep(_ step: Int) {
        guard canNavigateToStep(step) else { return }
        
        // Hide all views
        showPlatformSelection = false
        showTextGeneration = false
        showTextReview = false
        showImageGeneration = false
        showImageReview = false
        showFinalReview = false
        
        // Show the selected view
        switch step {
        case 0: showPlatformSelection = true
        case 1: showTextGeneration = true
        case 2: showTextReview = true
        case 3: showImageGeneration = true
        case 4: showFinalReview = true
        default: break
        }
    }
    
    // Move to the next step in the workflow
    private func moveToNextStep() {
        if showPlatformSelection {
            showPlatformSelection = false
            showTextGeneration = true
        } else if showTextGeneration {
            showTextGeneration = false
            showTextReview = true
        } else if showTextReview {
            showTextReview = false
            showImageGeneration = true
        } else if showImageGeneration {
            showImageGeneration = false
            showImageReview = true
        } else if showImageReview {
            showImageReview = false
            showFinalReview = true
        }
    }
    
    // Move to the previous step in the workflow
    private func moveToPreviousStep() {
        if showTextGeneration {
            showTextGeneration = false
            showPlatformSelection = true
        } else if showTextReview {
            showTextReview = false
            showTextGeneration = true
        } else if showImageGeneration {
            showImageGeneration = false
            showTextReview = true
        } else if showImageReview {
            showImageReview = false
            showImageGeneration = true
        } else if showFinalReview {
            showFinalReview = false
            showImageReview = true
        }
    }
    
    // Reset the workflow
    private func resetWorkflow() {
        // Reset all state
        selectedPlatform = nil
        viewModel.reset()
        
        // Show only the platform selection view
        showPlatformSelection = true
        showTextGeneration = false
        showTextReview = false
        showImageGeneration = false
        showImageReview = false
        showFinalReview = false
    }
    
    // Save the meme
    private func saveMeme(post: Bool) {
        guard let platform = selectedPlatform else { return }
        
        // Create a new post
        let newPost = Post(
            postType: .meme,
            userInputPrompt: topicHeadline,
            platformType: platform,
            textContent: viewModel.memeText + "\n\n" + viewModel.hashtags,
            imagePrompt: viewModel.imagePrompt
        )
        
        // Set the image if available
        if let imageData = viewModel.memeImage?.jpegData(compressionQuality: 0.8) {
            newPost.setImage(imageData)
        }
        
        // Mark as approved
        newPost.approve()
        
        // Insert into model context
        modelContext.insert(newPost)
        
        // Post if requested
        if post {
            // In a real app, this would post to the social media platform
            // For now, we'll just mark it as posted
            newPost.markAsPosted(url: "https://example.com/post/\(UUID().uuidString)")
        }
        
        // Save changes
        try? modelContext.save()
        
        // Show success alert
        viewModel.showSuccessAlert = true
        viewModel.successMessage = post ? "Meme has been published!" : "Meme has been saved as a draft."
        
        // Reset workflow after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            resetWorkflow()
        }
    }
}
