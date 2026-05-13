import XCTest
@testable import HydrateKit

final class PortionAccumulationTests: XCTestCase {
    func test_defaultPresetsHaveCorrectPortions() {
        let defaults = DrinkContainer.defaults
        XCTAssertEqual(defaults.count, 3)

        // 保温杯
        XCTAssertEqual(defaults[0].name, "保温杯")
        XCTAssertEqual(defaults[0].totalAmount, 480)

        // 矿泉水 — 分量为累加小分量
        if case .portionSelect(let portions) = defaults[1].mode {
            let total = portions.reduce(0) { $0 + $1.amount }
            XCTAssertEqual(portions.count, 3)
            // 各分量和为 300+375+500=1175，小于总量 1500（不是一口气喝完）
            XCTAssertEqual(total, 1175)
        } else {
            XCTFail("矿泉水应为 portionSelect")
        }

        // 其他
        if case .portionSelect(let portions) = defaults[2].mode {
            XCTAssertEqual(portions.count, 3)
            XCTAssertEqual(portions.map(\.amount), [250, 500, 800])
        } else {
            XCTFail("其他应为 portionSelect")
        }
    }

    func test_customContainer() {
        let container = DrinkContainer(
            name: "自定义",
            totalAmount: 1000,
            icon: "drop.fill",
            mode: .oneTap
        )
        XCTAssertEqual(container.totalAmount, 1000)
    }
}
