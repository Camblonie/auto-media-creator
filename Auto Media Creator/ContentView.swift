//
//  ContentView.swift
//  Auto Media Creator
//
//  Created by Scott Campbell on 4/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Environment dependencies
    @Environment(\.modelContext) private var modelContext
    
    // State for app flow
    @Binding var onboardingCompleted: Bool
    
    var body: some View {
        ZStack {
            if onboardingCompleted {
                // Main app interface
                MainView(modelContext: modelContext)
            } else {
                // Onboarding flow
                OnboardingView(onboardingCompleted: $onboardingCompleted)
            }
        }
    }
}

#Preview {
    ContentView(onboardingCompleted: .constant(true))
        .modelContainer(for: [Item.self, UserSettings.self, SocialMediaPlatform.self, Post.self, PostGroup.self], inMemory: true)
}
