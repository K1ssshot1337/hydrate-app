import AppIntents
import HydrateKit

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "记录喝水"
    static let description = IntentDescription("快速记录一杯喝水")

    @Parameter(title: "毫升")
    var amount: Double

    init() {
        self.amount = 480
    }

    init(amount: Double) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        let record = WaterRecord(amount: amount, source: .siri)
        WaterRecordStore().addRecord(record)

        try? await HealthKitService.shared.saveWaterIntake(ml: amount)
        WCManager.shared.sendRecord(record)

        return .result(dialog: "已记录 \(Int(amount))ml 喝水")
    }
}

struct HydrateShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "记录喝了杯水",
                "记录喝水",
                "我今天喝了水",
            ],
            shortTitle: "记录喝水"
        )
    }
}
