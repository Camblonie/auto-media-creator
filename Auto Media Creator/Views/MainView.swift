import SwiftUI
import SwiftData

struct MainView: View {
    // Environment and data dependencies
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: MainViewModel
    
    // Navigation states
    @State private var showSettings = false
    @State private var showPendingPosts = false
    @State private var showStatistics = false
    @State private var selectedTab = 0
    
    init(modelContext: ModelContext) {
        // Initialize view model with modelContext
        _viewModel = StateObject(wrappedValue: MainViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Platform toggle section
                platformToggleSection
                
                // Main content
                TabView(selection: $selectedTab) {
                    // Traditional post tab
                    traditionalPostView
                        .tag(0)
                    
                    // Meme post tab
                    memePostView
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom tab bar
                customTabBar
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(modelContext: modelContext)
            }
            .navigationDestination(isPresented: $showPendingPosts) {
                PendingPostsView(modelContext: modelContext)
            }
            .navigationDestination(isPresented: $showStatistics) {
                StatisticsView(modelContext: modelContext)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "Working on your content...")
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
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Subviews
    
    // Header view with title and action buttons
    private var headerView: some View {
        HStack {
            Text("Auto Media Creator")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryColor)
            
            Spacer()
            
            // Pending posts button
            Button(action: {
                showPendingPosts = true
            }) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(.primaryColor)
            }
            .padding(.horizontal, 8)
            
            // Statistics button
            Button(action: {
                showStatistics = true
            }) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.primaryColor)
            }
            .padding(.horizontal, 8)
            
            // Settings button
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.primaryColor)
            }
            .padding(.horizontal, 8)
        }
        .padding()
        .background(Color.backgroundColor)
    }
    
    // Platform toggle section
    private var platformToggleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Platforms")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.platforms, id: \.type) { platform in
                        PlatformToggleButton(
                            platform: platform.type,
                            isActive: platform.isActive,
                            isAuthenticated: platform.isAuthenticated,
                            toggleAction: {
                                viewModel.updatePlatformStatus(platform: platform, isActive: !platform.isActive)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
        }
        .padding(.top)
        .background(Color.backgroundColor)
    }
    
    // Traditional post view
    private var traditionalPostView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            SectionHeader(
                title: "Create Traditional Post",
                systemImage: "text.bubble.fill"
            )
            
            VStack(spacing: 16) {
                Text("Create an engaging social media post based on automotive repair news and trends")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Input field
                TextInputArea(
                    title: "Topic (optional)",
                    placeholder: "Enter a specific topic or leave blank for general automotive news",
                    text: $viewModel.traditionalPostInput
                )
                .padding(.horizontal)
                
                // Create post button
                Button(action: {
                    viewModel.createTraditionalPost()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Post")
                        Image(systemName: "sparkles")
                    }
                    .primaryButtonStyle()
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                // Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("What happens next?")
                        .font(.headline)
                    
                    InfoRow(
                        step: "1",
                        description: "OpenAI researches current automotive topics"
                    )
                    
                    InfoRow(
                        step: "2",
                        description: "Customized posts for each platform are created"
                    )
                    
                    InfoRow(
                        step: "3",
                        description: "Review and approve posts before publishing"
                    )
                }
                .padding()
                .background(Color.cardBackgroundColor)
                .cornerRadius(10)
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.backgroundColor)
    }
    
    // Meme post view
    private var memePostView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            SectionHeader(
                title: "Create Meme Post",
                systemImage: "face.smiling.fill"
            )
            
            VStack(spacing: 16) {
                Text("Create a humorous automotive meme to engage your audience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Input field
                TextInputArea(
                    title: "Meme Topic (optional)",
                    placeholder: "Enter a specific topic or leave blank for a random automotive meme",
                    text: $viewModel.memePostInput
                )
                .padding(.horizontal)
                
                // Create meme button
                Button(action: {
                    viewModel.createMemePost()
                }) {
                    HStack {
                        Image(systemName: "face.smiling")
                        Text("Generate Meme")
                        Image(systemName: "face.smiling")
                    }
                    .primaryButtonStyle()
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                // Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meme Creation Process")
                        .font(.headline)
                    
                    InfoRow(
                        step: "1",
                        description: "AI creates a humorous automotive repair meme concept"
                    )
                    
                    InfoRow(
                        step: "2",
                        description: "An image with text overlay is generated"
                    )
                    
                    InfoRow(
                        step: "3",
                        description: "Review and approve before publishing"
                    )
                }
                .padding()
                .background(Color.cardBackgroundColor)
                .cornerRadius(10)
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.backgroundColor)
    }
    
    // Custom tab bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            // Traditional posts tab
            Button(action: {
                withAnimation {
                    selectedTab = 0
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "text.bubble.fill" : "text.bubble")
                        .font(.system(size: 20))
                    
                    Text("Traditional")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 0 ? .primaryColor : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Memes tab
            Button(action: {
                withAnimation {
                    selectedTab = 1
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "face.smiling.fill" : "face.smiling")
                        .font(.system(size: 20))
                    
                    Text("Memes")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 1 ? .primaryColor : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .background(Color.backgroundColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.2)),
            alignment: .top
        )
    }
}

// MARK: - Helper Views

// Platform toggle button
struct PlatformToggleButton: View {
    let platform: PlatformType
    let isActive: Bool
    let isAuthenticated: Bool
    let toggleAction: () -> Void
    
    var body: some View {
        VStack {
            Button(action: toggleAction) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(isActive ? Color.primaryColor : Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: platform.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Text(platform.rawValue)
                        .font(.caption)
                        .foregroundColor(isActive ? .primary : .secondary)
                    
                    // Authentication indicator
                    if isAuthenticated {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                    }
                }
            }
        }
    }
}

// Info row for steps
struct InfoRow: View {
    let step: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.primaryColor)
                .cornerRadius(12)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
