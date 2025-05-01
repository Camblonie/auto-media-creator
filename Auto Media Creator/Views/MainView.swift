import SwiftUI
import SwiftData

struct MainView: View {
    // Environment and data dependencies
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appServices: AppServices
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
                VStack(spacing: 0) {
                    Text("Auto Media Creator")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryColor)
                    
                    if let headline = viewModel.currentTopic?.headline {
                        Text(headline)
                            .font(.subheadline)
                            .foregroundColor(.secondaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.backgroundColor)
                
                // Platform toggle section
                platformToggleSection
                    .padding(.vertical, 10)
                    .background(Color.cardBackgroundColor)
                
                // Main content
                TabView(selection: $selectedTab) {
                    // Topic tab
                    TopicView(modelContext: modelContext, openAIService: appServices.openAIService)
                        .tag(0)
                    
                    // Create Post tab
                    createPostView
                        .tag(1)
                    
                    // Create Meme tab
                    createMemeView
                        .tag(2)
                    
                    // Pending Posts tab
                    PendingPostsView(modelContext: modelContext)
                        .tag(3)
                    
                    // Statistics tab
                    StatisticsView(modelContext: modelContext)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.none, value: selectedTab) // Use the non-deprecated version with a value parameter
                .gesture(DragGesture()) // Add empty drag gesture to disable swipe
                
                // Custom tab bar
                customTabBar
            }
            .background(Color.backgroundColor)
            .overlay(
                // Add a subtle gradient at the top
                LinearGradient(
                    gradient: Gradient(colors: [Color.darkAccentColor.opacity(0.05), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false),
                alignment: .top
            )
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(modelContext: modelContext)
                    .navigationBarBackButtonHidden(true)
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
            .alert(isPresented: $viewModel.showDraftCreatedAlert) {
                Alert(
                    title: Text("Draft Created"),
                    message: Text("A new post has been generated and can be reviewed in the Pending Posts area."),
                    dismissButton: .default(Text("OK"))
                )
            }
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
                HStack(spacing: 16) {
                    ForEach(viewModel.platforms, id: \.type) { platform in
                        PlatformToggleButton(
                            platform: platform.type,
                            isActive: platform.isActive,
                            isAuthenticated: platform.isAuthenticated,
                            toggleAction: {
                                viewModel.togglePlatform(platform)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
        }
        .padding(.top)
    }
    
    // Create Post View
    private var createPostView: some View {
        VStack {
            if let headline = viewModel.currentTopic?.headline,
               let summary = viewModel.currentTopic?.summary {
                CreatePostView(
                    openAIService: appServices.openAIService,
                    modelContext: modelContext,
                    topicHeadline: headline,
                    topicSummary: summary
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    
                    Text("No Topic Selected")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Please generate a topic first in the Topic tab")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        selectedTab = 0
                    }) {
                        Text("Go to Topic Tab")
                            .primaryButtonStyle()
                    }
                }
                .padding()
            }
        }
        .background(Color.backgroundColor)
    }
    
    // Create Meme View
    private var createMemeView: some View {
        VStack {
            if let headline = viewModel.currentTopic?.headline,
               let summary = viewModel.currentTopic?.summary {
                CreateMemeView(
                    openAIService: appServices.openAIService,
                    modelContext: modelContext,
                    topicHeadline: headline,
                    topicSummary: summary
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    
                    Text("No Topic Selected")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Please generate a topic first in the Topic tab")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        selectedTab = 0
                    }) {
                        Text("Go to Topic Tab")
                            .primaryButtonStyle()
                    }
                }
                .padding()
            }
        }
        .background(Color.backgroundColor)
    }
    
    // Custom tab bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            // Topic tab
            Button(action: {
                selectedTab = 0
            }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: 20))
                    
                    Text("Topic")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 0 ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Create Post tab
            Button(action: {
                selectedTab = 1
            }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "square.and.pencil.circle.fill" : "square.and.pencil.circle")
                        .font(.system(size: 20))
                    
                    Text("Post")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 1 ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Create Meme tab
            Button(action: {
                selectedTab = 2
            }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 2 ? "photo.fill" : "photo")
                        .font(.system(size: 20))
                    
                    Text("Meme")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 2 ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Pending Posts tab
            Button(action: {
                selectedTab = 3
            }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 3 ? "clock.fill" : "clock")
                        .font(.system(size: 20))
                    
                    Text("Pending")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 3 ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Statistics tab
            Button(action: {
                selectedTab = 4
            }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 4 ? "chart.bar.fill" : "chart.bar")
                        .font(.system(size: 20))
                    
                    Text("Stats")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 4 ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(Color.backgroundColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.darkAccentColor.opacity(0.1)),
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
                            .fill(isActive ? Color.primaryColor : Color.darkAccentColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                        // Use custom LinkedIn image for LinkedIn platform, SF Symbols for others
                        if platform == .linkedin {
                            // Prefer the white circle version if available, fallback to the plain version
                            if let _ = UIImage(named: "linkedin_white_circle") {
                                Image("linkedin_white_circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .accessibilityLabel("LinkedIn")
                            } else {
                                Image("linkedin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .accessibilityLabel("LinkedIn")
                            }
                        } else {
                            Image(systemName: platform.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: isActive ? Color.primaryColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                    
                    Text(platform.rawValue)
                        .font(.caption)
                        .fontWeight(isActive ? .semibold : .regular)
                        .foregroundColor(isActive ? .primaryColor : .secondary)
                    
                    // Authentication indicator
                    if isAuthenticated {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.secondaryColor)
                            .font(.system(size: 12))
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 12))
                    }
                }
            }
        }
    }
}
