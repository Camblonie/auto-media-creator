import SwiftUI
import SwiftData

struct PendingPostsView: View {
    // Environment and data dependencies
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReviewViewModel
    @State private var selectedPost: Post? = nil
    
    init(modelContext: ModelContext) {
        // Initialize view model with modelContext
        _viewModel = StateObject(wrappedValue: ReviewViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            if viewModel.pendingPosts.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // List of pending posts
                pendingPostsListView
            }
        }
        .navigationDestination(item: $selectedPost) { post in
            ReviewPostView(post: post, viewModel: viewModel)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Loading posts...")
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
        .onAppear {
            viewModel.loadPendingPosts()
        }
    }
    
    // MARK: - Subviews
    
    // Header view
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primaryColor)
            }
            
            Spacer()
            
            Text("Pending Posts")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Refresh button
            Button(action: {
                // Force reload pending posts
                viewModel.loadPendingPosts()
            }) {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.backgroundColor)
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Pending Posts")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Create posts from the main screen to see them here for review")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text("Return to Main Screen")
                    .secondaryButtonStyle()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundColor)
    }
    
    // List of pending posts
    private var pendingPostsListView: some View {
        VStack {
            if viewModel.pendingPosts.isEmpty {
                // Backup empty state in case the list is empty but not caught earlier
                emptyStateView
            } else {
                List {
                    // Group posts by type
                    Section(header: Text("Traditional Posts")) {
                        let traditionalPosts = viewModel.pendingPosts.filter { $0.postType == .traditional }
                        if traditionalPosts.isEmpty {
                            Text("No traditional posts pending review")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 8)
                        } else {
                            ForEach(traditionalPosts, id: \.id) { post in
                                PendingPostRow(post: post)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPost = post
                                    }
                            }
                        }
                    }
                    
                    Section(header: Text("Meme Posts")) {
                        let memePosts = viewModel.pendingPosts.filter { $0.postType == .meme }
                        if memePosts.isEmpty {
                            Text("No meme posts pending review")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 8)
                        } else {
                            ForEach(memePosts, id: \.id) { post in
                                PendingPostRow(post: post)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPost = post
                                    }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    // Allow pull-to-refresh to reload posts
                    viewModel.loadPendingPosts()
                }
            }
        }
    }
}

// MARK: - Helper Views

// Pending post row
struct PendingPostRow: View {
    let post: Post
    
    var body: some View {
        HStack {
            // Platform icon
            Image(systemName: post.platformType.icon)
                .foregroundColor(.primaryColor)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                // Post type and platform
                HStack {
                    Text(post.postType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(post.postType == .traditional ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(post.platformType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Post content preview
                Text(post.textContent.isEmpty ? post.userInputPrompt : post.textContent)
                    .font(.subheadline)
                    .lineLimit(2)
                
                // Status and timestamp
                HStack {
                    Text(post.reviewStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(statusColor(post.reviewStatus))
                    
                    Spacer()
                    
                    Text(post.creationDate.relativeTime())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
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
