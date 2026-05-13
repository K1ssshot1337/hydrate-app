import XCTest
@testable import HydrateKit

final class AdaptiveCalculatorTests: XCTestCase {
    let calculator = AdaptiveCalculator()
    let rule = ReminderRule.default

    func test_normalProgress_returnsBaseInterval() {
        let interval = calculator.nextInterval(
            currentML: 1200, targetML: 2000,
            rule: rule, currentTime: makeDate(15, 0),
            lastExerciseMinutes: 5
        )
        XCTAssertEqual(interval, 2700)
    }

    func test_behindSchedule_shortensInterval() {
        let interval = calculator.nextInterval(
            currentML: 600, targetML: 2000,
            rule: rule, currentTime: makeDate(16, 0),
            lastExerciseMinutes: 0
        )
        XCTAssertEqual(interval, 1800)
    }

    func test_recentExercise_triggersImmediateReminder() {
        let interval = calculator.nextInterval(
            currentML: 800, targetML: 2000,
            rule: rule, currentTime: makeDate(14, 0),
            lastExerciseMinutes: 35
        )
        XCTAssertEqual(interval, 0)
    }

    func test_outsideReminderWindow_returnsLargeInterval() {
        let interval = calculator.nextInterval(
            currentML: 500, targetML: 2000,
            rule: rule, currentTime: makeDate(22, 0),
            lastExerciseMinutes: 0
        )
        XCTAssertEqual(interval, 86400)
    }

    private func makeDate(_ hour: Int, _ minute: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: 2026, month: 5, day: 13, hour: hour, minute: minute))!
    }
}
