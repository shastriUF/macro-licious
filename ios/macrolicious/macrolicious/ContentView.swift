//
//  ContentView.swift
//  macrolicious
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import SwiftUI

@MainActor
struct ContentView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var editingIngredient: Ingredient?
    @State private var editName = ""
    @State private var editBrand = ""
    @State private var editCalories = ""
    @State private var editCarbs = ""
    @State private var editProtein = ""
    @State private var editFat = ""

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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

                    if viewModel.showsManualTokenEntry {
                        TextField("Token", text: $viewModel.token)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button("Verify Magic Link") {
                            Task {
                                await viewModel.verifyMagicLink()
                            }
                        }
                        .disabled(viewModel.token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Text("Check your email and tap the link to return to the app.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
                        }

                        TextField("Calories", text: $viewModel.caloriesInput)
                            .keyboardType(.numberPad)
                        TextField("Carbs", text: $viewModel.carbsInput)
                            .keyboardType(.numberPad)
                        TextField("Protein", text: $viewModel.proteinInput)
                            .keyboardType(.numberPad)

                        Button("Save Macro Targets") {
                            Task {
                                await viewModel.saveMacroTargets()
                            }
                        }
                    } else {
                        Text("No signed-in user")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Ingredients") {
                    Button("Refresh Ingredients") {
                        Task {
                            await viewModel.refreshIngredients()
                        }
                    }

                    TextField("Name", text: $viewModel.ingredientNameInput)
                    TextField("Brand (optional)", text: $viewModel.ingredientBrandInput)
                    TextField("Calories / 100g", text: $viewModel.ingredientCaloriesInput)
                        .keyboardType(.decimalPad)
                    TextField("Carbs / 100g", text: $viewModel.ingredientCarbsInput)
                        .keyboardType(.decimalPad)
                    TextField("Protein / 100g", text: $viewModel.ingredientProteinInput)
                        .keyboardType(.decimalPad)
                    TextField("Fat / 100g", text: $viewModel.ingredientFatInput)
                        .keyboardType(.decimalPad)

                    Button("Create Ingredient") {
                        Task {
                            await viewModel.createIngredient()
                        }
                    }

                    if viewModel.ingredients.isEmpty {
                        Text("No ingredients yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.ingredients) { ingredient in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(ingredient.name)
                                    .font(.headline)

                                Text("P \(Int(ingredient.proteinPer100g)) • C \(Int(ingredient.carbsPer100g)) • F \(Int(ingredient.fatPer100g)) • kcal \(Int(ingredient.caloriesPer100g))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Button("Edit") {
                                        beginEdit(ingredient)
                                    }

                                    Spacer()

                                    Button("Archive", role: .destructive) {
                                        Task {
                                            await viewModel.archiveIngredient(ingredient.id)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
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
            .sheet(item: $editingIngredient) { ingredient in
                NavigationStack {
                    Form {
                        Section("Edit Ingredient") {
                            TextField("Name", text: $editName)
                            TextField("Brand (optional)", text: $editBrand)
                            TextField("Calories / 100g", text: $editCalories)
                                .keyboardType(.decimalPad)
                            TextField("Carbs / 100g", text: $editCarbs)
                                .keyboardType(.decimalPad)
                            TextField("Protein / 100g", text: $editProtein)
                                .keyboardType(.decimalPad)
                            TextField("Fat / 100g", text: $editFat)
                                .keyboardType(.decimalPad)
                        }
                    }
                    .navigationTitle(ingredient.name)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                editingIngredient = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task {
                                    await saveEditedIngredient(ingredient)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func beginEdit(_ ingredient: Ingredient) {
        editName = ingredient.name
        editBrand = ingredient.brand ?? ""
        editCalories = String(ingredient.caloriesPer100g)
        editCarbs = String(ingredient.carbsPer100g)
        editProtein = String(ingredient.proteinPer100g)
        editFat = String(ingredient.fatPer100g)
        editingIngredient = ingredient
    }

    private func saveEditedIngredient(_ ingredient: Ingredient) async {
        guard
            let calories = Double(editCalories),
            let carbs = Double(editCarbs),
            let protein = Double(editProtein),
            let fat = Double(editFat),
            calories >= 0,
            carbs >= 0,
            protein >= 0,
            fat >= 0,
            !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        let updatedIngredient = Ingredient(
            id: ingredient.id,
            userId: ingredient.userId,
            name: editName,
            brand: editBrand.isEmpty ? nil : editBrand,
            barcode: ingredient.barcode,
            caloriesPer100g: calories,
            carbsPer100g: carbs,
            proteinPer100g: protein,
            fatPer100g: fat,
            archived: ingredient.archived,
            createdAt: ingredient.createdAt,
            updatedAt: ingredient.updatedAt
        )

        await viewModel.updateIngredient(updatedIngredient)
        editingIngredient = nil
    }
}

#Preview {
    ContentView(viewModel: AuthViewModel())
}
