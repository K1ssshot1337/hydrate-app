import SwiftUI
import HydrateKit

struct HomeView: View {
    @State private var todayML: Double = 0
    @State private var targetML: Double = 2000
    @State private var selectedContainer: DrinkContainer?
    @State private var showPortionPicker = false
    @State private var recentRecords: [WaterRecord] = []

    private let store = WaterRecordStore()
    private let containers = DrinkContainer.defaults

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    progressRing

                    VStack(spacing: 4) {
                        Text("\(Int(todayML))")
                            .font(.system(size: 48, weight: .bold))
                        Text("/ \(Int(targetML)) ml")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        ForEach(containers) { container in
                            containerButton(container)
                        }
                    }
                    .padding(.horizontal)

                    if !recentRecords.isEmpty {
                        recentRecordsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Hydrate")
            .sheet(isPresented: $showPortionPicker) {
                if let container = selectedContainer {
                    PortionPickerSheet(container: container) { portion in
                        recordDrink(container: container, amount: portion.amount)
                        showPortionPicker = false
                    }
                }
            }
            .onAppear { refresh() }
        }
    }

    // MARK: - 进度环

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 20)
            Circle()
                .trim(from: 0, to: min(todayML / targetML, 1.0))
                .stroke(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: todayML)
        }
        .frame(width: 200, height: 200)
        .padding(.top)
    }

    // MARK: - 容器按钮

    private func containerButton(_ container: DrinkContainer) -> some View {
        Button {
            handleTap(container)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: container.icon)
                    .font(.system(size: 32))
                Text(container.name)
                    .font(.caption)
                if case .oneTap = container.mode {
                    Text("\(Int(container.totalAmount ?? 0))ml")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func handleTap(_ container: DrinkContainer) {
        switch container.mode {
        case .oneTap:
            recordDrink(container: container, amount: container.totalAmount ?? 0)
        case .portionSelect:
            selectedContainer = container
            showPortionPicker = true
        }
    }

    // MARK: - 记录操作

    private func recordDrink(container: DrinkContainer, amount: Double) {
        let record = WaterRecord(amount: amount, source: .manual)
        store.addRecord(record)
        HealthKitService.shared.saveWater(ml: amount)
        WCManager.shared.sendRecord(record)
        refresh()
    }

    // MARK: - 最近记录

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日记录")
                .font(.headline)
                .padding(.horizontal)

            ForEach(recentRecords.prefix(10)) { record in
                HStack {
                    Image(systemName: record.source.iconName)
                    Text(record.timestamp, style: .time)
                    Spacer()
                    Text("\(Int(record.amount))ml")
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
            }
        }
    }

    private func refresh() {
        todayML = store.todayTotal()
        recentRecords = store.recordsForDate(Date())
    }
}

extension RecordSource {
    var iconName: String {
        switch self {
        case .manual: return "hand.tap.fill"
        case .siri: return "waveform"
        case .watch: return "applewatch"
        }
    }
}
