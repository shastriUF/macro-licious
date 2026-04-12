//
//  ContentView.swift
//  macrolicious
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import SwiftUI
import UIKit

// MARK: - Editable meal log item for the edit sheet

struct EditableMealLogItem: Identifiable {
    let id: String
    let ingredientId: String?
    let ingredientName: String
    var quantityValueInput: String
    var quantityUnit: QuantityUnit
    let originalQuantityValue: Double
    let originalConsumedGrams: Double
    let originalNutrition: MealLogNutrition

    init(from item: MealLogItem) {
        self.id = item.id
        self.ingredientId = item.ingredientId
        self.ingredientName = item.ingredientName
        self.quantityValueInput = item.quantityValue.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", item.quantityValue)
            : String(item.quantityValue)
        self.quantityUnit = item.quantityUnit
        self.originalQuantityValue = item.quantityValue
        self.originalConsumedGrams = item.consumedGrams
        self.originalNutrition = item.nutrition
    }

    /// Recompute nutrition using the ingredient's per-100g values.
    /// Returns nil if the ingredient can't be found or conversion fails.
    func nutritionPreview(ingredients: [Ingredient]) -> NutritionPreview? {
        guard let qty = Double(quantityValueInput), qty > 0,
              let ingredient = ingredients.first(where: { $0.id == ingredientId }) else {
            return nil
        }

        let per100g = UnitConversion.NutritionValues(
            calories: ingredient.caloriesPer100g,
            carbs: ingredient.carbsPer100g,
            protein: ingredient.proteinPer100g,
            fat: ingredient.fatPer100g
        )
        guard let result = UnitConversion.computeNutrition(
            quantity: qty,
            unit: quantityUnit,
            per100g: per100g,
            densityGPerMl: ingredient.densityGPerMl,
            servingSizeGrams: ingredient.servingSizeGrams
        ), let grams = UnitConversion.toCanonicalGrams(
            qty,
            unit: quantityUnit,
            densityGPerMl: ingredient.densityGPerMl,
            servingSizeGrams: ingredient.servingSizeGrams
        ) else { return nil }

        return NutritionPreview(
            consumedGrams: grams,
            calories: result.calories,
            carbs: result.carbs,
            protein: result.protein,
            fat: result.fat
        )
    }
}

struct NutritionPreview {
    let consumedGrams: Double
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
}

@MainActor
struct ContentView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var editingIngredient: Ingredient?
    @State private var archiveCandidate: Ingredient?
    @State private var editingMealLog: MealLog?
    @State private var deleteMealLogCandidate: MealLog?
    @State private var showingCreateIngredient = false
    @State private var editName = ""
    @State private var editBrand = ""
    @State private var editDensity = ""
    @State private var editServingSize = ""
    @State private var editDefaultUnit: QuantityUnit? = nil
    @State private var editCalories = ""
    @State private var editCarbs = ""
    @State private var editProtein = ""
    @State private var editFat = ""
    @FocusState private var isSignInEmailFocused: Bool

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        TabView {
            signInTab
                .tabItem {
                    Label("Sign In", systemImage: "person.crop.circle")
                }

            mealsTab
                .tabItem {
                    Label("Meals", systemImage: "fork.knife.circle")
                }

            ingredientsTab
                .tabItem {
                    Label("Ingredients", systemImage: "list.bullet.rectangle.portrait")
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
                        TextField("Serving size grams (optional)", text: $editServingSize)
                            .keyboardType(.decimalPad)
                        Picker("Default unit", selection: $editDefaultUnit) {
                            Text("None").tag(QuantityUnit?.none)
                            ForEach(QuantityUnit.allCases, id: \.rawValue) { unit in
                                Text(unit.label).tag(QuantityUnit?.some(unit))
                            }
                        }
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
                .scrollDismissesKeyboard(.interactively)
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
            MealLogEditSheet(
                mealLog: mealLog,
                ingredients: viewModel.ingredients,
                onSave: { mealType, notes, items in
                    await viewModel.updateMealLog(
                        mealLogId: mealLog.id,
                        mealType: mealType,
                        notes: notes,
                        items: items
                    )
                    editingMealLog = nil
                },
                onCancel: {
                    editingMealLog = nil
                }
            )
        }
    }

    private var signInTab: some View {
        NavigationStack {
            Form {
                backendSection
                signInSection
                profileSection
                statusSection
            }
            .accessibilityIdentifier("sign-in-form")
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardDismissOnTapInstaller())
            .navigationTitle("Sign In")
        }
    }

    private var mealsTab: some View {
        NavigationStack {
            Form {
                Section("New Entry") {
                    DiaryComposerView(
                        viewModel: viewModel,
                        mealLogEntryModeBinding: mealLogEntryModeBinding,
                        hasMealLogDraftInput: hasMealLogDraftInput
                    )
                }

                Section("Today's Summary") {
                    DailyTotalsView(totals: viewModel.dailyTotals)

                    if let user = viewModel.currentUser {
                        MacroTargetProgressView(
                            totals: viewModel.dailyTotals,
                            targets: user.macroTargets
                        )
                    } else {
                        Text("Sign in to view macro target progress.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Meal Log") {
                    MealLogListView(
                        mealLogs: viewModel.mealLogs,
                        onEdit: { mealLog in
                            beginMealLogEdit(mealLog)
                        },
                        onDelete: { mealLog in
                            deleteMealLogCandidate = mealLog
                        }
                    )
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardDismissOnTapInstaller())
            .navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .status) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .onChange(of: viewModel.diaryDate) { _, _ in
                guard viewModel.currentUser != nil else {
                    return
                }

                Task {
                    await viewModel.refreshMealLogs()
                }
            }
        }
    }

    private var ingredientsTab: some View {
        NavigationStack {
            Form {
                ingredientListSection
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardDismissOnTapInstaller())
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem(placement: .status) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateIngredient = true
                    } label: {
                        Label("Add Ingredient", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateIngredient) {
                IngredientCreateSheet(
                    viewModel: viewModel,
                    onDismiss: { showingCreateIngredient = false }
                )
            }
        }
    }

    @ViewBuilder
    private var backendSection: some View {
        Section("Backend") {
            TextField("Base URL", text: $viewModel.baseURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            Button("Save Backend URL") {
                viewModel.saveBaseURL()
            }
        }
    }

    @ViewBuilder
    private var signInSection: some View {
        Section("Sign In") {
            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .accessibilityIdentifier("sign-in-email-field")
                .focused($isSignInEmailFocused)

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

            if isUITestMode {
                Text(isSignInEmailFocused ? "focused" : "unfocused")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("sign-in-email-focus-state")
            }
        }
    }

    @ViewBuilder
    private var profileSection: some View {
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
    }

    @ViewBuilder
    private var ingredientListSection: some View {
        Section("Ingredients") {
            Button("Refresh Ingredients") {
                Task {
                    await viewModel.refreshIngredients()
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

                        NutritionPillsView(
                            calories: ingredient.caloriesPer100g,
                            carbs: ingredient.carbsPer100g,
                            protein: ingredient.proteinPer100g,
                            fat: ingredient.fatPer100g
                        )

                        if let density = ingredient.densityGPerMl {
                            Text("Density: \(density, specifier: "%.2f") g/ml")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let serving = ingredient.servingSizeGrams {
                            Text("Serving: \(serving, specifier: "%.0f")g")
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
    }

    @ViewBuilder
    private var statusSection: some View {
        Section("Status") {
            if viewModel.isLoading {
                ProgressView()
            }

            Text(viewModel.statusMessage.isEmpty ? "Ready" : viewModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("status-message-label")
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
        if let serving = ingredient.servingSizeGrams {
            editServingSize = String(serving)
        } else {
            editServingSize = ""
        }
        editDefaultUnit = ingredient.defaultQuantityUnit
        editCalories = String(ingredient.caloriesPer100g)
        editCarbs = String(ingredient.carbsPer100g)
        editProtein = String(ingredient.proteinPer100g)
        editFat = String(ingredient.fatPer100g)
        editingIngredient = ingredient
    }

    private func saveEditedIngredient(_ ingredient: Ingredient) async {
        let density = editDensity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : Double(editDensity)
        let serving = editServingSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : Double(editServingSize)

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
            serving == nil || serving! > 0,
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
            servingSizeGrams: serving,
            defaultQuantityUnit: editDefaultUnit,
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
        editingMealLog = mealLog
    }

    private var mealLogEntryModeBinding: Binding<MealLogEntryMode> {
        Binding(
            get: {
                viewModel.useIngredientForMealLog ? .ingredientLibrary : .manualSnapshot
            },
            set: { newMode in
                viewModel.useIngredientForMealLog = newMode == .ingredientLibrary
            }
        )
    }

    private var hasMealLogDraftInput: Bool {
        let quantityText = viewModel.mealQuantityValueInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !quantityText.isEmpty {
            return true
        }

        if !viewModel.mealNotesInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        if viewModel.useIngredientForMealLog {
            return viewModel.selectedMealIngredient != nil
        }

        return !viewModel.mealIngredientNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isUITestMode: Bool {
        let launchArguments = ProcessInfo.processInfo.arguments
        let launchEnvironment = ProcessInfo.processInfo.environment

        return launchArguments.contains("-ui-testing")
            || launchArguments.contains("-ui-testing-signed-in")
            || launchEnvironment["UI_TEST_MODE"] == "1"
            || launchEnvironment["UI_TEST_SIGNED_IN"] == "1"
    }
}

private enum MealLogEntryMode: String, CaseIterable, Identifiable {
    case ingredientLibrary
    case manualSnapshot

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ingredientLibrary:
            return "Library"
        case .manualSnapshot:
            return "Manual"
        }
    }
}

private struct DiaryComposerView: View {
    @ObservedObject var viewModel: AuthViewModel
    let mealLogEntryModeBinding: Binding<MealLogEntryMode>
    let hasMealLogDraftInput: Bool

    var body: some View {
        DatePicker("Date", selection: $viewModel.diaryDate, displayedComponents: .date)

        Button("Refresh Diary") {
            Task {
                await viewModel.refreshMealLogs()
            }
        }
        .disabled(viewModel.currentUser == nil || viewModel.isLoading)

        if !viewModel.mealQuickPresets.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Add")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.mealQuickPresets) { preset in
                            Button {
                                viewModel.applyMealQuickPreset(preset)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.mealType.label)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(preset.displayName)
                                        .font(.footnote)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }

        Picker("Meal Type", selection: $viewModel.selectedMealType) {
            ForEach(MealType.allCases) { mealType in
                Text(mealType.label).tag(mealType)
            }
        }
        .pickerStyle(.segmented)

        Picker("Entry Mode", selection: mealLogEntryModeBinding) {
            ForEach(MealLogEntryMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        TextField("Notes (optional)", text: $viewModel.mealNotesInput)

        if viewModel.useIngredientForMealLog {
            ingredientEntryView
        } else {
            manualEntryView
        }

        if hasMealLogDraftInput, let validationMessage = viewModel.mealLogValidationMessage {
            Text(validationMessage)
                .font(.footnote)
                .foregroundStyle(.orange)
        }

        Button {
            Task {
                await viewModel.createMealLog()
            }
        } label: {
            Label("Add Meal Log Entry", systemImage: "plus")
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isLoading || !viewModel.canCreateMealLog)
    }

    @ViewBuilder
    private var ingredientEntryView: some View {
        if viewModel.ingredients.isEmpty {
            Text("No ingredients yet. Create one in Ingredients or switch to Manual Snapshot.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Switch to Manual Snapshot") {
                viewModel.useIngredientForMealLog = false
            }
        } else {
            Picker("Ingredient", selection: $viewModel.selectedMealIngredientId) {
                ForEach(viewModel.ingredients) { ingredient in
                    Text(ingredient.name).tag(ingredient.id)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.selectedMealIngredientId) { _, newId in
                if let ingredient = viewModel.ingredients.first(where: { $0.id == newId }) {
                    viewModel.applyDefaultUnit(for: ingredient)
                }
            }

            if let ingredient = viewModel.selectedMealIngredient {
                NutritionPillsView(
                    calories: ingredient.caloriesPer100g,
                    carbs: ingredient.carbsPer100g,
                    protein: ingredient.proteinPer100g,
                    fat: ingredient.fatPer100g,
                    prefix: "Per 100g"
                )

                if let density = ingredient.densityGPerMl {
                    Text("Density: \(density, specifier: "%.2f") g/ml")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let serving = ingredient.servingSizeGrams {
                    Text("Serving: \(serving, specifier: "%.0f")g per count")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
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

            if let preview = viewModel.mealLogPreview {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(preview.consumedGrams, specifier: "%.1f")g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    NutritionPillsView(
                        calories: preview.nutrition.calories,
                        carbs: preview.nutrition.carbs,
                        protein: preview.nutrition.protein,
                        fat: preview.nutrition.fat
                    )
                }
            } else if !viewModel.mealQuantityValueInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Unable to compute nutrition. Use a mass unit or ensure the ingredient has density for volume units.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var manualEntryView: some View {
        TextField("Ingredient name", text: $viewModel.mealIngredientNameInput)

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
}

// MARK: - Nutrition Pills

private struct NutritionPillsView: View {
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    var prefix: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let prefix {
                Text(prefix)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            pill("\(Int(calories)) kcal", color: .orange)
            pill("C \(Int(carbs))g", color: .blue)
            pill("P \(Int(protein))g", color: .green)
            pill("F \(Int(fat))g", color: .yellow)
        }
    }

    private func pill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

private struct DailyTotalsView: View {
    let totals: MealLogNutrition

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Daily Totals")
                .font(.caption)
                .foregroundStyle(.secondary)
            NutritionPillsView(
                calories: totals.calories,
                carbs: totals.carbs,
                protein: totals.protein,
                fat: totals.fat
            )
        }
    }
}

private struct MacroTargetProgressView: View {
    let totals: MealLogNutrition
    let targets: MacroTargets

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Progress")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                MacroGaugeView(label: "kcal", consumed: totals.calories, target: targets.calories, tint: .orange)
                MacroGaugeView(label: "Carbs", consumed: totals.carbs, target: targets.carbs, tint: .blue, unit: "g")
                MacroGaugeView(label: "Protein", consumed: totals.protein, target: targets.protein, tint: .green, unit: "g")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("macro-target-progress-section")
    }
}

private struct MacroGaugeView: View {
    let label: String
    let consumed: Double
    let target: Double
    let tint: Color
    var unit: String = ""

    private var ratio: Double {
        guard target > 0 else { return 0 }
        return consumed / target
    }

    private var remaining: Double {
        max(target - consumed, 0)
    }

    var body: some View {
        VStack(spacing: 4) {
            Gauge(value: min(ratio, 1.0)) {
                EmptyView()
            } currentValueLabel: {
                Text("\(Int(consumed))")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(ratio > 1 ? .red : tint)
            .scaleEffect(1.2)

            Text(label)
                .font(.caption2)
                .fontWeight(.medium)

            if ratio > 1 {
                Text("+\(Int(consumed - target))\(unit)")
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else if target > 0 {
                Text("\(Int(remaining))\(unit) left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("macro-progress-\(label.lowercased())")
    }
}

// MARK: - Meal Log Edit Sheet

/// Self-contained edit sheet that initialises its own @State from the presented MealLog,
/// avoiding timing issues with external state set before sheet presentation.
private struct MealLogEditSheet: View {
    let mealLog: MealLog
    let ingredients: [Ingredient]
    let onSave: (MealType, String?, [CreateMealLogItemRequest]?) async -> Void
    let onCancel: () -> Void

    @State private var mealType: MealType
    @State private var notes: String
    @State private var items: [EditableMealLogItem]

    init(
        mealLog: MealLog,
        ingredients: [Ingredient],
        onSave: @escaping (MealType, String?, [CreateMealLogItemRequest]?) async -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mealLog = mealLog
        self.ingredients = ingredients
        self.onSave = onSave
        self.onCancel = onCancel
        _mealType = State(initialValue: mealLog.mealType)
        _notes = State(initialValue: mealLog.notes ?? "")
        _items = State(initialValue: mealLog.items.map { EditableMealLogItem(from: $0) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Edit Meal Log") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases) { mealType in
                            Text(mealType.label).tag(mealType)
                        }
                    }

                    TextField("Notes (optional)", text: $notes)
                }

                Section("Items") {
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.ingredientName)
                                .font(.headline)

                            HStack {
                                TextField("Qty", text: $item.quantityValueInput)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                                Picker("Unit", selection: $item.quantityUnit) {
                                    ForEach(QuantityUnit.allCases, id: \.rawValue) { unit in
                                        Text(unit.label).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            if let preview = item.nutritionPreview(ingredients: ingredients) {
                                NutritionPillsView(
                                    calories: preview.calories,
                                    carbs: preview.carbs,
                                    protein: preview.protein,
                                    fat: preview.fat,
                                    prefix: String(format: "%.1fg", preview.consumedGrams)
                                )
                            } else {
                                NutritionPillsView(
                                    calories: item.originalNutrition.calories,
                                    carbs: item.originalNutrition.carbs,
                                    protein: item.originalNutrition.protein,
                                    fat: item.originalNutrition.fat
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(mealLog.mealType.label)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await save()
                        }
                    }
                }
            }
        }
    }

    private func save() async {
        let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let updatedItems: [CreateMealLogItemRequest] = items.map { item in
            if let preview = item.nutritionPreview(ingredients: ingredients) {
                return CreateMealLogItemRequest(
                    ingredientId: item.ingredientId,
                    ingredientName: item.ingredientName,
                    quantityValue: Double(item.quantityValueInput) ?? item.originalQuantityValue,
                    quantityUnit: item.quantityUnit,
                    consumedGrams: preview.consumedGrams,
                    nutrition: MealLogNutrition(
                        calories: preview.calories,
                        carbs: preview.carbs,
                        protein: preview.protein,
                        fat: preview.fat
                    )
                )
            } else {
                return CreateMealLogItemRequest(
                    ingredientId: item.ingredientId,
                    ingredientName: item.ingredientName,
                    quantityValue: Double(item.quantityValueInput) ?? item.originalQuantityValue,
                    quantityUnit: item.quantityUnit,
                    consumedGrams: item.originalConsumedGrams,
                    nutrition: item.originalNutrition
                )
            }
        }

        await onSave(
            mealType,
            normalizedNotes.isEmpty ? nil : normalizedNotes,
            updatedItems
        )
    }
}

// MARK: - Ingredient Create Sheet

private struct IngredientCreateSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Produce Quick Add", isOn: $viewModel.isProduceModeEnabled)

                    if viewModel.isProduceModeEnabled {
                        Text("Produce mode is weight-first: name + macros per 100g, brand optional.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Details") {
                    TextField("Name", text: $viewModel.ingredientNameInput)
                    if !viewModel.isProduceModeEnabled {
                        TextField("Brand (optional)", text: $viewModel.ingredientBrandInput)
                    }
                    TextField("Density g/ml (optional)", text: $viewModel.ingredientDensityInput)
                        .keyboardType(.decimalPad)
                    TextField("Serving size grams (optional)", text: $viewModel.ingredientServingSizeInput)
                        .keyboardType(.decimalPad)
                    Picker("Default unit", selection: $viewModel.ingredientDefaultUnitInput) {
                        Text("None").tag(QuantityUnit?.none)
                        ForEach(QuantityUnit.allCases, id: \.rawValue) { unit in
                            Text(unit.label).tag(QuantityUnit?.some(unit))
                        }
                    }
                }

                Section("Nutrition per 100g") {
                    TextField("Calories", text: $viewModel.ingredientCaloriesInput)
                        .keyboardType(.decimalPad)
                    TextField("Carbs", text: $viewModel.ingredientCarbsInput)
                        .keyboardType(.decimalPad)
                    TextField("Protein", text: $viewModel.ingredientProteinInput)
                        .keyboardType(.decimalPad)
                    TextField("Fat", text: $viewModel.ingredientFatInput)
                        .keyboardType(.decimalPad)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createIngredient()
                            onDismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct MealLogListView: View {
    let mealLogs: [MealLog]
    let onEdit: (MealLog) -> Void
    let onDelete: (MealLog) -> Void

    var body: some View {
        if mealLogs.isEmpty {
            Text("No meal logs for selected date")
                .foregroundStyle(.secondary)
        } else {
            ForEach(mealLogs) { mealLog in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(mealLog.mealType.label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(mealLog.mealType.color, in: Capsule())

                        Spacer()

                        Text(mealLog.date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let notes = mealLog.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(mealLog.items) { item in
                        HStack(alignment: .top) {
                            Rectangle()
                                .fill(mealLog.mealType.color.opacity(0.4))
                                .frame(width: 3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.ingredientName)
                                    .font(.subheadline)
                                Text(
                                    "\(item.quantityValue, specifier: "%.1f") \(item.quantityUnit.label) · \(Int(item.nutrition.calories)) kcal"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button("Edit") {
                        onEdit(mealLog)
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        onDelete(mealLog)
                    }
                }
            }
        }
    }
}

private struct KeyboardDismissOnTapInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> KeyboardDismissInstallerView {
        KeyboardDismissInstallerView()
    }

    func updateUIView(_ uiView: KeyboardDismissInstallerView, context: Context) {}
}

private final class KeyboardDismissInstallerView: UIView {
    private static let recognizerName = "macrolicious.keyboardDismissTap"

    override func didMoveToWindow() {
        super.didMoveToWindow()
        installRecognizerIfNeeded()
    }

    private func installRecognizerIfNeeded() {
        guard let window else {
            return
        }

        if window.gestureRecognizers?.contains(where: { $0.name == Self.recognizerName }) == true {
            return
        }

        let recognizer = KeyboardDismissTapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.name = Self.recognizerName
        window.addGestureRecognizer(recognizer)
    }

    @objc private func handleTap() {
        window?.endEditing(true)
    }
}

private final class KeyboardDismissTapGestureRecognizer: UITapGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var currentView = touch.view
        while let view = currentView {
            if view is UITextField || view is UITextView {
                return false
            }

            currentView = view.superview
        }

        return true
    }
}

#Preview {
    ContentView(viewModel: AuthViewModel())
}
