import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    // Environment and data dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // State for settings
    @Query private var userSettings: [UserSettings]
    @Query private var platforms: [SocialMediaPlatform]
    
    // View model
    private let socialMediaService: SocialMediaService
    
    // State for form fields
    @State private var businessName = ""
    @State private var apiKey = ""
    @State private var defaultTags = ""
    @State private var selectedLogo: PhotosPickerItem?
    @State private var logoImage: UIImage?
    
    // States for API testing
    @State private var isTestingAPI = false
    @State private var apiTestResult: APITestResult?
    
    // State for authentication
    @State private var selectedPlatform: SocialMediaPlatform?
    @State private var showAuthSheet = false
    @State private var username = ""
    @State private var password = ""
    
    // State for platform configuration
    @State private var showPromptConfig = false
    @State private var selectedPromptPlatform: SocialMediaPlatform?
    
    // State for alerts
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    init(modelContext: ModelContext) {
        self.socialMediaService = SocialMediaService(modelContext: modelContext)
    }
    
    var body: some View {
        List {
            // General settings section
            Section(header: Text("General Settings")) {
                // Business name
                TextField("Business Name", text: $businessName)
                
                // Logo picker
                HStack {
                    Text("Business Logo")
                    Spacer()
                    PhotosPicker(selection: $selectedLogo, matching: .images) {
                        if let logoImage = logoImage {
                            Image(uiImage: logoImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo.circle")
                                .font(.title)
                                .foregroundColor(.primaryColor)
                        }
                    }
                }
                
                // OpenAI API key settings section
                Section(header: Text("API Settings")) {
                    Text("OpenAI API Key")
                        .font(.headline)
                    
                    SecureField("Enter your API key", text: $apiKey)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.default)
                    
                    // Test API Connection button
                    Button(action: {
                        testAPIConnection()
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("Test API Connection")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(apiKey.isEmpty || isTestingAPI)
                    
                    // Show loading indicator while testing
                    if isTestingAPI {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Testing connection...")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Show test result if available
                    if let result = apiTestResult {
                        HStack {
                            Image(systemName: result.color == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.color)
                            Text(result.message)
                                .foregroundColor(result.color)
                        }
                        .padding(.vertical, 10)
                    }
                    
                    Text("Default Hashtags")
                        .font(.headline)
                        .padding(.top)
                    
                    TextField("Enter default hashtags", text: $defaultTags)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Platform connections section
                Section(header: Text("Platform Connections")) {
                    ForEach(platforms, id: \.type) { platform in
                        platformRow(platform)
                    }
                }
                
                // Platform configuration section
                Section(header: Text("Platform Configuration")) {
                    ForEach(platforms, id: \.type) { platform in
                        Button(action: {
                            selectedPromptPlatform = platform
                            showPromptConfig = true
                        }) {
                            HStack {
                                Image(systemName: platform.type.icon)
                                    .foregroundColor(.primaryColor)
                                
                                Text("\(platform.type.rawValue) Prompt Settings")
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveSettings()
                    dismiss()
                }) {
                    Text("Save")
                }
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showAuthSheet) {
            if let platform = selectedPlatform {
                authenticationSheet(platform: platform)
            }
        }
        .navigationDestination(isPresented: $showPromptConfig) {
            if let platform = selectedPromptPlatform {
                PromptConfigView(platform: platform)
            }
        }
        .overlay {
            if isLoading {
                LoadingView(message: "Processing...")
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: selectedLogo) { _, newValue in
            loadImageFromPicker(newValue)
        }
    }
    
    // MARK: - Platform Row
    private func platformRow(_ platform: SocialMediaPlatform) -> some View {
        HStack {
            Image(systemName: platform.type.icon)
                .foregroundColor(.primaryColor)
            
            Text(platform.type.rawValue)
            
            Spacer()
            
            if platform.isAuthenticated {
                // Connected state
                HStack {
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Button(action: {
                        // Disconnect
                        platform.isAuthenticated = false
                        platform.authToken = nil
                        try? modelContext.save()
                    }) {
                        Text("Disconnect")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            } else {
                // Connect button
                Button(action: {
                    selectedPlatform = platform
                    showAuthSheet = true
                }) {
                    Text("Connect")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Authentication Sheet
    private func authenticationSheet(platform: SocialMediaPlatform) -> some View {
        Form {
            Section(header: Text("Connect to \(platform.type.rawValue)")) {
                TextField("Username or Email", text: $username)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                
                Button(action: {
                    connectToPlatform(platform)
                }) {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(username.isEmpty || password.isEmpty)
            }
            
            Section(footer: Text("For demonstration purposes, authentication will be simulated.")) {
                Text("In a production app, this would use OAuth or another secure authentication method provided by the platform.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAuthSheet = false
                }) {
                    Text("Cancel")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Load data
    private func loadData() {
        // Load user settings directly with optional binding instead of do-catch
        if let firstSettings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first {
            apiKey = firstSettings.openAIApiKey
            defaultTags = firstSettings.defaultTags
            businessName = firstSettings.businessName
            
            // Check if we have a logo to display
            if firstSettings.businessLogo != nil {
                logoImage = firstSettings.logoImage
            }
        } else {
            print("No settings found or error loading settings")
        }
    }
    
    // Save settings
    private func saveSettings() {
        if let settings = userSettings.first {
            // Update existing settings
            settings.businessName = businessName
            settings.openAIApiKey = apiKey
            settings.defaultTags = defaultTags
            
            if let logoImage = logoImage, let logoData = logoImage.jpegData(compressionQuality: 0.8) {
                settings.businessLogo = logoData
            }
        } else {
            // Create new settings
            let newSettings = UserSettings(
                businessName: businessName,
                openAIApiKey: apiKey
            )
            
            if let logoImage = logoImage, let logoData = logoImage.jpegData(compressionQuality: 0.8) {
                newSettings.businessLogo = logoData
            }
            
            newSettings.defaultTags = defaultTags.isEmpty ? UserSettings.defaultHashtags : defaultTags
            
            modelContext.insert(newSettings)
        }
        
        // Save changes
        do {
            try modelContext.save()
            
            alertTitle = "Success"
            alertMessage = "Settings saved successfully"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to save settings: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // Connect to platform
    private func connectToPlatform(_ platform: SocialMediaPlatform) {
        isLoading = true
        
        socialMediaService.authenticatePlatform(platform: platform, username: username, password: password) { result in
            isLoading = false
            showAuthSheet = false
            
            switch result {
            case .success:
                alertTitle = "Success"
                alertMessage = "Connected to \(platform.type.rawValue) successfully"
                showAlert = true
                
                // Clear credentials
                username = ""
                password = ""
                
            case .failure(let error):
                alertTitle = "Authentication Failed"
                alertMessage = error.description
                showAlert = true
            }
        }
    }
    
    // Load image from picker
    private func loadImageFromPicker(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.logoImage = image
                    }
                }
            case .failure:
                DispatchQueue.main.async {
                    alertTitle = "Error"
                    alertMessage = "Failed to load image"
                    showAlert = true
                }
            }
        }
    }
    
    // Test API connection
    private func testAPIConnection() {
        isTestingAPI = true
        apiTestResult = nil
        
        let openAIService = OpenAIService()
        openAIService.testAPIConnection(apiKey: apiKey) { result in
            DispatchQueue.main.async {
                isTestingAPI = false
                
                switch result {
                case .success:
                    apiTestResult = .success
                    // If connection was successful, update the stored key
                    if let settings = self.userSettings.first {
                        settings.openAIApiKey = self.apiKey
                        try? self.modelContext.save()
                    }
                case .failure(let error):
                    apiTestResult = .failure(error.localizedDescription)
                }
            }
        }
    }
}

// Enum to represent OpenAI API test results
enum APITestResult {
    case success
    case failure(String)
    
    var message: String {
        switch self {
        case .success:
            return "API connection successful! Your key is valid."
        case .failure(let error):
            return "API connection failed: \(error)"
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
}

// MARK: - Prompt Configuration View
struct PromptConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Changed from @ObservedObject to using a simple binding
    // to avoid ObservableObject conformance issue with SwiftData models
    var platform: SocialMediaPlatform
    
    @State private var promptGuidance: String = ""
    @State private var graphicGuidance: String = ""
    @State private var showAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("\(platform.type.rawValue) Post Prompt"), footer: Text("This guidance will be used to generate the text content for posts.")) {
                TextEditor(text: $promptGuidance)
                    .frame(minHeight: 200)
                
                Button("Reset to Default") {
                    promptGuidance = platform.type.defaultPromptGuidance
                }
            }
            
            Section(header: Text("\(platform.type.rawValue) Graphic Prompt"), footer: Text("This guidance will be used to generate images for posts.")) {
                TextEditor(text: $graphicGuidance)
                    .frame(minHeight: 150)
                
                Button("Reset to Default") {
                    graphicGuidance = platform.type.graphicPromptGuidance
                }
            }
        }
        .navigationTitle("\(platform.type.rawValue) Configuration")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    savePromptSettings()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Settings Saved"),
                message: Text("Your prompt configurations have been updated"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadPromptSettings()
        }
    }
    
    private func loadPromptSettings() {
        promptGuidance = platform.customPromptGuidance
        graphicGuidance = platform.customGraphicPromptGuidance
    }
    
    private func savePromptSettings() {
        platform.customPromptGuidance = promptGuidance
        platform.customGraphicPromptGuidance = graphicGuidance
        
        try? modelContext.save()
        showAlert = true
    }
}
