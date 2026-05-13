import Foundation
import CoreData

public final class WaterRecordStore {
    private let stack: CoreDataStack

    public init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - 写入

    public func addRecord(_ record: WaterRecord) {
        let context = stack.container.viewContext
        let entity = WaterRecordEntity(context: context)
        entity.id = record.id
        entity.amount = record.amount
        entity.timestamp = record.timestamp
        entity.source = record.source.rawValue
        stack.saveContext()
    }

    // MARK: - 查询

    public func recordsForDate(_ date: Date) -> [WaterRecord] {
        let context = stack.container.viewContext
        let request = WaterRecordEntity.fetchRequest() as! NSFetchRequest<WaterRecordEntity>

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate, endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let entities = try context.fetch(request)
            return entities.map { WaterRecord(
                id: $0.id,
                amount: $0.amount,
                timestamp: $0.timestamp,
                source: RecordSource(rawValue: $0.source) ?? .manual
            )}
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    /// 当日累计饮水 (ml)
    public func todayTotal() -> Double {
        recordsForDate(Date()).reduce(0) { $0 + $1.amount }
    }

    /// 查询日期范围内的所有记录
    public func recordsBetween(start: Date, end: Date) -> [WaterRecord] {
        let context = stack.container.viewContext
        let request = WaterRecordEntity.fetchRequest() as! NSFetchRequest<WaterRecordEntity>

        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            start as NSDate, end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let entities = try context.fetch(request)
            return entities.map { WaterRecord(
                id: $0.id,
                amount: $0.amount,
                timestamp: $0.timestamp,
                source: RecordSource(rawValue: $0.source) ?? .manual
            )}
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    /// 删除一条记录
    public func deleteRecord(id: UUID) {
        let context = stack.container.viewContext
        let request = WaterRecordEntity.fetchRequest() as! NSFetchRequest<WaterRecordEntity>
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                stack.saveContext()
            }
        } catch {
            print("Delete error: \(error)")
        }
    }
}
