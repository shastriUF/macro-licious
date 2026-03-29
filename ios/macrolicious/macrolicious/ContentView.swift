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
    @State private var archiveCandidate: Ingredient?
    @State private var editingMealLog: MealLog?
    @State private var deleteMealLogCandidate: MealLog?
    @State private var editName = ""
    @State private var editBrand = ""
    @State private var editDensity = ""
    @State private var editCalories = ""
    @State private var editCarbs = ""
    @State private var editProtein = ""
    @State private var editFat = ""
    @State private var editMealType: MealType = .breakfast
    @State private var editMealNotes = ""

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
                        Task {
                            await viewModel.signOut()
                        }
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

                Section("Diary") {
                    DatePicker("Date", selection: $viewModel.diaryDate, displayedComponents: .date)

                    Button("Refresh Diary") {
                        Task {
                            await viewModel.refreshMealLogs()
                        }
                    }

                    Picker("Meal Type", selection: $viewModel.selectedMealType) {
                        ForEach(MealType.allCases) { mealType in
                            Text(mealType.label).tag(mealType)
                        }
                    }

                    TextField("Notes (optional)", text: $viewModel.mealNotesInput)
                    Toggle("Use Ingredient Library", isOn: $viewModel.useIngredientForMealLog)

                    if viewModel.useIngredientForMealLog {
                        if viewModel.ingredients.isEmpty {
                            Text("No ingredients yet. Create one below or switch to manual entry.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Ingredient", selection: $viewModel.selectedMealIngredientId) {
                                ForEach(viewModel.ingredients) { ingredient in
                                    Text(ingredient.name).tag(ingredient.id)
                                }
                            }
                            .pickerStyle(.menu)

                            if let ingredient = viewModel.selectedMealIngredient {
                                Text(
                                    "Per 100g: kcal \(Int(ingredient.caloriesPer100g)) • C \(Int(ingredient.carbsPer100g)) • P \(Int(ingredient.proteinPer100g)) • F \(Int(ingredient.fatPer100g))"
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                                if let density = ingredient.densityGPerMl {
                                    Text("Density: \(density, specifier: "%.2f") g/ml")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        TextField("Ingredient name", text: $viewModel.mealIngredientNameInput)
                    }

                    HStack {
                        TextField("Quantity", text: $viewModel.mealQuantityValueInput)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $viewModel.mealQuantityUnit) {
                            ForEach(QuantityUnit.allCases, id: \.rawValue) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if viewModel.useIngredientForMealLog {
                        if let preview = viewModel.mealLogPreview {
                            Text(
                                "Computed: \(preview.consumedGrams, specifier: "%.1f")g • kcal \(Int(preview.nutrition.calories)) • C \(Int(preview.nutrition.carbs)) • P \(Int(preview.nutrition.protein)) • F \(Int(preview.nutrition.fat))"
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        } else if !viewModel.mealQuantityValueInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Unable to compute nutrition. Use a mass unit or ensure the ingredient has density for volume units.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        TextField("Consumed grams", text: $viewModel.mealConsumedGramsInput)
                            .keyboardType(.decimalPad)
                        TextField("Calories", text: $viewModel.mealCaloriesInput)
                            .keyboardType(.decimalPad)
                        TextField("Carbs", text: $viewModel.mealCarbsInput)
                            .keyboardType(.decimalPad)
                        TextField("Protein", text: $viewModel.mealProteinInput)
                            .keyboardType(.decimalPad)
                        TextField("Fat", text: $viewModel.mealFatInput)
                            .keyboardType(.decimalPad)
                    }

                    Button("Add Meal Log Entry") {
                        Task {
                            await viewModel.createMealLog()
                        }
                    }

                    Text(
                        "Totals: kcal \(Int(viewModel.dailyTotals.calories)) • C \(Int(viewModel.dailyTotals.carbs)) • P \(Int(viewModel.dailyTotals.protein)) • F \(Int(viewModel.dailyTotals.fat))"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    if viewModel.mealLogs.isEmpty {
                        Text("No meal logs for selected date")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.mealLogs) { mealLog in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(mealLog.mealType.label)
                                        .font(.headline)
                                    Spacer()
                                    Text(mealLog.date)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                if let notes = mealLog.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(mealLog.items) { item in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.ingredientName)
                                        Text(
                                            "\(item.quantityValue, specifier: "%.2f") \(item.quantityUnit.label) • \(item.consumedGrams, specifier: "%.1f")g • kcal \(Int(item.nutrition.calories))"
                                        )
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button("Edit") {
                                    beginMealLogEdit(mealLog)
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    deleteMealLogCandidate = mealLog
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Ingredients") {
                    Button("Refresh Ingredients") {
                        Task {
                            await viewModel.refreshIngredients()
                        }
                    }

                    Toggle("Produce Quick Add", isOn: $viewModel.isProduceModeEnabled)

                    if viewModel.isProduceModeEnabled {
                        Text("Produce mode is weight-first: name + macros per 100g, brand optional.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Name", text: $viewModel.ingredientNameInput)
                    if !viewModel.isProduceModeEnabled {
                        TextField("Brand (optional)", text: $viewModel.ingredientBrandInput)
                    }
                    TextField("Density g/ml (optional)", text: $viewModel.ingredientDensityInput)
                        .keyboardType(.decimalPad)
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

                                if let density = ingredient.densityGPerMl {
                                    Text("Density: \(density, specifier: "%.2f") g/ml")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button("Edit") {
                                    beginEdit(ingredient)
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Archive", role: .destructive) {
                                    archiveCandidate = ingredient
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
            .onChange(of: viewModel.diaryDate) { _, _ in
                Task {
                    await viewModel.refreshMealLogs()
                }
            }
            .confirmationDialog(
                "Archive ingredient?",
                isPresented: Binding(
                    get: { archiveCandidate != nil },
                    set: { isPresented in
                        if !isPresented {
                            archiveCandidate = nil
                        }
                    }
                ),
                titleVisibility: .visible,
                presenting: archiveCandidate
            ) { ingredient in
                Button("Archive \(ingredient.name)", role: .destructive) {
                    Task {
                        await viewModel.archiveIngredient(ingredient.id)
                    }
                    archiveCandidate = nil
                }

                Button("Cancel", role: .cancel) {
                    archiveCandidate = nil
                }
            } message: { ingredient in
                Text("\(ingredient.name) will be hidden from the default ingredient list.")
            }
            .confirmationDialog(
                "Delete meal log?",
                isPresented: Binding(
                    get: { deleteMealLogCandidate != nil },
                    set: { isPresented in
                        if !isPresented {
                            deleteMealLogCandidate = nil
                        }
                    }
                ),
                titleVisibility: .visible,
                presenting: deleteMealLogCandidate
            ) { mealLog in
                Button("Delete \(mealLog.mealType.label)", role: .destructive) {
                    Task {
                        await viewModel.deleteMealLog(mealLog.id)
                    }
                    deleteMealLogCandidate = nil
                }

                Button("Cancel", role: .cancel) {
                    deleteMealLogCandidate = nil
                }
            } message: { mealLog in
                Text("This will remove the \(mealLog.mealType.label.lowercased()) meal log entry for \(mealLog.date).")
            }
            .sheet(item: $editingIngredient) { ingredient in
                NavigationStack {
                    Form {
                        Section("Edit Ingredient") {
                            TextField("Name", text: $editName)
                            TextField("Brand (optional)", text: $editBrand)
                            TextField("Density g/ml (optional)", text: $editDensity)
                                .keyboardType(.decimalPad)
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
            .sheet(item: $editingMealLog) { mealLog in
                NavigationStack {
                    Form {
                        Section("Edit Meal Log") {
                            Picker("Meal Type", selection: $editMealType) {
                                ForEach(MealType.allCases) { mealType in
                                    Text(mealType.label).tag(mealType)
                                }
                            }

                            TextField("Notes (optional)", text: $editMealNotes)
                        }
                    }
                    .navigationTitle(mealLog.mealType.label)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                editingMealLog = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task {
                                    await saveEditedMealLog(mealLog)
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
        if let density = ingredient.densityGPerMl {
            editDensity = String(density)
        } else {
            editDensity = ""
        }
        editCalories = String(ingredient.caloriesPer100g)
        editCarbs = String(ingredient.carbsPer100g)
        editProtein = String(ingredient.proteinPer100g)
        editFat = String(ingredient.fatPer100g)
        editingIngredient = ingredient
    }

    private func saveEditedIngredient(_ ingredient: Ingredient) async {
        let density = editDensity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : Double(editDensity)

        guard
            let calories = Double(editCalories),
            let carbs = Double(editCarbs),
            let protein = Double(editProtein),
            let fat = Double(editFat),
            calories >= 0,
            carbs >= 0,
            protein >= 0,
            fat >= 0,
            density == nil || density! > 0,
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
            densityGPerMl: density,
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

    private func beginMealLogEdit(_ mealLog: MealLog) {
        editMealType = mealLog.mealType
        editMealNotes = mealLog.notes ?? ""
        editingMealLog = mealLog
    }

    private func saveEditedMealLog(_ mealLog: MealLog) async {
        let normalizedNotes = editMealNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        await viewModel.updateMealLog(
            mealLogId: mealLog.id,
            mealType: editMealType,
            notes: normalizedNotes.isEmpty ? nil : normalizedNotes
        )

        editingMealLog = nil
    }
}

#Preview {
    ContentView(viewModel: AuthViewModel())
}
