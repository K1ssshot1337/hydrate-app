import SwiftUI
import HydrateKit

struct WatchHomeView: View {
    @State private var todayML: Double = 0
    @State private var targetML: Double = 2000

    private let store = WaterRecordStore()
    private let containers = DrinkContainer.defaults

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.15), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: min(todayML / targetML, 1.0))
                            .stroke(Color.cyan, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(Int(todayML))")
                                .font(.system(size: 24, weight: .bold))
                            Text("ml")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)

                    ForEach(containers) { container in
                        NavigationLink {
                            if case .portionSelect(let portions) = container.mode {
                                PortionPickerView(container: container, portions: portions) { amount in
                                    recordDrink(container: container, amount: amount)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: container.icon)
                                Text(container.name)
                                Spacer()
                                if case .oneTap = container.mode {
                                    Text("\(Int(container.totalAmount ?? 0))ml")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onTapGesture {
                            if case .oneTap = container.mode {
                                recordDrink(container: container, amount: container.totalAmount ?? 0)
                            }
                        }
                    }
                }
                .padding()
            }
            .onAppear { refresh() }
        }
    }

    private func recordDrink(container: DrinkContainer, amount: Double) {
        let record = WaterRecord(amount: amount, source: .watch)
        store.addRecord(record)
        WCManager.shared.sendRecord(record)
        refresh()
    }

    private func refresh() {
        todayML = store.todayTotal()
    }
}
