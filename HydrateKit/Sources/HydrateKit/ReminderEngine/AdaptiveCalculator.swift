import Foundation

public final class AdaptiveCalculator {
    public init() {}

    /// 计算距下次提醒的秒数
    /// - Parameters:
    ///   - currentML: 今日已喝
    ///   - targetML: 今日目标
    ///   - rule: 提醒规则
    ///   - currentTime: 当前时间
    ///   - lastExerciseMinutes: 最近一次运动时长（分钟），用于触发运动后提醒
    /// - Returns: 下次提醒间隔（秒）；0 = 立即提醒；86400 = 跳过今天
    public func nextInterval(
        currentML: Double,
        targetML: Double,
        rule: ReminderRule,
        currentTime: Date,
        lastExerciseMinutes: Double
    ) -> TimeInterval {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMinutes = hour * 60 + minute
        let startMinutes = rule.startHour * 60 + rule.startMinute
        let endMinutes = rule.endHour * 60 + rule.endMinute

        // 1. 检查静默时段 — 非提醒时段跳过
        if currentMinutes < startMinutes || currentMinutes > endMinutes {
            return 86400
        }

        // 2. 检查星期
        let weekday = calendar.component(.weekday, from: currentTime)
        if !rule.enabledWeekdays.contains(weekday) {
            return 86400
        }

        // 3. 运动后立即提醒（运动 >= 30 分钟）
        if lastExerciseMinutes >= 30 {
            return 0
        }

        // 4. 进度落后 -> 缩短间隔
        let progress = currentML / targetML
        let dayProgress = Double(currentMinutes - startMinutes) / Double(endMinutes - startMinutes)

        if dayProgress > 0.5 && progress < 0.5 {
            return 30 * 60
        }

        // 5. 正常间隔
        return TimeInterval(rule.baseIntervalMinutes * 60)
    }
}
