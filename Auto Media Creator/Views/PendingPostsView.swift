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
        // Filtering logic must be outside the view builder to avoid SwiftUI generic parameter errors
        let traditionalPosts = viewModel.pendingPosts.filter { $0.postType == .traditional }
        let memePosts = viewModel.pendingPosts.filter { $0.postType == .meme }
        
        return Group {
            if viewModel.pendingPosts.isEmpty {
                // Backup empty state in case the list is empty but not caught earlier
                emptyStateView
            } else {
                List {
                    // Group posts by type
                    Section {
                        ForEach(traditionalPosts) { post in
                            ZStack {
                                PendingPostRow(post: post)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPost = post
                                    }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deletePost(post)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .font(.title3)
                                }
                                .tint(.red)
                            }
                        }
                    } header: {
                        Text("Traditional Posts")
                    }
                    
                    Section {
                        ForEach(memePosts) { post in
                            ZStack {
                                PendingPostRow(post: post)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPost = post
                                    }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deletePost(post)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .font(.title3)
                                }
                                .tint(.red)
                            }
                        }
                    } header: {
                        Text("Meme Posts")
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .background(Color.backgroundColor)
                .refreshable {
                    // Allow pull-to-refresh to reload posts
                    viewModel.loadPendingPosts()
                }
            }
        }
    }
    
    // Helper view for traditional posts content
    private struct TraditionalPostsContent: View {
        let posts: [Post]
        let onTap: (Post) -> Void
        let onDelete: (IndexSet) -> Void
        
        var body: some View {
            if posts.isEmpty {
                Text("No traditional posts pending review")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                ForEach(posts, id: \.id) { post in
                    PendingPostRow(post: post)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTap(post)
                        }
                }
                .onDelete(perform: onDelete)
            }
        }
    }
    
    // Helper view for meme posts content
    private struct MemePostsContent: View {
        let posts: [Post]
        let onTap: (Post) -> Void
        let onDelete: (IndexSet) -> Void
        
        var body: some View {
            if posts.isEmpty {
                Text("No meme posts pending review")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                ForEach(posts, id: \.id) { post in
                    PendingPostRow(post: post)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTap(post)
                        }
                }
                .onDelete(perform: onDelete)
            }
        }
    }
}

// MARK: - Helper Views

// Pending post row
struct PendingPostRow: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Platform icon with background
            ZStack {
                Circle()
                    .fill(Color.primaryColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: post.platformType.icon)
                    .foregroundColor(.primaryColor)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Post type and platform
                HStack {
                    Text(post.postType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(post.postType == .traditional ? Color.primaryColor.opacity(0.2) : Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(post.platformType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondaryColor)
                }
                
                // Post content preview
                Text(post.textContent.isEmpty ? post.userInputPrompt : post.textContent)
                    .font(.subheadline)
                    .lineLimit(2)
                    .padding(.vertical, 2)
                
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
            
            // Chevron with better tap area
            Image(systemName: "chevron.right")
                .foregroundColor(.secondaryColor)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Make entire row tappable
        .background(Color.backgroundColor) // Ensure background is tappable
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
