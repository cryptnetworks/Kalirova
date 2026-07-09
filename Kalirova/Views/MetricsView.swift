import SwiftData
import SwiftUI

struct MetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthMetricEntry.loggedAt, order: .reverse) private var metrics: [HealthMetricEntry]
    @Query private var settings: [AppSettings]
    @State private var showingAddMetric = false
    @State private var activeError: AppError?

    private var unitSystem: UnitSystem {
        settings.first?.unitSystem ?? .metric
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(metric.displayName, systemImage: icon(for: metric.type))
                                .font(.headline)
                            Spacer()
                            Text(displayValue(for: metric))
                                .fontWeight(.semibold)
                        }
                        Text(metric.loggedAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                        if !metric.note.isEmpty {
                            Text(metric.note)
                                .font(.subheadline)
                                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteMetrics)
            }
            .overlay {
                if metrics.isEmpty {
                    ContentUnavailableView("No metrics logged", systemImage: "waveform.path.ecg")
                }
            }
            .navigationTitle("Metrics")
            .appErrorAlert(error: $activeError)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMetric = true
                    } label: {
                        Label("Add Metric", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMetric) {
                AddMetricView(unitSystem: unitSystem)
            }
        }
    }

    private func deleteMetrics(at offsets: IndexSet) {
        offsets.map { metrics[$0] }.forEach(modelContext.delete)
        do {
            try modelContext.saveChanges(context: "Metric deletion")
        } catch {
            let appError = ErrorMessageMapper.map(error, fallback: .deleteFailed(context: "Metric"), technicalContext: "Delete metrics")
            AppErrorLogger.log(appError, source: "Metrics delete")
            activeError = appError
        }
    }

    private func icon(for type: MetricType) -> String {
        switch type {
        case .bodyMass: "scalemass"
        case .bodyFat: "percent"
        case .water: "drop"
        case .sleep: "bed.double"
        case .steps: "shoeprints.fill"
        case .heartRate: "heart"
        case .mood: "face.smiling"
        case .note: "note.text"
        case .custom: "slider.horizontal.3"
        }
    }

    private func displayValue(for metric: HealthMetricEntry) -> String {
        if metric.type == .bodyMass {
            return metric.value.formattedWeight(unitSystem: unitSystem)
        }

        return "\(metric.value.formatted(.number.precision(.fractionLength(0...2)))) \(metric.unit)"
    }
}

private struct AddMetricView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var unitSystem: UnitSystem

    @State private var type: MetricType = .bodyMass
    @State private var customName = ""
    @State private var value = 0.0
    @State private var unit = "kg"
    @State private var note = ""
    @State private var activeError: AppError?

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    Picker("Type", selection: $type) {
                        ForEach(MetricType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .onChange(of: type) { _, newValue in
                        unit = defaultUnit(for: newValue)
                    }

                    if type == .custom {
                        TextField("Name", text: $customName)
                    }

                    LabeledContent("Value") {
                        TextField("Value", value: $value, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("Unit", text: $unit)
                    TextField("Note", text: $note, axis: .vertical)
                }

                if let activeError {
                    Section("Needs Attention") {
                        AppErrorBanner(error: activeError) {
                            self.activeError = nil
                        }
                    }
                }
            }
            .navigationTitle("Add Metric")
            .onAppear {
                unit = defaultUnit(for: type)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try validateMetric()
                            try saveMetric()
                            dismiss()
                        } catch {
                            let appError = ErrorMessageMapper.map(error, fallback: .saveFailed(context: "Metric"), technicalContext: "Save metric")
                            AppErrorLogger.log(appError, source: "Metrics save")
                            activeError = appError
                        }
                    }
                }
            }
        }
    }

    private func saveMetric() throws {
        let normalizedValue: Double
        let normalizedUnit: String

        if type == .bodyMass, unitSystem == .imperial {
            normalizedValue = UnitConverter.kilograms(fromPounds: value)
            normalizedUnit = "kg"
        } else {
            normalizedValue = value
            normalizedUnit = unit
        }

        let metric = HealthMetricEntry(
            type: type,
            customName: customName,
            value: normalizedValue,
            unit: normalizedUnit,
            note: note
        )
        modelContext.insert(metric)
        try modelContext.saveChanges(context: type == .bodyMass ? "Weight entry" : "Metric")
    }

    private func validateMetric() throws {
        guard value >= 0 else {
            throw AppError.validation("Metric value cannot be negative.", field: "Metric value", recoverySuggestion: "Use zero when a value is not available.")
        }
        guard type != .custom || !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation("Custom metrics need a name.", field: "Metric name", recoverySuggestion: "Enter a short name for this metric.")
        }
        guard type == .note || !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation("Unit cannot be empty.", field: "Metric unit", recoverySuggestion: "Enter a unit such as kg, lb, L, hr, or bpm.")
        }
        if type == .bodyMass {
            guard value > 0 else {
                throw AppError.validation("Weight must be greater than zero.", field: "Weight", recoverySuggestion: "Enter your current weight.")
            }
        }
    }

    private func defaultUnit(for type: MetricType) -> String {
        switch type {
        case .bodyMass: unitSystem == .imperial ? "lb" : "kg"
        case .bodyFat: "%"
        case .water: "L"
        case .sleep: "hr"
        case .steps: "steps"
        case .heartRate: "bpm"
        case .mood: "score"
        case .note: ""
        case .custom: ""
        }
    }
}

#Preview {
    MetricsView()
}
