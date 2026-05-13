import Foundation

public enum ContainerMode: Equatable {
    case oneTap
    case portionSelect([Portion])
}

public struct Portion: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let amount: Double

    public init(id: UUID = UUID(), name: String, amount: Double) {
        self.id = id
        self.name = name
        self.amount = amount
    }
}

public struct DrinkContainer: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var totalAmount: Double?
    public var icon: String
    public var mode: ContainerMode

    public init(id: UUID = UUID(), name: String, totalAmount: Double? = nil, icon: String, mode: ContainerMode) {
        self.id = id
        self.name = name
        self.totalAmount = totalAmount
        self.icon = icon
        self.mode = mode
    }

    /// 默认预设：保温杯(480ml 一键)、矿泉水(1500ml 分份)、其他(多种规格)
    public static let defaults: [DrinkContainer] = [
        DrinkContainer(
            name: "保温杯",
            totalAmount: 480,
            icon: "cup.and.saucer.fill",
            mode: .oneTap
        ),
        DrinkContainer(
            name: "矿泉水",
            totalAmount: 1500,
            icon: "waterbottle.fill",
            mode: .portionSelect([
                Portion(name: "1/5 瓶", amount: 300),
                Portion(name: "1/4 瓶", amount: 375),
                Portion(name: "1/3 瓶", amount: 500),
            ])
        ),
        DrinkContainer(
            name: "其他",
            icon: "takeoutbag.and.cup.and.straw.fill",
            mode: .portionSelect([
                Portion(name: "250ml 小瓶", amount: 250),
                Portion(name: "500ml 中瓶", amount: 500),
                Portion(name: "800ml 大瓶", amount: 800),
            ])
        ),
    ]
}
