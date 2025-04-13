import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var currentPage = 0
    @State private var apiKey = ""
    @State private var businessName = ""
    
    // For navigating to main app after onboarding
    @Binding var onboardingCompleted: Bool
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Auto Media Creator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryColor)
                
                Spacer()
                
                // Skip button
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        saveSettings()
                        onboardingCompleted = true
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Page indicator
            HStack {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle()
                        .fill(currentPage == i ? Color.primaryColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom)
            
            // Page content
            TabView(selection: $currentPage) {
                // Welcome page
                welcomeView
                    .tag(0)
                
                // Features page
                featuresView
                    .tag(1)
                
                // Setup page
                setupView
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                // Back button
                if currentPage > 0 {
                    Button(action: {
                        withAnimation {
                            currentPage -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Next/Start button
                Button(action: {
                    withAnimation {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            saveSettings()
                            onboardingCompleted = true
                        }
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.primaryColor)
                .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            // Populate form with existing values if available
            if let settings = userSettings.first {
                apiKey = settings.openAIApiKey
                businessName = settings.businessName
            }
        }
    }
    
    // MARK: - Page Views
    
    // Welcome page
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.primaryColor)
                .padding()
            
            Text("Welcome to Auto Media Creator")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("The ultimate tool for automotive repair shops to create engaging social media content")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // Features page
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Key Features")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
            
            FeatureRow(
                icon: "text.bubble.fill",
                title: "AI-Powered Content",
                description: "Research and create professional social media posts using OpenAI"
            )
            
            FeatureRow(
                icon: "photo.fill",
                title: "Custom Graphics",
                description: "Generate eye-catching graphics for each platform"
            )
            
            FeatureRow(
                icon: "face.smiling.fill",
                title: "Meme Creation",
                description: "Create engaging automotive memes to boost engagement"
            )
            
            FeatureRow(
                icon: "arrow.up.forward.app.fill",
                title: "Multi-Platform Support",
                description: "Post to Facebook, Instagram, TikTok, X, and LinkedIn"
            )
        }
        .padding()
    }
    
    // Setup page
    private var setupView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Setup")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
            
            Text("Let's set up your app with a few basic details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
            
            TextInputField(
                title: "Business Name",
                placeholder: "Enter your business name",
                text: $businessName
            )
            
            TextInputField(
                title: "OpenAI API Key",
                placeholder: "Enter your OpenAI API key",
                text: $apiKey,
                secure: true
            )
            
            Text("You can always change these later in Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
        }
        .padding()
    }
    
    // Helper for saving settings
    private func saveSettings() {
        // Check if settings exist
        if let settings = userSettings.first {
            // Update existing settings
            settings.openAIApiKey = apiKey
            settings.businessName = businessName
            settings.onboardingCompleted = true
        } else {
            // Create new settings
            let newSettings = UserSettings(
                onboardingCompleted: true,
                businessName: businessName,
                openAIApiKey: apiKey
            )
            modelContext.insert(newSettings)
        }
        
        // Save changes
        try? modelContext.save()
    }
    
    // Page data
    private let pages = ["Welcome", "Features", "Setup"]
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.primaryColor)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
