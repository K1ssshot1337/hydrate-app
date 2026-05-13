import Foundation

public struct DailyGoal: Identifiable {
    public let id: UUID
    public let date: Date
    public var targetML: Double
    public var currentML: Double

    public var progress: Double {
        guard targetML > 0 else { return 0 }
        return min(currentML / targetML, 1.0)
    }

    public var isMet: Bool {
        currentML >= targetML
    }

    public init(id: UUID = UUID(), date: Date = Date(), targetML: Double = 2000, currentML: Double = 0) {
        self.id = id
        self.date = date
        self.targetML = targetML
        self.currentML = currentML
    }

    /// 根据体重计算建议饮水量 (ml) — 每公斤体重约 33ml
    public static func recommendedTarget(weightKG: Double) -> Double {
        weightKG * 33.0
    }
}
