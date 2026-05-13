import Foundation

public struct ReminderRule: Equatable {
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int
    public var baseIntervalMinutes: Int
    public var enabledWeekdays: Set<Int>  // 1=周日...7=周六

    public static let `default` = ReminderRule(
        startHour: 9, startMinute: 0,
        endHour: 21, endMinute: 0,
        baseIntervalMinutes: 45,
        enabledWeekdays: Set(1...7)
    )

    public init(
        startHour: Int, startMinute: Int,
        endHour: Int, endMinute: Int,
        baseIntervalMinutes: Int,
        enabledWeekdays: Set<Int>
    ) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.baseIntervalMinutes = baseIntervalMinutes
        self.enabledWeekdays = enabledWeekdays
    }
}
