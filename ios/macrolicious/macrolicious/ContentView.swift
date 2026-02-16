//
//  ContentView.swift
//  macrolicious
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend") {
                    TextField("Base URL", text: $viewModel.baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Button("Save Backend URL") {
                        viewModel.saveBaseURL()
                    }
                }

                Section("Sign In") {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    Button("Request Magic Link") {
                        Task {
                            await viewModel.requestMagicLink()
                        }
                    }

                    TextField("Token", text: $viewModel.token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Verify Magic Link") {
                        Task {
                            await viewModel.verifyMagicLink()
                        }
                    }
                }

                Section("Profile") {
                    Button("Refresh Profile") {
                        Task {
                            await viewModel.refreshProfile()
                        }
                    }

                    Button("Sign Out", role: .destructive) {
                        viewModel.signOut()
                    }

                    if let user = viewModel.currentUser {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email: \(user.email)")
                            Text("Calories: \(Int(user.macroTargets.calories))")
                            Text("Carbs: \(Int(user.macroTargets.carbs))")
                            Text("Protein: \(Int(user.macroTargets.protein))")
                        }
                    } else {
                        Text("No signed-in user")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Status") {
                    if viewModel.isLoading {
                        ProgressView()
                    }

                    Text(viewModel.statusMessage.isEmpty ? "Ready" : viewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("MacroLicious")
        }
    }
}

#Preview {
    ContentView()
}
