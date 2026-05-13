import Foundation

public final class AssessmentEngine {
    public init() {}

    public func assess(
        weekStart: Date,
        dailyAmounts: [Double],
        targetML: Double,
        prevAvg: Double
    ) -> WeeklyAssessment {
        let avgDailyML = dailyAmounts.isEmpty ? 0 : dailyAmounts.reduce(0, +) / Double(dailyAmounts.count)
        let goalMetDays = dailyAmounts.filter { $0 >= targetML }.count
        let grade = calculateGrade(avgDailyML: avgDailyML, targetML: targetML, goalMetDays: goalMetDays, totalDays: dailyAmounts.count)
        let trend = calculateTrend(currentAvg: avgDailyML, previousAvg: prevAvg)
        let suggestion = generateSuggestion(grade: grade, trend: trend, avgDailyML: avgDailyML, targetML: targetML, goalMetDays: goalMetDays)

        return WeeklyAssessment(
            weekStart: weekStart,
            avgDailyML: avgDailyML,
            goalMetDays: goalMetDays,
            grade: grade,
            trend: trend,
            suggestion: suggestion
        )
    }

    private func calculateGrade(avgDailyML: Double, targetML: Double, goalMetDays: Int, totalDays: Int) -> HydrateGrade {
        let ratio = avgDailyML / targetML
        let metRatio = totalDays > 0 ? Double(goalMetDays) / Double(min(totalDays, 7)) : 0

        if ratio >= 0.9 && metRatio >= 0.8 { return .a }
        if ratio >= 0.7 && metRatio >= 0.5 { return .b }
        if ratio >= 0.5 { return .c }
        return .d
    }

    private func calculateTrend(currentAvg: Double, previousAvg: Double) -> HydrateTrend {
        guard previousAvg > 0 else { return .stable }
        let change = (currentAvg - previousAvg) / previousAvg
        if change > 0.1 { return .up }
        if change < -0.1 { return .down }
        return .stable
    }

    private func generateSuggestion(
        grade: HydrateGrade,
        trend: HydrateTrend,
        avgDailyML: Double,
        targetML: Double,
        goalMetDays: Int
    ) -> String {
        let deficit = Int(targetML - avgDailyML)

        switch (grade, trend) {
        case (.a, .up): return "表现优秀且持续进步，保持这个节奏!"
        case (.a, _): return "本周达标情况很好，继续保持！"
        case (.b, .down): return "本周有下滑趋势，平均每天少喝 \(deficit)ml，注意在运动后及时补水"
        case (.b, _): return "还不错！再努力一点就能达到优秀了"
        case (.c, .down): return "饮水量明显不足且在下滑，建议将水瓶放在显眼位置提醒自己"
        case (.c, _): return "平均每天比目标少 \(deficit)ml，试试在每餐前固定喝一杯水"
        case (.d, _): return "本周饮水严重不足，平均每天仅 \(Int(avgDailyML))ml。建议开启高频提醒模式"
        }
    }
}
