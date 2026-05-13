import Foundation
import CoreData

public final class CoreDataStack: @unchecked Sendable {
    public static let shared = CoreDataStack()

    public let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "HydrateModel", managedObjectModel: Self.model)

        let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.hydrate")?
            .appendingPathComponent("HydrateModel.sqlite")
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("HydrateModel.sqlite")

        container.persistentStoreDescriptions = [
            NSPersistentStoreDescription(url: storeURL)
        ]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data store failed: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - 用代码定义 Model（无需 .xcdatamodeld）

    private static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        // WaterRecordEntity
        let recordEntity = NSEntityDescription()
        recordEntity.name = "WaterRecordEntity"
        recordEntity.managedObjectClassName = "HydrateKit.WaterRecordEntity"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"; idAttr.attributeType = .UUIDAttributeType; idAttr.isOptional = false
        let amountAttr = NSAttributeDescription()
        amountAttr.name = "amount"; amountAttr.attributeType = .doubleAttributeType; amountAttr.isOptional = false
        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"; timestampAttr.attributeType = .dateAttributeType; timestampAttr.isOptional = false
        let sourceAttr = NSAttributeDescription()
        sourceAttr.name = "source"; sourceAttr.attributeType = .stringAttributeType; sourceAttr.isOptional = false

        recordEntity.properties = [idAttr, amountAttr, timestampAttr, sourceAttr]

        // SyncLogEntity
        let syncEntity = NSEntityDescription()
        syncEntity.name = "SyncLogEntity"
        syncEntity.managedObjectClassName = "HydrateKit.SyncLogEntity"

        let syncIdAttr = NSAttributeDescription()
        syncIdAttr.name = "recordID"; syncIdAttr.attributeType = .UUIDAttributeType; syncIdAttr.isOptional = false
        let syncedAtAttr = NSAttributeDescription()
        syncedAtAttr.name = "syncedAt"; syncedAtAttr.attributeType = .dateAttributeType; syncedAtAttr.isOptional = false

        syncEntity.properties = [syncIdAttr, syncedAtAttr]

        // ReminderRuleEntity
        let ruleEntity = NSEntityDescription()
        ruleEntity.name = "ReminderRuleEntity"
        ruleEntity.managedObjectClassName = "HydrateKit.ReminderRuleEntity"

        let sHour = NSAttributeDescription()
        sHour.name = "startHour"; sHour.attributeType = .integer64AttributeType; sHour.isOptional = false
        let sMin = NSAttributeDescription()
        sMin.name = "startMinute"; sMin.attributeType = .integer64AttributeType; sMin.isOptional = false
        let eHour = NSAttributeDescription()
        eHour.name = "endHour"; eHour.attributeType = .integer64AttributeType; eHour.isOptional = false
        let eMin = NSAttributeDescription()
        eMin.name = "endMinute"; eMin.attributeType = .integer64AttributeType; eMin.isOptional = false
        let intervalAttr = NSAttributeDescription()
        intervalAttr.name = "baseIntervalMinutes"; intervalAttr.attributeType = .integer64AttributeType; intervalAttr.isOptional = false
        let weekdaysAttr = NSAttributeDescription()
        weekdaysAttr.name = "enabledWeekdays"; weekdaysAttr.attributeType = .transformableAttributeType
        weekdaysAttr.valueTransformerName = NSStringFromClass(NSSecureUnarchiveFromDataTransformer.self)

        ruleEntity.properties = [sHour, sMin, eHour, eMin, intervalAttr, weekdaysAttr]

        model.entities = [recordEntity, syncEntity, ruleEntity]
        return model
    }()

    public func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
}

// MARK: - NSManagedObject 子类

@objc(WaterRecordEntity)
public class WaterRecordEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var amount: Double
    @NSManaged public var timestamp: Date
    @NSManaged public var source: String
}

@objc(SyncLogEntity)
public class SyncLogEntity: NSManagedObject {
    @NSManaged public var recordID: UUID
    @NSManaged public var syncedAt: Date
}

@objc(ReminderRuleEntity)
public class ReminderRuleEntity: NSManagedObject {
    @NSManaged public var startHour: Int
    @NSManaged public var startMinute: Int
    @NSManaged public var endHour: Int
    @NSManaged public var endMinute: Int
    @NSManaged public var baseIntervalMinutes: Int
    @NSManaged public var enabledWeekdays: Set<Int>
}
