//
//  Auto_Media_CreatorApp.swift
//  Auto Media Creator
//
//  Created by Scott Campbell on 4/13/25.
//

import SwiftUI
import SwiftData

// Define a class to hold our shared services
class AppServices: ObservableObject {
    let openAIService = OpenAIService()
}

@main
struct Auto_Media_CreatorApp: App {
    // Create shared services
    @StateObject private var appServices = AppServices()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    UserSettings.self,
                    SocialMediaPlatform.self,
                    Post.self,
                    PostGroup.self,
                    ResearchContent.self
                ])
                .environmentObject(appServices)
        }
    }
}
