import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var meals: [MealEntry]
    @Query private var workouts: [WorkoutEntry]
    @Query private var metrics: [HealthMetricEntry]
    @Query private var goals: [Goal]
    @Query private var aiSummaries: [AISummary]
    @Query private var settings: [AppSettings]

    @StateObject private var healthKitService = HealthKitService()
    @State private var aiFeaturesEnabled = false
    @State private var healthKitSyncEnabled = false
    @State private var showDeviceCalories = true
    @State private var showAppEstimatedCalories = true
    @State private var openAIModel = "gpt-5.5"
    @State private var apiKey = ""
    @State private var statusMessage: String?
    @State private var showingDeleteConfirmation = false

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
                Section("Privacy") {
                    Label("No cloud database", systemImage: "icloud.slash")
                    Label("No third-party analytics", systemImage: "chart.bar.xaxis")
                    Label("API keys stay in Keychain", systemImage: "key")
                    Text(SummaryService.wellnessDisclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apple Health") {
                    Toggle("HealthKit Sync", isOn: $healthKitSyncEnabled)
                    Button {
                        Task { await requestHealthAccess() }
                    } label: {
                        Label("Request Health Access", systemImage: "heart.text.square")
                    }
                    Text(healthKitService.authorizationStatusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Calories") {
                    Toggle("Device Reported Calories", isOn: $showDeviceCalories)
                    Toggle("App Estimated Calories", isOn: $showAppEstimatedCalories)
                }

                Section("ChatGPT") {
                    Toggle("AI Features", isOn: $aiFeaturesEnabled)
                    TextField("Model", text: $openAIModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("OpenAI API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        Button {
                            saveAPIKey()
                        } label: {
                            Label("Save Key", systemImage: "key.fill")
                        }
                        Spacer()
                        Button(role: .destructive) {
                            deleteAPIKey()
                        } label: {
                            Label("Delete Key", systemImage: "trash")
                        }
                    }
                }

                Section("Data") {
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
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: loadSettings)
            .onChange(of: aiFeaturesEnabled) { _, _ in saveSettings() }
            .onChange(of: healthKitSyncEnabled) { _, _ in saveSettings() }
            .onChange(of: showDeviceCalories) { _, _ in saveSettings() }
            .onChange(of: showAppEstimatedCalories) { _, _ in saveSettings() }
            .onChange(of: openAIModel) { _, _ in saveSettings() }
            .alert("Delete all local data?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive, action: deleteAllLocalData)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Meals, workouts, metrics, goals, summaries, settings, and the Keychain API key will be removed from this device.")
            }
        }
    }

    private func loadSettings() {
        let current = settings.first
        aiFeaturesEnabled = current?.aiFeaturesEnabled ?? false
        healthKitSyncEnabled = current?.healthKitSyncEnabled ?? false
        showDeviceCalories = current?.showDeviceCalories ?? true
        showAppEstimatedCalories = current?.showAppEstimatedCalories ?? true
        openAIModel = current?.openAIModel ?? "gpt-5.5"

        if (try? KeychainService.shared.loadOpenAIAPIKey()) != nil {
            statusMessage = "OpenAI API key is stored in Keychain."
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
        current.updatedAt = .now
        try? modelContext.save()
    }

    private func saveAPIKey() {
        do {
            try KeychainService.shared.saveOpenAIAPIKey(apiKey)
            apiKey = ""
            statusMessage = "OpenAI API key saved to Keychain."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func deleteAPIKey() {
        do {
            try KeychainService.shared.deleteOpenAIAPIKey()
            apiKey = ""
            statusMessage = "OpenAI API key deleted from Keychain."
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
                ExportProfile(ageYears: $0.ageYears, sex: $0.sexRawValue, heightCentimeters: $0.heightCentimeters, bodyMassKg: $0.bodyMassKg, activityLevel: $0.activityLevelRawValue, goalSummary: $0.goalSummary)
            },
            meals: meals.map {
                ExportMeal(title: $0.title, loggedAt: $0.loggedAt, calories: $0.totalCalories, proteinGrams: $0.totalProtein, source: $0.sourceRawValue)
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
    var ageYears: Int
    var sex: String
    var heightCentimeters: Double
    var bodyMassKg: Double
    var activityLevel: String
    var goalSummary: String
}

private struct ExportMeal: Codable {
    var title: String
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

#Preview {
    SettingsView()
}

