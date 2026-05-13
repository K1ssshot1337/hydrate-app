import XCTest
@testable import HydrateKit

final class AssessmentEngineTests: XCTestCase {
    let engine = AssessmentEngine()

    func test_assessExcellent() {
        let assessment = engine.assess(
            weekStart: Date(),
            dailyAmounts: [2100, 2050, 1950, 2150, 2000, 2200, 1980],
            targetML: 2000,
            prevAvg: 1800
        )
        XCTAssertEqual(assessment.grade, .a)
        XCTAssertEqual(assessment.trend, .up)
        XCTAssertEqual(assessment.goalMetDays, 5)
    }

    func test_assessNeedsImprovement() {
        let assessment = engine.assess(
            weekStart: Date(),
            dailyAmounts: [800, 1000, 500, 1200, 900, 600, 1100],
            targetML: 2000,
            prevAvg: 1600
        )
        XCTAssertEqual(assessment.grade, .d)
        XCTAssertEqual(assessment.trend, .down)
    }

    func test_emptyWeek_returnsGradeD() {
        let assessment = engine.assess(
            weekStart: Date(),
            dailyAmounts: [],
            targetML: 2000,
            prevAvg: 1800
        )
        XCTAssertEqual(assessment.grade, .d)
    }
}
