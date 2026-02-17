//
//  macroliciousApp.swift
//  macrolicious
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import SwiftUI

@main
struct macroliciousApp: App {
    @StateObject private var authViewModel = AuthViewModel()

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
