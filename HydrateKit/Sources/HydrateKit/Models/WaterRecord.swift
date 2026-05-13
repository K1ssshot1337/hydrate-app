import Foundation

public enum RecordSource: String, Codable, CaseIterable {
    case manual
    case siri
    case watch
}

public struct WaterRecord: Identifiable, Codable, Hashable {
    public let id: UUID
    public let amount: Double
    public let timestamp: Date
    public let source: RecordSource

    public init(id: UUID = UUID(), amount: Double, timestamp: Date = Date(), source: RecordSource = .manual) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.source = source
    }
}
