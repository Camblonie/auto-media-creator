//
//  Auto_Media_CreatorApp.swift
//  Auto Media Creator
//
//  Created by Scott Campbell on 4/13/25.
//

import SwiftUI
import SwiftData

@main
struct Auto_Media_CreatorApp: App {
    // SwiftData model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            UserSettings.self,
            SocialMediaPlatform.self,
            Post.self,
            PostGroup.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // State for app flow
    @State private var onboardingCompleted = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(onboardingCompleted: $onboardingCompleted)
                .onAppear {
                    checkOnboardingStatus()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Check if onboarding has been completed
    private func checkOnboardingStatus() {
        let context = sharedModelContainer.mainContext
        let fetchDescriptor = FetchDescriptor<UserSettings>()
        
        do {
            let settings = try context.fetch(fetchDescriptor)
            if let settings = settings.first {
                onboardingCompleted = settings.onboardingCompleted
            }
        } catch {
            print("Failed to fetch user settings: \(error.localizedDescription)")
        }
    }
}
