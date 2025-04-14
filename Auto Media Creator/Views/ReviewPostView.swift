import SwiftUI
import SwiftData

struct ReviewPostView: View {
    // Post being reviewed
    let post: Post
    
    // View model
    @ObservedObject var viewModel: ReviewViewModel
    
    // Environment dependencies
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with platform and type
                reviewHeader
                
                // Content review section (depends on status)
                switch post.reviewStatus {
                case .pendingTextReview:
                    textReviewSection
                case .pendingGraphicReview:
                    graphicReviewSection
                case .pendingMemeReview:
                    memeReviewSection
                case .approved:
                    approvedContentSection
                case .rejected:
                    rejectedContentSection
                case .posted:
                    postedContentSection
                }
                
                // Action buttons for pending items
                if post.reviewStatus == .pendingTextReview || 
                   post.reviewStatus == .pendingGraphicReview || 
                   post.reviewStatus == .pendingMemeReview {
                    
                    // Feedback section
                    feedbackSection
                    
                    // Action buttons
                    actionButtons
                }
            }
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Processing...")
            }
        }
        .alert(isPresented: $viewModel.showError, content: {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissError()
                }
            )
        })
    }
    
    // MARK: - Subviews
    
    // Review header
    private var reviewHeader: some View {
        VStack(spacing: 8) {
            // Platform icon and name
            HStack {
                Image(systemName: post.platformType.icon)
                    .font(.title2)
                    .foregroundColor(.primaryColor)
                
                Text(post.platformType.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Post type badge
                Text(post.postType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(post.postType == .traditional ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Status and creation date
            HStack {
                Label(post.reviewStatus.rawValue, systemImage: statusIcon(post.reviewStatus))
                    .font(.caption)
                    .foregroundColor(statusColor(post.reviewStatus))
                
                Spacer()
                
                Text("Created: \(post.creationDate.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Topic / prompt
            VStack(alignment: .leading, spacing: 4) {
                Text("Topic Prompt:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(post.userInputPrompt)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                
                // Add button to show AI prompt
                DisclosureGroup(
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OpenAI Prompt Template:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let platform = viewModel.getPlatform(for: post.platformType) {
                                ScrollView(.vertical) {
                                    Text(platform.promptGuidance)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .frame(height: 150)
                            } else {
                                Text("Platform prompt guidance not available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 8)
                    },
                    label: {
                        HStack {
                            Image(systemName: "terminal")
                            Text("Show OpenAI Prompt")
                                .font(.caption)
                            Spacer()
                        }
                        .foregroundColor(.blue)
                    }
                )
                .padding(.top, 8)
            }
            .padding()
            .background(Color.backgroundColor)
        }
        .padding()
        .background(Color.backgroundColor)
    }
    
    // Text review section
    private var textReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 Text Review")
                .font(.headline)
                .foregroundColor(.primaryColor)
                .padding(.horizontal)
            
            // Text content
            if post.textContent.isEmpty {
                Text("Content still being generated...")
                    .italic()
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(post.textContent)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Error message if any
            if let errorMessage = post.errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // Graphic review section
    private var graphicReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Approved text section
            VStack(alignment: .leading, spacing: 8) {
                Text("✅ Approved Text")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal)
                
                Text(post.textContent)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            Divider()
                .padding(.horizontal)
            
            // Image review section
            VStack(alignment: .leading, spacing: 12) {
                Text("🖼️ Graphic Review")
                    .font(.headline)
                    .foregroundColor(.primaryColor)
                    .padding(.horizontal)
                
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    // Show the image
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                } else if !post.imagePrompt.isEmpty {
                    // Image is being generated
                    VStack(spacing: 12) {
                        ProgressView()
                            .padding()
                        
                        Text("Generating image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    // No image yet
                    Text("Image prompt is being generated...")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.vertical, 8)
            
            // Show image prompt for reference
            if !post.imagePrompt.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image Prompt:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Show the actual prompt used to generate the image
                    ScrollView {
                        Text(post.imagePrompt)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(height: 100)
                    .padding(.horizontal)
                    
                    // Add disclosure group to show platform specific image guidance
                    DisclosureGroup(
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("OpenAI Image Generation Guidance:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let platform = viewModel.getPlatform(for: post.platformType) {
                                    ScrollView(.vertical) {
                                        Text(platform.graphicGuidance)
                                            .font(.system(.caption, design: .monospaced))
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .frame(height: 150)
                                } else {
                                    Text("Platform graphic guidance not available")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(.vertical, 8)
                        },
                        label: {
                            HStack {
                                Image(systemName: "paintbrush")
                                Text("Show Image Generation Guidelines")
                                    .font(.caption)
                                Spacer()
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                        }
                    )
                    .padding(.top, 4)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            
            // Error message if any
            if let errorMessage = post.errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // Meme review section
    private var memeReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("😂 Meme Review")
                .font(.headline)
                .foregroundColor(.primaryColor)
                .padding(.horizontal)
            
            // Meme text
            VStack(alignment: .leading, spacing: 4) {
                Text("Caption:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if post.textContent.isEmpty {
                    Text("Caption being generated...")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text(post.textContent)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            
            // Meme image
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    // Show the image
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                } else {
                    // No image yet
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding()
                        
                        Text("Meme image will be generated after review")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            
            // Error message if any
            if let errorMessage = post.errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // Content for approved posts pending publishing
    private var approvedContentSection: some View {
        VStack(spacing: 16) {
            // Header
            Text("✅ Ready to Post")
                .font(.headline)
                .foregroundColor(.green)
                .padding(.horizontal)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text("Text Content:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text(post.textContent)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Image if available
            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                }
            }
            
            // Post button
            Button(action: {
                viewModel.postToSocialMedia(post: post)
            }) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Post to \(post.platformType.rawValue)")
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Content for rejected posts
    private var rejectedContentSection: some View {
        VStack(spacing: 16) {
            // Header
            Text("❌ Rejected Content")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.horizontal)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text("Rejected Text:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text(post.textContent)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // User feedback if available
            if let feedback = post.userFeedback {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Feedback:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text(feedback)
                        .italic()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            
            // Action buttons
            HStack {
                Button(action: {
                    // Delete post
                    viewModel.rejectPost(post: post)
                    dismiss()
                }) {
                    Text("Delete Post")
                        .secondaryButtonStyle()
                }
                
                Button(action: {
                    // Return to main view to create new post
                    dismiss()
                }) {
                    Text("Create New Post")
                        .primaryButtonStyle()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Content for posted content
    private var postedContentSection: some View {
        VStack(spacing: 16) {
            // Header
            Text("✅ Posted Successfully")
                .font(.headline)
                .foregroundColor(.green)
                .padding(.horizontal)
            
            // Post date
            if let postDate = post.postDate {
                Text("Posted on \(postDate.formatted())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text("Posted Content:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text(post.textContent)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Image if available
            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Posted Image:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                }
            }
            
            // Post URL if available
            if let url = post.postUrl {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Post URL:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text(url)
                        .foregroundColor(.blue)
                        .underline()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            
            // Return button
            Button(action: {
                dismiss()
            }) {
                Text("Return to List")
                    .primaryButtonStyle()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // Feedback section
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Provide Feedback")
                .font(.headline)
                .padding(.horizontal)
            
            TextInputArea(
                title: "Your Feedback",
                placeholder: "Provide feedback or suggestions for improvement...",
                text: $viewModel.userFeedback
            )
            .padding(.horizontal)
            
            Button(action: {
                viewModel.applyFeedback(post: post)
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Revise Content")
                }
                .secondaryButtonStyle()
            }
            .padding(.horizontal)
            .disabled(viewModel.userFeedback.isEmpty)
        }
        .padding(.vertical)
    }
    
    // Action buttons
    private var actionButtons: some View {
        HStack {
            // Reject button
            Button(action: {
                viewModel.rejectPost(post: post)
                dismiss()
            }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Reject")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.red)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red, lineWidth: 2)
                )
            }
            
            // Approve button
            Button(action: {
                switch post.reviewStatus {
                case .pendingTextReview:
                    viewModel.approveTextContent(post: post)
                case .pendingGraphicReview:
                    viewModel.approveGraphic(post: post)
                case .pendingMemeReview:
                    viewModel.approveMeme(post: post)
                default:
                    break
                }
            }) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Approve")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // Helper for status icons
    private func statusIcon(_ status: ReviewStatus) -> String {
        switch status {
        case .pendingTextReview, .pendingGraphicReview, .pendingMemeReview:
            return "clock.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        case .posted:
            return "paperplane.fill"
        }
    }
    
    // Helper for status colors
    private func statusColor(_ status: ReviewStatus) -> Color {
        switch status {
        case .pendingTextReview, .pendingGraphicReview, .pendingMemeReview:
            return .orange
        case .approved:
            return .blue
        case .rejected:
            return .red
        case .posted:
            return .green
        }
    }
}
