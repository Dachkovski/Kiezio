//
//  ContentView.swift
//  Kiezio
//
//  Created by Dennis Dachkovski on 10.05.26.
//

import SwiftUI

struct ContentView: View {
    @State private var onboardingCompleted = UserDefaults.standard.bool(forKey: AppConfiguration.onboardingCompletedKey)

    var body: some View {
        if onboardingCompleted {
            HomeView {
                UserDefaults.standard.set(false, forKey: AppConfiguration.onboardingCompletedKey)
                onboardingCompleted = false
            }
        } else {
            OnboardingView(isCompleted: $onboardingCompleted)
        }
    }
}

#Preview {
    ContentView()
}
