//
//  ContentView.swift
//  macrolicious
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import SwiftUI
import UIKit

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
                .scrollDismissesKeyboard(.interactively)
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
                Section("Diary") {
                    DiaryComposerView(
                        viewModel: viewModel,
                        mealLogEntryModeBinding: mealLogEntryModeBinding,
                        hasMealLogDraftInput: hasMealLogDraftInput
                    )

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

                statusSection
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardDismissOnTapInstaller())
            .navigationTitle("Meals")
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
                ingredientsSection
                statusSection
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardDismissOnTapInstaller())
            .navigationTitle("Ingredients")
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
    private var ingredientsSection: some View {
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
            Label("Add Meal Log Entry", systemImage: "plus.circle.fill")
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
                    Text("Computed Nutrition")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(
                        "\(preview.consumedGrams, specifier: "%.1f")g • kcal \(Int(preview.nutrition.calories)) • C \(Int(preview.nutrition.carbs)) • P \(Int(preview.nutrition.protein)) • F \(Int(preview.nutrition.fat))"
                    )
                    .font(.footnote)
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

private struct DailyTotalsView: View {
    let totals: MealLogNutrition

    var body: some View {
        Text(
            "Totals: kcal \(Int(totals.calories)) • C \(Int(totals.carbs)) • P \(Int(totals.protein)) • F \(Int(totals.fat))"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

private struct MacroTargetProgressView: View {
    let totals: MealLogNutrition
    let targets: MacroTargets

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Target Progress")
                .font(.caption)
                .foregroundStyle(.secondary)

            MacroProgressRow(label: "Calories", consumed: totals.calories, target: targets.calories, tint: .orange)
            MacroProgressRow(label: "Carbs", consumed: totals.carbs, target: targets.carbs, tint: .blue)
            MacroProgressRow(label: "Protein", consumed: totals.protein, target: targets.protein, tint: .green)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("macro-target-progress-section")
    }
}

private struct MacroProgressRow: View {
    let label: String
    let consumed: Double
    let target: Double
    let tint: Color

    private var ratio: Double {
        guard target > 0 else {
            return 0
        }

        return consumed / target
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.footnote)
                Spacer()
                Text("\(Int(consumed)) / \(Int(target))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(ratio, 1.0))
                .tint(tint)

            if ratio > 1 {
                Text("Over by \(Int(consumed - target))")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityIdentifier("macro-progress-\(label.lowercased())")
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
                        onEdit(mealLog)
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        onDelete(mealLog)
                    }
                }
                .padding(.vertical, 4)
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
