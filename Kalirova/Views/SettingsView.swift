import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage(PersistenceService.iCloudBackupEnabledKey) private var storedICloudBackupEnabled = false
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var persistenceService: PersistenceService

    @Query private var profiles: [UserProfile]
    @Query private var meals: [MealEntry]
    @Query private var workouts: [WorkoutEntry]
    @Query private var metrics: [HealthMetricEntry]
    @Query private var goals: [Goal]
    @Query private var aiSummaries: [AISummary]
    @Query private var settings: [AppSettings]

    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var iCloudBackupService = ICloudBackupService()
    @State private var aiFeaturesEnabled = false
    @State private var healthKitSyncEnabled = false
    @State private var showDeviceCalories = true
    @State private var showAppEstimatedCalories = true
    @State private var openAIModel = "gpt-5.5"
    @State private var unitSystem: UnitSystem = .metric
    @State private var iCloudBackupEnabled = false
    @State private var apiKey = ""
    @State private var maskedAPIKey: String?
    @State private var isTestingConnection = false
    @State private var statusMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var showingICloudEnableWarning = false
    @State private var requestedICloudBackupState = false
    @State private var showingUsernameEditor = false
    @State private var usernameDraft = ""
    @State private var usernameValidationMessage: String?
    @FocusState private var focusedSettingsField: SettingsFocusField?

    private let openAIService = OpenAIService()

    private var exportText: String {
        LocalDataExporter.export(
            profiles: profiles,
            meals: meals,
            workouts: workouts,
            metrics: metrics,
            goals: goals,
            aiSummaries: aiSummaries
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(KalirovaTheme.Colors.accentPrimary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileDisplayName)
                                .font(.kalirovaSectionTitle)
                                .foregroundStyle(KalirovaTheme.Colors.textPrimary)
                            Text(profileSummary)
                                .font(.subheadline)
                                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Personal") {
                    if let profile = profiles.first {
                        LabeledContent("Username", value: profile.displayUsername)
                        Button {
                            beginUsernameEdit(profile)
                        } label: {
                            Label("Edit Username", systemImage: "pencil")
                        }
                        .accessibilityLabel("Edit profile username")
                        LabeledContent("Goal", value: profile.goalSummary)
                        LabeledContent("Age", value: "\(profile.ageYears)")
                        LabeledContent("Activity", value: profile.activityLevel.rawValue.displayName)
                    } else {
                        ContentUnavailableView("No profile", systemImage: "person.crop.circle", description: Text("Complete onboarding to create your profile."))
                    }
                }

                Section("General") {
                    Toggle("Device Reported Calories", isOn: $showDeviceCalories)
                    Toggle("App Estimated Calories", isOn: $showAppEstimatedCalories)
                }

                Section("Units") {
                    Picker("Unit Preference", selection: $unitSystem) {
                        ForEach(UnitSystem.allCases) { unitSystem in
                            Text(unitSystem.displayName).tag(unitSystem)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Notifications") {
                    Label("Notification preferences are not enabled yet.", systemImage: "bell")
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }

                Section("HealthKit") {
                    Toggle("HealthKit Sync", isOn: $healthKitSyncEnabled)
                    Button {
                        Task { await requestHealthAccess() }
                    } label: {
                        Label("Request Health Access", systemImage: "heart.text.square")
                    }
                    Text(healthKitService.authorizationStatusText)
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }

                Section("AI") {
                    Toggle("AI Features", isOn: $aiFeaturesEnabled)
                    TextField("Model", text: $openAIModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedSettingsField, equals: .openAIModel)
                        .submitLabel(.done)
                        .onSubmit(dismissKeyboard)
                    SecureField("OpenAI API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .privacySensitive()
                        .focused($focusedSettingsField, equals: .apiKey)
                        .submitLabel(.done)
                        .onSubmit(dismissKeyboard)
                    if let maskedAPIKey {
                        Label("Saved key: \(maskedAPIKey)", systemImage: "checkmark.seal")
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                            .accessibilityLabel("OpenAI API key is saved")
                    }
                    VStack(spacing: 10) {
                        Button {
                            saveAPIKey()
                        } label: {
                            Label("Save Key", systemImage: "key.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryKalirovaButton())

                        Button {
                            Task { await testOpenAIConnection() }
                        } label: {
                            Label(isTestingConnection ? "Testing" : "Test Connection", systemImage: "network")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTestingConnection || (apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && maskedAPIKey == nil))

                        Button(role: .destructive) {
                            deleteAPIKey()
                        } label: {
                            Label("Delete/Clear Key", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section("Privacy") {
                    Label(privacyStorageText, systemImage: "lock.shield")
                    Label("No third-party analytics", systemImage: "chart.bar.xaxis")
                    Label("API keys stay in Keychain", systemImage: "key")
                    Text(SummaryService.wellnessDisclaimer)
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }

                Section("iCloud") {
                    Toggle("Enable iCloud Backup", isOn: Binding(
                        get: { iCloudBackupEnabled },
                        set: { updateICloudBackupPreference($0) }
                    ))
                    .disabled(!PersistenceService.isICloudBackupCapabilityEnabled)
                    Text(iCloudBackupDescription)
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    Label(iCloudBackupService.availabilityText, systemImage: iCloudBackupService.isAvailable ? "icloud" : "icloud.slash")
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    Label("Last backup: \(iCloudBackupService.formattedLastBackup())", systemImage: "clock")
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    Button {
                        backUpNow()
                    } label: {
                        Label("Back Up Now", systemImage: "icloud.and.arrow.up")
                    }
                    .disabled(!PersistenceService.isICloudBackupCapabilityEnabled || !iCloudBackupEnabled || !iCloudBackupService.isAvailable)
                    Text("OpenAI API keys, logs, caches, debug data, and OpenAI request data are not included in iCloud backup.")
                        .font(.caption)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }

                Section("Appearance") {
                    Label("Uses system appearance, Dynamic Type, and high-contrast settings.", systemImage: "paintbrush")
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }

                Section("Developer") {
                    ShareLink(item: exportText) {
                        Label("Export Local Data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete All Local Data", systemImage: "trash")
                    }
                }

                if let statusMessage {
                    Section("Status") {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnOutsideTap(dismissKeyboard)
            .navigationTitle("Profile")
            .onAppear(perform: loadSettings)
            .onChange(of: aiFeaturesEnabled) { _, _ in saveSettings() }
            .onChange(of: healthKitSyncEnabled) { _, _ in saveSettings() }
            .onChange(of: showDeviceCalories) { _, _ in saveSettings() }
            .onChange(of: showAppEstimatedCalories) { _, _ in saveSettings() }
            .onChange(of: openAIModel) { _, _ in saveSettings() }
            .onChange(of: unitSystem) { _, _ in saveSettings() }
            .alert("Enable iCloud Backup?", isPresented: $showingICloudEnableWarning) {
                Button("Enable", action: enableICloudBackupAfterWarning)
                Button("Cancel", role: .cancel) {
                    requestedICloudBackupState = false
                }
            } message: {
                Text("Your Kalirova app data may be stored in your private iCloud account. Do not enable this on shared Apple IDs.")
            }
            .alert("Delete all local data?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive, action: deleteAllLocalData)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Meals, workouts, metrics, goals, summaries, settings, and the Keychain API key will be removed from this device.")
            }
            .sheet(isPresented: $showingUsernameEditor) {
                UsernameEditorView(
                    username: $usernameDraft,
                    validationMessage: usernameValidationMessage,
                    onCancel: {
                        usernameValidationMessage = nil
                        showingUsernameEditor = false
                    },
                    onSave: saveUsername
                )
                .presentationDetents([.medium])
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done", action: dismissKeyboard)
                }
            }
        }
    }

    private var profileDisplayName: String {
        profiles.first?.displayUsername ?? "Kalirova Profile"
    }

    private var profileSummary: String {
        guard let profile = profiles.first else {
            return "Local-first health settings"
        }

        return "\(profile.goalSummary) • \(unitSystem.displayName)"
    }

    private func beginUsernameEdit(_ profile: UserProfile) {
        usernameDraft = profile.displayUsername
        usernameValidationMessage = nil
        showingUsernameEditor = true
    }

    private func saveUsername() {
        guard let profile = profiles.first else {
            usernameValidationMessage = "Complete onboarding before editing your username."
            return
        }

        let trimmedUsername = usernameDraft.trimmedUsername
        guard !trimmedUsername.isEmpty else {
            usernameValidationMessage = "Username cannot be empty."
            return
        }

        let invalidCharacters = CharacterSet.newlines.union(.controlCharacters)
        guard trimmedUsername.rangeOfCharacter(from: invalidCharacters) == nil else {
            usernameValidationMessage = "Username cannot contain line breaks or control characters."
            return
        }

        profile.username = trimmedUsername
        profile.updatedAt = .now
        do {
            try modelContext.save()
            usernameDraft = trimmedUsername
            usernameValidationMessage = nil
            showingUsernameEditor = false
            statusMessage = "Username updated."
        } catch {
            usernameValidationMessage = error.localizedDescription
        }
    }

    private func dismissKeyboard() {
        focusedSettingsField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var privacyStorageText: String {
        PersistenceService.isICloudBackupCapabilityEnabled
            ? "Health data stays on this device unless iCloud Backup is enabled."
            : "Health data stays on this device in local development builds."
    }

    private var iCloudBackupDescription: String {
        PersistenceService.isICloudBackupCapabilityEnabled
            ? "Health data is stored on this device unless iCloud Backup is enabled. When enabled, supported Kalirova app data may sync through your private iCloud account."
            : "iCloud Backup requires a paid Apple Developer account, the iCloud capability, and the ENABLE_ICLOUD_BACKUP build flag. This local build uses local-only storage."
    }

    private func loadSettings() {
        let current = settings.first
        aiFeaturesEnabled = current?.aiFeaturesEnabled ?? false
        healthKitSyncEnabled = current?.healthKitSyncEnabled ?? false
        showDeviceCalories = current?.showDeviceCalories ?? true
        showAppEstimatedCalories = current?.showAppEstimatedCalories ?? true
        openAIModel = current?.openAIModel ?? "gpt-5.5"
        unitSystem = current?.unitSystem ?? profiles.first?.preferredUnitSystem ?? .metric
        if PersistenceService.isICloudBackupCapabilityEnabled {
            iCloudBackupEnabled = storedICloudBackupEnabled || (current?.iCloudBackupEnabled ?? false)
        } else {
            if storedICloudBackupEnabled || (current?.iCloudBackupEnabled ?? false) {
                statusMessage = "iCloud Backup was disabled for this local development build. Kalirova is using local-only storage."
            }
            storedICloudBackupEnabled = false
            iCloudBackupEnabled = false
        }
        iCloudBackupService.refreshAvailability()

        do {
            if let storedAPIKey = try KeychainService.shared.loadOpenAIAPIKey() {
                maskedAPIKey = KeychainService.maskedAPIKey(storedAPIKey)
                statusMessage = "OpenAI API key is stored in Keychain."
            } else {
                maskedAPIKey = nil
            }
        } catch {
            maskedAPIKey = nil
            statusMessage = error.localizedDescription
        }
    }

    private func saveSettings() {
        let current = settings.first ?? AppSettings()
        if settings.first == nil {
            modelContext.insert(current)
        }

        current.aiFeaturesEnabled = aiFeaturesEnabled
        current.healthKitSyncEnabled = healthKitSyncEnabled
        current.showDeviceCalories = showDeviceCalories
        current.showAppEstimatedCalories = showAppEstimatedCalories
        current.openAIModel = openAIModel
        current.unitSystemRawValue = unitSystem.rawValue
        current.iCloudBackupEnabled = PersistenceService.isICloudBackupCapabilityEnabled && iCloudBackupEnabled
        current.lastICloudBackupAt = iCloudBackupService.lastBackupAt
        current.updatedAt = .now
        try? modelContext.save()
    }

    private func updateICloudBackupPreference(_ isEnabled: Bool) {
        guard PersistenceService.isICloudBackupCapabilityEnabled else {
            storedICloudBackupEnabled = false
            iCloudBackupEnabled = false
            saveSettings()
            statusMessage = "iCloud Backup requires a paid Apple Developer account and is disabled for this local development build."
            return
        }

        if isEnabled {
            requestedICloudBackupState = true
            showingICloudEnableWarning = true
        } else {
            applyICloudBackupPreference(false)
        }
    }

    private func enableICloudBackupAfterWarning() {
        guard requestedICloudBackupState else { return }
        requestedICloudBackupState = false
        applyICloudBackupPreference(true)
    }

    private func applyICloudBackupPreference(_ isEnabled: Bool) {
        guard !isEnabled || PersistenceService.isICloudBackupCapabilityEnabled else {
            storedICloudBackupEnabled = false
            iCloudBackupEnabled = false
            saveSettings()
            statusMessage = "iCloud Backup requires a paid Apple Developer account and is disabled for this local development build."
            return
        }

        let previousState = storedICloudBackupEnabled
        do {
            iCloudBackupEnabled = isEnabled
            storedICloudBackupEnabled = isEnabled
            saveSettings()
            try modelContext.save()
            try persistenceService.setICloudBackupEnabled(isEnabled)
            if isEnabled {
                iCloudBackupService.recordSuccessfulBackup()
                statusMessage = "iCloud Backup enabled. Existing local Kalirova data is prepared for private iCloud sync."
            } else {
                statusMessage = "iCloud Backup disabled. Kalirova will continue using local-only storage on this device."
            }
        } catch {
            storedICloudBackupEnabled = previousState
            iCloudBackupEnabled = previousState
            saveSettings()
            statusMessage = error.localizedDescription
        }
    }

    private func backUpNow() {
        guard PersistenceService.isICloudBackupCapabilityEnabled else {
            statusMessage = "iCloud Backup requires a paid Apple Developer account and is disabled for this local development build."
            return
        }

        guard iCloudBackupEnabled else {
            statusMessage = "Enable iCloud Backup before backing up."
            return
        }

        guard iCloudBackupService.isAvailable else {
            statusMessage = "No iCloud account is available on this device."
            return
        }

        do {
            try modelContext.save()
            iCloudBackupService.recordSuccessfulBackup()
            saveSettings()
            statusMessage = "Kalirova data was saved locally and queued for private iCloud sync."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func saveAPIKey() {
        dismissKeyboard()
        do {
            let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedAPIKey.isEmpty else {
                statusMessage = "Enter an OpenAI API key before saving."
                return
            }

            try KeychainService.shared.saveOpenAIAPIKey(trimmedAPIKey)
            maskedAPIKey = KeychainService.maskedAPIKey(trimmedAPIKey)
            apiKey = ""
            statusMessage = "OpenAI API key saved to Keychain as \(maskedAPIKey ?? "a masked key")."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func deleteAPIKey() {
        do {
            try KeychainService.shared.deleteOpenAIAPIKey()
            apiKey = ""
            maskedAPIKey = nil
            statusMessage = "OpenAI API key deleted from Keychain."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func testOpenAIConnection() async {
        isTestingConnection = true
        defer { isTestingConnection = false }

        do {
            let pendingAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let keyToTest = pendingAPIKey.isEmpty ? try KeychainService.shared.loadOpenAIAPIKey() : pendingAPIKey
            try await openAIService.testConnection(apiKey: keyToTest)
            statusMessage = "OpenAI connection succeeded."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func requestHealthAccess() async {
        do {
            try await healthKitService.requestAuthorization()
            healthKitSyncEnabled = true
            saveSettings()
            statusMessage = "HealthKit authorization flow completed."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func deleteAllLocalData() {
        profiles.forEach(modelContext.delete)
        meals.forEach(modelContext.delete)
        workouts.forEach(modelContext.delete)
        metrics.forEach(modelContext.delete)
        goals.forEach(modelContext.delete)
        aiSummaries.forEach(modelContext.delete)
        settings.forEach(modelContext.delete)
        try? KeychainService.shared.deleteOpenAIAPIKey()
        try? modelContext.save()
        hasCompletedOnboarding = false
    }
}

private enum SettingsFocusField: Hashable {
    case openAIModel
    case apiKey
}

private struct UsernameEditorView: View {
    @Binding var username: String
    var validationMessage: String?
    var onCancel: () -> Void
    var onSave: () -> Void
    @FocusState private var isUsernameFocused: Bool

    private var trimmedUsername: String {
        username.trimmedUsername
    }

    private var canSave: Bool {
        !trimmedUsername.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .textContentType(.nickname)
                        .focused($isUsernameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if canSave {
                                isUsernameFocused = false
                                onSave()
                            }
                        }
                        .accessibilityLabel("Profile username")

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.error)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } footer: {
                    Text("This name appears on your Home and Profile screens. It does not change saved meals, metrics, workouts, settings, or API keys.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnOutsideTap {
                isUsernameFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Edit Username")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isUsernameFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isUsernameFocused = false
                        onSave()
                    }
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isUsernameFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}

private extension View {
    func dismissKeyboardOnOutsideTap(_ action: @escaping () -> Void) -> some View {
        background(KeyboardDismissTapInstaller(onTapOutsideTextInput: action))
    }
}

private struct KeyboardDismissTapInstaller: UIViewRepresentable {
    var onTapOutsideTextInput: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTapOutsideTextInput: onTapOutsideTextInput)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTapOutsideTextInput = onTapOutsideTextInput
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: uiView)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTapOutsideTextInput: () -> Void
        private weak var installedWindow: UIWindow?
        private weak var tapRecognizer: UITapGestureRecognizer?

        init(onTapOutsideTextInput: @escaping () -> Void) {
            self.onTapOutsideTextInput = onTapOutsideTextInput
        }

        func installIfNeeded(from view: UIView) {
            guard let window = view.window else { return }
            guard installedWindow !== window || tapRecognizer == nil else { return }

            uninstall()

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)
            installedWindow = window
            tapRecognizer = recognizer
        }

        func uninstall() {
            if let tapRecognizer, let installedWindow {
                installedWindow.removeGestureRecognizer(tapRecognizer)
            }
            tapRecognizer = nil
            installedWindow = nil
        }

        @objc private func handleTap() {
            onTapOutsideTextInput()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let view = touch.view else { return true }
            return !view.isTextInputOrDescendant
        }
    }
}

private extension UIView {
    var isTextInputOrDescendant: Bool {
        if self is UITextField || self is UITextView || self is UISearchTextField {
            return true
        }
        return superview?.isTextInputOrDescendant ?? false
    }
}

private enum LocalDataExporter {
    static func export(
        profiles: [UserProfile],
        meals: [MealEntry],
        workouts: [WorkoutEntry],
        metrics: [HealthMetricEntry],
        goals: [Goal],
        aiSummaries: [AISummary]
    ) -> String {
        let export = LocalExport(
            exportedAt: .now,
            disclaimer: SummaryService.wellnessDisclaimer,
            profiles: profiles.map {
                ExportProfile(username: $0.displayUsername, ageYears: $0.ageYears, sex: $0.sexRawValue, dateOfBirth: $0.dateOfBirth, heightCentimeters: $0.heightCentimeters, bodyMassKg: $0.bodyMassKg, goalBodyMassKg: $0.goalBodyMassKg, activityLevel: $0.activityLevelRawValue, unitSystem: $0.preferredUnitSystemRawValue, goalSummary: $0.goalSummary)
            },
            meals: meals.map {
                ExportMeal(title: $0.displayTitle, mealType: $0.mealTypeRawValue, customMealTypeName: $0.customMealTypeName, loggedAt: $0.loggedAt, calories: $0.totalCalories, proteinGrams: $0.totalProtein, source: $0.sourceRawValue)
            },
            workouts: workouts.map {
                ExportWorkout(title: $0.title, startedAt: $0.startedAt, durationMinutes: $0.durationMinutes, kind: $0.kindRawValue, sourceName: $0.sourceName, deviceReportedCalories: $0.deviceReportedCalories, appEstimatedCalories: $0.appEstimatedCalories, confidence: $0.estimateConfidenceRawValue, algorithmVersion: $0.algorithmVersion)
            },
            metrics: metrics.map {
                ExportMetric(type: $0.typeRawValue, name: $0.displayName, value: $0.value, unit: $0.unit, loggedAt: $0.loggedAt, sourceName: $0.sourceName)
            },
            goals: goals.map {
                ExportGoal(type: $0.typeRawValue, targetValue: $0.targetValue, unit: $0.unit, cadence: $0.cadenceRawValue, isActive: $0.isActive)
            },
            aiSummaries: aiSummaries.map {
                ExportAISummary(createdAt: $0.createdAt, startDate: $0.startDate, endDate: $0.endDate, model: $0.model)
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard
            let data = try? encoder.encode(export),
            let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return json
    }
}

private struct LocalExport: Codable {
    var exportedAt: Date
    var disclaimer: String
    var profiles: [ExportProfile]
    var meals: [ExportMeal]
    var workouts: [ExportWorkout]
    var metrics: [ExportMetric]
    var goals: [ExportGoal]
    var aiSummaries: [ExportAISummary]
}

private struct ExportProfile: Codable {
    var username: String
    var ageYears: Int
    var sex: String
    var dateOfBirth: Date?
    var heightCentimeters: Double
    var bodyMassKg: Double
    var goalBodyMassKg: Double?
    var activityLevel: String
    var unitSystem: String
    var goalSummary: String
}

private struct ExportMeal: Codable {
    var title: String
    var mealType: String
    var customMealTypeName: String
    var loggedAt: Date
    var calories: Double
    var proteinGrams: Double
    var source: String
}

private struct ExportWorkout: Codable {
    var title: String
    var startedAt: Date
    var durationMinutes: Double
    var kind: String
    var sourceName: String
    var deviceReportedCalories: Double?
    var appEstimatedCalories: Double?
    var confidence: String
    var algorithmVersion: String
}

private struct ExportMetric: Codable {
    var type: String
    var name: String
    var value: Double
    var unit: String
    var loggedAt: Date
    var sourceName: String
}

private struct ExportGoal: Codable {
    var type: String
    var targetValue: Double
    var unit: String
    var cadence: String
    var isActive: Bool
}

private struct ExportAISummary: Codable {
    var createdAt: Date
    var startDate: Date
    var endDate: Date
    var model: String
}

private extension String {
    var displayName: String {
        split(separator: "_").joined(separator: " ").capitalized
    }
}

#Preview {
    SettingsView()
}
