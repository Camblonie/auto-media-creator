//
//  ContentView.swift
//  Auto Media Creator
//
//  Created by Scott Campbell on 4/13/25.
//

import SwiftUI
import SwiftData

// Placeholder ContentView for new app start
struct ContentView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appServices: AppServices
    
    var body: some View {
        MainView(modelContext: modelContext)
            .onAppear {
                // Initialize OpenAI service with API key from settings
                let fetchDescriptor = FetchDescriptor<UserSettings>()
                if let settings = try? modelContext.fetch(fetchDescriptor).first,
                   !settings.openAIApiKey.isEmpty {
                    appServices.openAIService.setAPIKey(settings.openAIApiKey)
                    print("OpenAI service initialized with stored API key")
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [
                UserSettings.self,
                SocialMediaPlatform.self,
                Post.self,
                PostGroup.self,
                ResearchContent.self
            ])
            .environmentObject(AppServices())
    }
}
