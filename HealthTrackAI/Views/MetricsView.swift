import SwiftData
import SwiftUI

struct MetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthMetricEntry.loggedAt, order: .reverse) private var metrics: [HealthMetricEntry]
    @State private var showingAddMetric = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(metric.displayName, systemImage: icon(for: metric.type))
                                .font(.headline)
                            Spacer()
                            Text("\(metric.value.formatted(.number.precision(.fractionLength(0...2)))) \(metric.unit)")
                                .fontWeight(.semibold)
                        }
                        Text(metric.loggedAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !metric.note.isEmpty {
                            Text(metric.note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
                AddMetricView()
            }
        }
    }

    private func deleteMetrics(at offsets: IndexSet) {
        offsets.map { metrics[$0] }.forEach(modelContext.delete)
        try? modelContext.save()
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
}

private struct AddMetricView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var type: MetricType = .bodyMass
    @State private var customName = ""
    @State private var value = 0.0
    @State private var unit = "kg"
    @State private var note = ""

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
            }
            .navigationTitle("Add Metric")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMetric()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveMetric() {
        let metric = HealthMetricEntry(
            type: type,
            customName: customName,
            value: value,
            unit: unit,
            note: note
        )
        modelContext.insert(metric)
        try? modelContext.save()
    }

    private func defaultUnit(for type: MetricType) -> String {
        switch type {
        case .bodyMass: "kg"
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

