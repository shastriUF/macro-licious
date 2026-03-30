//
//  macroliciousApp.swift
//  macrolicious
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import SwiftUI

@main
struct macroliciousApp: App {
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let viewModel = AuthViewModel()
        let processInfo = ProcessInfo.processInfo
        let launchArguments = processInfo.arguments
        let launchEnvironment = processInfo.environment
        let shouldLaunchSignedInForUITests = launchArguments.contains("-ui-testing-signed-in")
            || launchEnvironment["UI_TEST_SIGNED_IN"] == "1"

        if shouldLaunchSignedInForUITests {
            viewModel.currentUser = UserProfile(
                id: "ui-test-user",
                email: "ui-test@example.com",
                macroTargets: MacroTargets(calories: 2000, carbs: 220, protein: 140),
                createdAt: "2026-01-01T00:00:00Z",
                updatedAt: "2026-01-01T00:00:00Z"
            )
            viewModel.dailyTotals = MealLogNutrition(calories: 2200, carbs: 180, protein: 150, fat: 70)
        }

        _authViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: authViewModel)
                .onOpenURL { url in
                    Task {
                        await authViewModel.handleAuthCallback(url: url)
                    }
                }
        }
    }
}
