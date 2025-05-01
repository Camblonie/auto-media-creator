import SwiftUI
import SwiftData

struct CreatePostView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    
    // ViewModel
    @ObservedObject var viewModel: CreatePostViewModel
    
    // State variables
    @State private var selectedPlatform: PlatformType?
    @State private var showPlatformSelection: Bool = true
    @State private var showTextGeneration: Bool = false
    @State private var showTextReview: Bool = false
    @State private var showHashtagEdit: Bool = false
    @State private var showImageGeneration: Bool = false
    @State private var showImageReview: Bool = false
    @State private var showFinalReview: Bool = false
    
    // Topic data passed from parent
    let topicHeadline: String
    let topicSummary: String
    
    init(openAIService: OpenAIService, modelContext: ModelContext, topicHeadline: String, topicSummary: String) {
        self.viewModel = CreatePostViewModel(openAIService: openAIService, modelContext: modelContext)
        self.topicHeadline = topicHeadline
        self.topicSummary = topicSummary
    }
    
    var body: some View {
        VStack {
            // Header
            SectionHeader(
                title: "Create Post",
                systemImage: "text.bubble.fill"
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
                    
                    // Hashtag edit
                    if showHashtagEdit {
                        hashtagEditView
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
                LoadingView(message: "Working on your content...")
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
            ForEach(0..<6) { index in
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
                        viewModel.selectedPlatform = activePlatform
                        moveToNextStep()
                    } else {
                        viewModel.showError = true
                        viewModel.errorMessage = "Please activate at least one platform in the Active Platforms section above."
                    }
                }) {
                    Text("Continue")
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
                Text("Text Instruction")
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
                viewModel.generatePostText(topicHeadline: topicHeadline, topicSummary: topicSummary)
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
            if !viewModel.generatedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated Post")
                        .font(.headline)
                        .foregroundColor(.primaryColor)
                    
                    Text(viewModel.generatedText)
                        .padding()
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Action buttons
                HStack {
                    Button("Regenerate") {
                        viewModel.generatePostText(topicHeadline: topicHeadline, topicSummary: topicSummary)
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
            if viewModel.generatedText.isEmpty {
                HStack {
                    Button("Back") {
                        moveToPreviousStep()
                    }
                    .secondaryButtonStyle()
                }
                .padding(.horizontal)
            }
        }
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
            
            Text("Review the generated text")
                .font(.headline)
                .padding(.horizontal)
            
            // Text editor
            TextInputArea(
                title: "Post Text",
                placeholder: "Enter post text...",
                text: $viewModel.generatedText,
                height: 200
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
                .disabled(viewModel.generatedText.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Hashtag edit view
    private var hashtagEditView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Platform indicator
            platformIndicator
            
            Text("Edit Hashtags")
                .font(.headline)
                .padding(.horizontal)
            
            // Hashtag editor
            TextInputArea(
                title: "Hashtags",
                placeholder: "Enter hashtags...",
                text: $viewModel.hashtags,
                height: 100
            )
            .padding(.horizontal)
            
            // Reset hashtags button
            Button(action: {
                if let settings = userSettings.first {
                    viewModel.hashtags = settings.defaultTags
                }
            }) {
                Text("Reset to Default Hashtags")
            }
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
            
            // Today's topic and generated text
            VStack(alignment: .leading, spacing: 8) {
                Text("Post Text")
                    .font(.headline)
                
                Text(viewModel.generatedText)
                    .font(.subheadline)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Text("This will generate an image for your post")
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
                viewModel.generateImage(topicHeadline: topicHeadline, topicSummary: topicSummary)
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
            if let image = viewModel.generatedImage {
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
                
                // Action buttons
                HStack {
                    Button("Regenerate") {
                        viewModel.generateImage(topicHeadline: topicHeadline, topicSummary: topicSummary)
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
            if viewModel.generatedImage == nil {
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
            
            Text("Review the generated image")
                .font(.headline)
                .padding(.horizontal)
            
            // Image display
            if let image = viewModel.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
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
                .disabled(viewModel.generatedImage == nil)
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
            
            Text("Review Your Post")
                .font(.headline)
                .padding(.horizontal)
            
            // Post preview
            VStack(alignment: .leading, spacing: 16) {
                // Text content
                Text(viewModel.generatedText)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(10)
                
                // Hashtags
                Text(viewModel.hashtags)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Image
                if let image = viewModel.generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Text("Click on the steps above to modify any part of your post")
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
                    savePost(post: false)
                }
                .secondaryButtonStyle()
                
                Button("Post") {
                    savePost(post: true)
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
    
    // MARK: - Helper Methods
    
    // Check if a step is active
    private func getStepActiveStatus(_ step: Int) -> Bool {
        switch step {
        case 0: return showPlatformSelection
        case 1: return showTextGeneration
        case 2: return showTextReview
        case 3: return showHashtagEdit
        case 4: return showImageGeneration
        case 5: return showImageReview || showFinalReview
        default: return false
        }
    }
    
    // Check if we can navigate to a step
    private func canNavigateToStep(_ step: Int) -> Bool {
        // Can only navigate to steps we've already visited or the next step
        if step == 0 { return true }
        if selectedPlatform == nil { return false }
        if step == 1 && !viewModel.generatedText.isEmpty { return true }
        if step == 2 && !viewModel.generatedText.isEmpty { return true }
        if step == 3 && !viewModel.generatedText.isEmpty { return true }
        if step == 4 && !viewModel.generatedText.isEmpty { return true }
        if step == 5 && viewModel.generatedImage != nil { return true }
        return false
    }
    
    // Navigate to a specific step
    private func navigateToStep(_ step: Int) {
        guard canNavigateToStep(step) else { return }
        
        // Hide all views
        showPlatformSelection = false
        showTextGeneration = false
        showTextReview = false
        showHashtagEdit = false
        showImageGeneration = false
        showImageReview = false
        showFinalReview = false
        
        // Show the selected view
        switch step {
        case 0: showPlatformSelection = true
        case 1: showTextGeneration = true
        case 2: showTextReview = true
        case 3: showHashtagEdit = true
        case 4: showImageGeneration = true
        case 5: showFinalReview = true
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
            showHashtagEdit = true
        } else if showHashtagEdit {
            showHashtagEdit = false
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
        } else if showHashtagEdit {
            showHashtagEdit = false
            showTextReview = true
        } else if showImageGeneration {
            showImageGeneration = false
            showHashtagEdit = true
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
        showHashtagEdit = false
        showImageGeneration = false
        showImageReview = false
        showFinalReview = false
    }
    
    // Save the post
    private func savePost(post: Bool) {
        guard let platform = selectedPlatform else { return }
        
        // Create a new post
        let newPost = Post(
            postType: .traditional,
            userInputPrompt: topicHeadline,
            platformType: platform,
            textContent: viewModel.generatedText + "\n\n" + viewModel.hashtags,
            imagePrompt: viewModel.imagePrompt
        )
        
        // Set the image if available
        if let imageData = viewModel.generatedImage?.jpegData(compressionQuality: 0.8) {
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
        viewModel.successMessage = post ? "Post has been published!" : "Post has been saved as a draft."
        
        // Reset workflow after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            resetWorkflow()
        }
    }
}
