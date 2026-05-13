import Foundation

public enum HydrateGrade: String, Codable, CaseIterable {
    case a = "优秀"
    case b = "良好"
    case c = "需改善"
    case d = "严重不足"
}

public enum HydrateTrend: String, Codable, CaseIterable {
    case up = "↑"
    case stable = "→"
    case down = "↓"
}

public struct WeeklyAssessment: Identifiable {
    public let id: UUID
    public let weekStart: Date
    public let avgDailyML: Double
    public let goalMetDays: Int
    public let grade: HydrateGrade
    public let trend: HydrateTrend
    public let suggestion: String

    public init(
        id: UUID = UUID(),
        weekStart: Date,
        avgDailyML: Double,
        goalMetDays: Int,
        grade: HydrateGrade,
        trend: HydrateTrend,
        suggestion: String
    ) {
        self.id = id
        self.weekStart = weekStart
        self.avgDailyML = avgDailyML
        self.goalMetDays = goalMetDays
        self.grade = grade
        self.trend = trend
        self.suggestion = suggestion
    }
}
