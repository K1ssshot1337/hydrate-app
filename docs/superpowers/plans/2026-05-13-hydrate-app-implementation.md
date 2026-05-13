# Hydrate App — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 构建一款原生 iOS/watchOS 智能喝水提醒应用，支持快捷记录、智能自适应提醒、HealthKit 集成、Watch 独立 App、表盘组件、Siri 捷径及每周健康评估。

**Architecture:** 共享 Swift Package (HydrateKit) 包含所有业务逻辑、数据模型和 Core Data 持久化。iPhone App 和 Watch App 是独立的 UI 壳层，通过 HydrateKit 共享代码，通过 WatchConnectivity 同步数据。

**Tech Stack:** Swift 5.9+, SwiftUI, Core Data (NSPersistentContainer), HealthKit, WatchConnectivity, UserNotifications, BackgroundTasks, Siri Intents, WidgetKit

**注意:** 创建 Xcode 项目 (.xcodeproj) 需要在 macOS Xcode 中手动操作。本计划覆盖所有 Swift 源代码编写，对应 Xcode 步骤在任务中标注。

---

## 文件布局总览

```
hydrate_app/
├── HydrateKit/
│   ├── Package.swift
│   ├── Sources/HydrateKit/
│   │   ├── Models/
│   │   │   ├── WaterRecord.swift
│   │   │   ├── DailyGoal.swift
│   │   │   ├── ReminderRule.swift
│   │   │   ├── CupPreset.swift
│   │   │   └── WeeklyAssessment.swift
│   │   ├── Storage/
│   │   │   ├── CoreDataStack.swift
│   │   │   ├── CoreDataModel.xcdatamodeld/  (Xcode 创建)
│   │   │   ├── WaterRecordStore.swift
│   │   │   └── HealthKitService.swift
│   │   ├── ReminderEngine/
│   │   │   ├── ReminderScheduler.swift
│   │   │   └── AdaptiveCalculator.swift
│   │   ├── SyncService/
│   │   │   └── WCManager.swift
│   │   └── Assessment/
│   │       └── AssessmentEngine.swift
│   └── Tests/HydrateKitTests/
│       ├── AdaptiveCalculatorTests.swift
│       ├── PortionAccumulationTests.swift
│       ├── AssessmentEngineTests.swift
│       └── SyncLogTests.swift
├── HydrateApp/
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── HistoryView.swift
│   │   └── SettingsView.swift
│   ├── Intents/
│   │   └── LogWaterIntent.swift
│   └── App.swift
├── HydrateWatch/
│   ├── Views/
│   │   ├── WatchHomeView.swift
│   │   └── PortionPickerView.swift
│   ├── Complication/
│   │   └── WaterProgressRing.swift
│   └── App.swift
└── docs/superpowers/
    ├── specs/2026-05-13-hydrate-app-design.md
    └── plans/2026-05-13-hydrate-app-implementation.md
```

---

### Task 1: Xcode 项目创建（手动步骤）

**注意:** 此任务需要在 macOS 上通过 Xcode 完成，创建后所有源代码文件由后续任务填充。

- [ ] **Step 1: 创建 Xcode 项目**
  - 打开 Xcode → File → New → Project → Multiplatform → App
  - Product Name: `HydrateApp`
  - Team: 个人 Apple ID
  - 勾选: `Include watchOS App`

- [ ] **Step 2: 添加 Watch App Target**
  - Xcode 会自动创建 `HydrateWatch` target
  - 确认 Watch App 的 Deployment Target 为 watchOS 11.0

- [ ] **Step 3: 创建 HydrateKit Swift Package**
  - File → New → Package → Swift Package
  - Name: `HydrateKit`
  - 保存到项目根目录 `hydrate_app/HydrateKit/`
  - 在 Xcode 中: HydrateApp target → General → Frameworks → 添加 HydrateKit
  - HydrateWatch target → General → Frameworks → 添加 HydrateKit

- [ ] **Step 4: 创建目录结构**
  在 `HydrateKit/Sources/HydrateKit/` 下创建:
  ```
  Models/
  Storage/
  ReminderEngine/
  SyncService/
  Assessment/
  ```
  在 `HydrateApp/` 下创建 `Views/`, `Intents/`
  在 `HydrateWatch/` 下创建 `Views/`, `Complication/`

- [ ] **Step 5: 配置 Capabilities**
  - HydrateApp target → Signing & Capabilities:
    - 添加 HealthKit
    - 添加 Background Modes (Background fetch, Background processing)
  - HydrateWatch target → Signing & Capabilities:
    - 添加 HealthKit (仅读取，写入由 iPhone 完成)

- [ ] **Step 6: 配置 Info.plist**
  - HydrateApp: 添加 `NSHealthShareUsageDescription` = "用于根据你的运动和体重数据调整饮水建议"
  - HydrateApp: 添加 `NSHealthUpdateUsageDescription` = "用于将你的饮水记录同步到 Apple Health"
  - 添加 `BGTaskSchedulerPermittedIdentifiers`: `["com.hydrate.reminderRefresh"]`

- [ ] **Step 7: 首次提交**

```bash
git add -A && git commit -m "chore: create Xcode project scaffolding"
```

---

### Task 2: 数据模型 — WaterRecord + Source

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Models/WaterRecord.swift`

- [ ] **Step 1: 编写 WaterRecord.swift**

```swift
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
```

- [ ] **Step 2: 编写 WaterRecord 单元测试**

```swift
// Tests/HydrateKitTests/WaterRecordTests.swift
import XCTest
@testable import HydrateKit

final class WaterRecordTests: XCTestCase {
    func test_recordInitializesWithDefaults() {
        let record = WaterRecord(amount: 480)
        XCTAssertEqual(record.amount, 480)
        XCTAssertEqual(record.source, .manual)
        XCTAssertNotNil(record.id)
    }
}
```

- [ ] **Step 3: 提交**

```bash
git add -A && git commit -m "feat: add WaterRecord model"
```

---

### Task 3: 数据模型 — DailyGoal + ReminderRule

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Models/DailyGoal.swift`
- Create: `HydrateKit/Sources/HydrateKit/Models/ReminderRule.swift`

- [ ] **Step 1: 编写 DailyGoal.swift**

```swift
import Foundation

public struct DailyGoal: Identifiable {
    public let id: UUID
    public let date: Date
    public var targetML: Double
    public var currentML: Double

    public var progress: Double {
        guard targetML > 0 else { return 0 }
        return min(currentML / targetML, 1.0)
    }

    public var isMet: Bool {
        currentML >= targetML
    }

    public init(id: UUID = UUID(), date: Date = Date(), targetML: Double = 2000, currentML: Double = 0) {
        self.id = id
        self.date = date
        self.targetML = targetML
        self.currentML = currentML
    }

    /// 根据体重计算建议饮水量 (ml) — 每公斤体重约 30-35ml
    public static func recommendedTarget(weightKG: Double) -> Double {
        weightKG * 33.0
    }
}
```

- [ ] **Step 2: 编写 ReminderRule.swift**

```swift
import Foundation

public struct ReminderRule: Equatable {
    public var startHour: Int        // 0-23，如 9
    public var startMinute: Int      // 0-59
    public var endHour: Int          // 0-23，如 21
    public var endMinute: Int
    public var baseIntervalMinutes: Int  // 默认 45
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
```

- [ ] **Step 3: 提交**

```bash
git add -A && git commit -m "feat: add DailyGoal and ReminderRule models"
```

---

### Task 4: 数据模型 — CupPreset + DrinkContainer

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Models/CupPreset.swift`

- [ ] **Step 1: 编写 CupPreset.swift**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add CupPreset and DrinkContainer models with defaults"
```

---

### Task 5: 数据模型 — WeeklyAssessment

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Models/WeeklyAssessment.swift`

- [ ] **Step 1: 编写 WeeklyAssessment.swift**

```swift
import Foundation

public enum HydrateGrade: String, Codable, CaseIterable {
    case a = "优秀"
    case b = "良好"
    case c = "需改善"
    case d = "严重不足"
}

public enum HydrateTrend: String, Codable, CaseIterable {
    case up = "↑"
    case stable = "→"
    case down = "↓"
}

public struct WeeklyAssessment: Identifiable {
    public let id: UUID
    public let weekStart: Date
    public let avgDailyML: Double
    public let goalMetDays: Int
    public let grade: HydrateGrade
    public let trend: HydrateTrend
    public let suggestion: String

    public init(
        id: UUID = UUID(),
        weekStart: Date,
        avgDailyML: Double,
        goalMetDays: Int,
        grade: HydrateGrade,
        trend: HydrateTrend,
        suggestion: String
    ) {
        self.id = id
        self.weekStart = weekStart
        self.avgDailyML = avgDailyML
        self.goalMetDays = goalMetDays
        self.grade = grade
        self.trend = trend
        self.suggestion = suggestion
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add WeeklyAssessment model"
```

---

### Task 6: Core Data — 模型定义与 CoreDataStack

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Storage/CoreDataStack.swift`

- [ ] **Step 1: 编写 CoreDataStack.swift（用代码定义 Core Data 模型）**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add CoreDataStack with code-defined model"
```

---

### Task 7: WaterRecordStore — 记录的增删查

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Storage/WaterRecordStore.swift`

- [ ] **Step 1: 编写 WaterRecordStore.swift**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add WaterRecordStore with CRUD operations"
```

---

### Task 8: HealthKitService — HealthKit 读写

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Storage/HealthKitService.swift`

- [ ] **Step 1: 编写 HealthKitService.swift**

```swift
import Foundation
import HealthKit

public final class HealthKitService: @unchecked Sendable {
    public static let shared = HealthKitService()

    private let store: HKHealthStore
    private var isAuthorized = false

    private init() {
        self.store = HKHealthStore()
    }

    // MARK: - 权限请求

    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }

        let waterType = HKQuantityType(.dietaryWater)
        let weightType = HKQuantityType(.bodyMass)
        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        let exerciseType = HKQuantityType(.appleExerciseTime)
        let sleepType = HKCategoryType(.sleepAnalysis)

        let readTypes: Set<HKSampleType> = [
            waterType, weightType, activeEnergyType, exerciseType, sleepType
        ]
        let writeTypes: Set<HKSampleType> = [waterType]

        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
        } catch {
            throw HealthKitError.authorizationDenied(error)
        }
    }

    public var isHealthKitAuthorized: Bool { isAuthorized }

    // MARK: - 写入饮水数据

    public func saveWaterIntake(ml: Double, date: Date = Date()) async throws {
        guard isAuthorized else { throw HealthKitError.unauthorized }

        let waterType = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: ml)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)

        do {
            try await store.save(sample)
        } catch {
            throw HealthKitError.saveFailed(error)
        }
    }

    // MARK: - 读取体重

    public func latestWeight() async throws -> Double? {
        guard isAuthorized else { throw HealthKitError.unauthorized }
        return try await latestQuantityValue(HKQuantityType(.bodyMass), unit: .gramUnit(with: .kilo))
    }

    // MARK: - 读取今日运动时间 (分钟)

    public func todayExerciseMinutes() async throws -> Double {
        guard isAuthorized else { throw HealthKitError.unauthorized }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return try await cumulativeQuantityValue(
            HKQuantityType(.appleExerciseTime),
            unit: .minute(),
            from: startOfDay, to: Date()
        )
    }

    // MARK: - 读取今日活动能量 (千卡)

    public func todayActiveEnergy() async throws -> Double {
        guard isAuthorized else { throw HealthKitError.unauthorized }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return try await cumulativeQuantityValue(
            HKQuantityType(.activeEnergyBurned),
            unit: .kilocalorie(),
            from: startOfDay, to: Date()
        )
    }

    // MARK: - 私有辅助

    private func latestQuantityValue(_ type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [sortDescriptor],
            limit: 1
        )
        let results = try await descriptor.result(for: store)
        return results.first?.quantity.doubleValue(for: unit)
    }

    private func cumulativeQuantityValue(_ type: HKQuantityType, unit: HKUnit, from start: Date, to end: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum
        )
        let result = try await descriptor.result(for: store)?
            .sumQuantity()?
            .doubleValue(for: unit)
        return result ?? 0
    }
}

public enum HealthKitError: Error {
    case unavailable
    case unauthorized
    case authorizationDenied(Error)
    case saveFailed(Error)
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add HealthKitService for water/weight/activity"
```

---

### Task 9: AdaptiveCalculator — 智能提醒间隔计算

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/ReminderEngine/AdaptiveCalculator.swift`

- [ ] **Step 1: 编写测试 AdaptiveCalculatorTests.swift**

```swift
// Tests/HydrateKitTests/AdaptiveCalculatorTests.swift
import XCTest
@testable import HydrateKit

final class AdaptiveCalculatorTests: XCTestCase {
    let calculator = AdaptiveCalculator()
    let rule = ReminderRule.default  // 9-21, 45min base

    func test_normalProgress_returnsBaseInterval() {
        // 下午 3 点，已完成 60% 目标 → 正常间隔
        let interval = calculator.nextInterval(
            currentML: 1200, targetML: 2000,
            rule: rule, currentTime: makeDate(15, 0),
            lastExerciseMinutes: 5
        )
        XCTAssertEqual(interval, 2700) // 45 min in seconds
    }

    func test_behindSchedule_shortensInterval() {
        // 下午 4 点 (时间过半)，只完成 30% → 缩短
        let interval = calculator.nextInterval(
            currentML: 600, targetML: 2000,
            rule: rule, currentTime: makeDate(16, 0),
            lastExerciseMinutes: 0
        )
        XCTAssertEqual(interval, 1800) // 30 min in seconds
    }

    func test_recentExercise_triggersImmediateReminder() {
        // 刚运动完 35 分钟 → 立即提醒
        let interval = calculator.nextInterval(
            currentML: 800, targetML: 2000,
            rule: rule, currentTime: makeDate(14, 0),
            lastExerciseMinutes: 35
        )
        XCTAssertEqual(interval, 0) // immediate
    }

    func test_outsideReminderWindow_returnsLargeInterval() {
        // 晚上 10 点，不在提醒窗口 → 跳过
        let interval = calculator.nextInterval(
            currentML: 500, targetML: 2000,
            rule: rule, currentTime: makeDate(22, 0),
            lastExerciseMinutes: 0
        )
        XCTAssertEqual(interval, 86400) // skip until next day
    }

    // MARK: - Helper

    private func makeDate(_ hour: Int, _ minute: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            from: DateComponents(
                year: 2026, month: 5, day: 13,
                hour: hour, minute: minute
            )
        )!
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
xcodebuild test -scheme HydrateKit -destination 'platform=iOS Simulator,name=iPhone 16'
# Expected: FAIL — AdaptiveCalculator not defined
```

- [ ] **Step 3: 编写 AdaptiveCalculator.swift 实现**

```swift
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
            return 86400 // 一天后
        }

        // 2. 检查星期
        let weekday = calendar.component(.weekday, from: currentTime)
        if !rule.enabledWeekdays.contains(weekday) {
            return 86400
        }

        // 3. 运动后立即提醒（运动 ≥ 30 分钟）
        if lastExerciseMinutes >= 30 {
            return 0
        }

        // 4. 进度落后 → 缩短间隔
        let progress = currentML / targetML
        let dayProgress = Double(currentMinutes - startMinutes) / Double(endMinutes - startMinutes)

        if dayProgress > 0.5 && progress < 0.5 {
            // 时间过半，饮水不足一半 → 缩短至 30 分钟
            return 30 * 60
        }

        // 5. 正常间隔
        return TimeInterval(rule.baseIntervalMinutes * 60)
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

```bash
xcodebuild test -scheme HydrateKit -destination 'platform=iOS Simulator,name=iPhone 16'
# Expected: PASS (4/4 tests)
```

- [ ] **Step 5: 提交**

```bash
git add -A && git commit -m "feat: add AdaptiveCalculator with smart interval logic"
```

---

### Task 10: ReminderScheduler — 后台任务调度与通知投递

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/ReminderEngine/ReminderScheduler.swift`

- [ ] **Step 1: 编写 ReminderScheduler.swift**

```swift
import Foundation
import BackgroundTasks
import UserNotifications

public final class ReminderScheduler {
    public static let shared = ReminderScheduler()

    private let calculator = AdaptiveCalculator()
    private let store = WaterRecordStore()
    private let healthKit = HealthKitService.shared
    private let taskID = "com.hydrate.reminderRefresh"

    private init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - 注册后台任务

    public func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            Task {
                await self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        }
    }

    public func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 分钟后
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BGTask schedule failed: \(error)")
            scheduleFallbackNotification()
        }
    }

    // MARK: - 后台刷新处理

    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        // 重新调度下一轮
        scheduleBackgroundRefresh()

        do {
            let exerciseMin = try await healthKit.todayExerciseMinutes()
            let currentML = store.todayTotal()
            let targetML: Double = 2000

            // 尝试从 HealthKit 读体重来调整目标
            if let weight = try? await healthKit.latestWeight(), weight > 0 {
                /// 目标会在设置中持久化，这里仅做动态微调
            }

            let rule = loadReminderRule()
            let interval = calculator.nextInterval(
                currentML: currentML,
                targetML: targetML,
                rule: rule,
                currentTime: Date(),
                lastExerciseMinutes: exerciseMin
            )

            if interval == 0 {
                await deliverNotification(title: "运动后补水", body: "你刚运动完，建议喝一杯水补充水分")
            } else if interval < 3600 {
                await scheduleImmediateNotification(in: interval)
            }

            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - 降级：固定间隔预排通知

    private func scheduleFallbackNotification() {
        let rule = loadReminderRule()
        let interval = TimeInterval(rule.baseIntervalMinutes * 60)

        Task {
            await scheduleImmediateNotification(in: interval)
        }
    }

    private func scheduleImmediateNotification(in seconds: TimeInterval) async {
        guard seconds > 0, seconds < 86400 else { return }

        let content = UNMutableNotificationContent()
        content.title = "该喝水了"
        content.body = "点击记录你今天喝的第N杯水"
        content.sound = .default
        content.categoryIdentifier = "WATER_REMINDER"

        // 通知操作：记录保温杯 480ml
        let recordAction = UNNotificationAction(
            identifier: "RECORD_480",
            title: "保温杯 (480ml)",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "WATER_REMINDER",
            actions: [recordAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Notification delivery failed: \(error)")
        }
    }

    private func deliverNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 立即
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 规则持久化

    private func loadReminderRule() -> ReminderRule {
        let context = CoreDataStack.shared.container.viewContext
        let request = ReminderRuleEntity.fetchRequest() as! NSFetchRequest<ReminderRuleEntity>
        request.fetchLimit = 1

        if let entity = try? context.fetch(request).first {
            return ReminderRule(
                startHour: entity.startHour,
                startMinute: entity.startMinute,
                endHour: entity.endHour,
                endMinute: entity.endMinute,
                baseIntervalMinutes: entity.baseIntervalMinutes,
                enabledWeekdays: entity.enabledWeekdays
            )
        }
        return .default
    }

    public func saveReminderRule(_ rule: ReminderRule) {
        let context = CoreDataStack.shared.container.viewContext
        let request = ReminderRuleEntity.fetchRequest() as! NSFetchRequest<ReminderRuleEntity>
        request.fetchLimit = 1

        let entity: ReminderRuleEntity
        if let existing = try? context.fetch(request).first {
            entity = existing
        } else {
            entity = ReminderRuleEntity(context: context)
        }
        entity.startHour = rule.startHour
        entity.startMinute = rule.startMinute
        entity.endHour = rule.endHour
        entity.endMinute = rule.endMinute
        entity.baseIntervalMinutes = rule.baseIntervalMinutes
        entity.enabledWeekdays = rule.enabledWeekdays
        CoreDataStack.shared.saveContext()
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add ReminderScheduler with BGTask + UNNotification"
```

---

### Task 11: WCManager — WatchConnectivity 双向同步

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/SyncService/WCManager.swift`

- [ ] **Step 1: 编写 WCManager.swift**

```swift
import Foundation
import WatchConnectivity

public final class WCManager: NSObject, @unchecked Sendable {
    public static let shared = WCManager()

    private let store = WaterRecordStore()
    private var pendingRecords: [WaterRecord] = []

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - 发送

    public func sendRecord(_ record: WaterRecord) {
        guard WCSession.default.isReachable || WCSession.default.isPaired else {
            pendingRecords.append(record)
            return
        }

        let payload: [String: Any] = [
            "id": record.id.uuidString,
            "amount": record.amount,
            "timestamp": record.timestamp.timeIntervalSince1970,
            "source": record.source.rawValue,
        ]

        WCSession.default.transferUserInfo(payload)
    }

    /// 重推所有未发送记录（连接恢复时调用）
    public func flushPending() {
        let records = pendingRecords
        pendingRecords.removeAll()
        for record in records {
            sendRecord(record)
        }
    }

    // MARK: - 去重

    public func isAlreadySynced(_ recordID: UUID) -> Bool {
        let context = CoreDataStack.shared.container.viewContext
        let request = SyncLogEntity.fetchRequest() as! NSFetchRequest<SyncLogEntity>
        request.predicate = NSPredicate(format: "recordID == %@", recordID as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request).first) != nil
    }

    public func markAsSynced(_ recordID: UUID) {
        let context = CoreDataStack.shared.container.viewContext
        let entity = SyncLogEntity(context: context)
        entity.recordID = recordID
        entity.syncedAt = Date()
        CoreDataStack.shared.saveContext()
    }
}

// MARK: - WCSessionDelegate

extension WCManager: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            flushPending()
        }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let idString = userInfo["id"] as? String,
              let id = UUID(uuidString: idString),
              let amount = userInfo["amount"] as? Double,
              let timestampInterval = userInfo["timestamp"] as? TimeInterval,
              let sourceRaw = userInfo["source"] as? String else {
            return
        }

        guard !isAlreadySynced(id) else { return }

        let record = WaterRecord(
            id: id,
            amount: amount,
            timestamp: Date(timeIntervalSince1970: timestampInterval),
            source: RecordSource(rawValue: sourceRaw) ?? .watch
        )

        store.addRecord(record)
        markAsSynced(id)

        // iPhone 侧写入 HealthKit
        #if os(iOS)
        Task {
            try? await HealthKitService.shared.saveWaterIntake(ml: amount, date: record.timestamp)
        }
        #endif
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            flushPending()
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add WCManager for iPhone-Watch sync"
```

---

### Task 12: AssessmentEngine — 每周健康评估

**Files:**
- Create: `HydrateKit/Sources/HydrateKit/Assessment/AssessmentEngine.swift`

- [ ] **Step 1: 编写测试 AssessmentEngineTests.swift**

```swift
// Tests/HydrateKitTests/AssessmentEngineTests.swift
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

    func test_emptyWeek_returnsSuggestion() {
        let assessment = engine.assess(
            weekStart: Date(),
            dailyAmounts: [],
            targetML: 2000,
            prevAvg: 1800
        )
        XCTAssertEqual(assessment.grade, .d)
    }
}
```

- [ ] **Step 2: 编写 AssessmentEngine.swift 实现**

```swift
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
```

- [ ] **Step 3: 运行测试**

```bash
xcodebuild test -scheme HydrateKit -destination 'platform=iOS Simulator,name=iPhone 16'
# Expected: PASS
```

- [ ] **Step 4: 提交**

```bash
git add -A && git commit -m "feat: add AssessmentEngine with weekly health evaluation"
```

---

### Task 13: Package.swift — 配置 HydrateKit

**Files:**
- Modify: `HydrateKit/Package.swift`

- [ ] **Step 1: 更新 Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HydrateKit",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "HydrateKit",
            targets: ["HydrateKit"]
        ),
    ],
    targets: [
        .target(
            name: "HydrateKit",
            path: "Sources/HydrateKit"
        ),
        .testTarget(
            name: "HydrateKitTests",
            dependencies: ["HydrateKit"],
            path: "Tests/HydrateKitTests"
        ),
    ]
)
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "chore: configure Package.swift for iOS 18 + watchOS 11"
```

---

### Task 14: iPhone App — HomeView 主界面

**Files:**
- Create: `HydrateApp/Views/HomeView.swift`

- [ ] **Step 1: 编写 HomeView.swift**

```swift
import SwiftUI
import HydrateKit

struct HomeView: View {
    @State private var todayML: Double = 0
    @State private var targetML: Double = 2000
    @State private var selectedContainer: DrinkContainer?
    @State private var showPortionPicker = false
    @State private var recentRecords: [WaterRecord] = []

    private let store = WaterRecordStore()
    private let containers = DrinkContainer.defaults

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 进度环
                    progressRing

                    // 今日数字
                    VStack(spacing: 4) {
                        Text("\(Int(todayML))")
                            .font(.system(size: 48, weight: .bold))
                        Text("/ \(Int(targetML)) ml")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // 三大容器按钮
                    HStack(spacing: 16) {
                        ForEach(containers) { container in
                            containerButton(container)
                        }
                    }
                    .padding(.horizontal)

                    // 最近记录
                    if !recentRecords.isEmpty {
                        recentRecordsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Hydrate")
            .sheet(isPresented: $showPortionPicker) {
                if let container = selectedContainer {
                    PortionPickerSheet(container: container) { portion in
                        recordDrink(container: container, amount: portion.amount)
                        showPortionPicker = false
                    }
                }
            }
            .onAppear { refresh() }
        }
    }

    // MARK: - 进度环

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 20)
            Circle()
                .trim(from: 0, to: min(todayML / targetML, 1.0))
                .stroke(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: todayML)
        }
        .frame(width: 200, height: 200)
        .padding(.top)
    }

    // MARK: - 容器按钮

    private func containerButton(_ container: DrinkContainer) -> some View {
        Button {
            handleTap(container)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: container.icon)
                    .font(.system(size: 32))
                Text(container.name)
                    .font(.caption)
                if case .oneTap = container.mode {
                    Text("\(Int(container.totalAmount ?? 0))ml")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func handleTap(_ container: DrinkContainer) {
        switch container.mode {
        case .oneTap:
            recordDrink(container: container, amount: container.totalAmount ?? 0)
        case .portionSelect:
            selectedContainer = container
            showPortionPicker = true
        }
    }

    // MARK: - 记录操作

    private func recordDrink(container: DrinkContainer, amount: Double) {
        let record = WaterRecord(amount: amount, source: .manual)
        store.addRecord(record)
        HealthKitService.shared.saveWater(ml: amount)
        WCManager.shared.sendRecord(record)
        refresh()
    }

    // MARK: - 最近记录

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日记录")
                .font(.headline)
                .padding(.horizontal)

            ForEach(recentRecords.prefix(10)) { record in
                HStack {
                    Image(systemName: record.source.iconName)
                    Text(record.timestamp, style: .time)
                    Spacer()
                    Text("\(Int(record.amount))ml")
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
            }
        }
    }

    private func refresh() {
        todayML = store.todayTotal()
        recentRecords = store.recordsForDate(Date())
    }
}

extension RecordSource {
    var iconName: String {
        switch self {
        case .manual: return "hand.tap.fill"
        case .siri: return "waveform"
        case .watch: return "applewatch"
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add iPhone HomeView with progress ring and container buttons"
```

---

### Task 15: iPhone App — PortionPickerSheet（分量选择器）

**Files:**
- Create: `HydrateApp/Views/PortionPickerSheet.swift`

- [ ] **Step 1: 编写 PortionPickerSheet.swift**

```swift
import SwiftUI
import HydrateKit

struct PortionPickerSheet: View {
    let container: DrinkContainer
    let onSelect: (Portion) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: container.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .padding(.top, 24)

                Text("\(container.name)")
                    .font(.title2)
                    .fontWeight(.bold)

                if let total = container.totalAmount {
                    Text("总容量 \(Int(total))ml")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if case .portionSelect(let portions) = container.mode {
                    VStack(spacing: 12) {
                        ForEach(portions) { portion in
                            Button {
                                onSelect(portion)
                            } label: {
                                HStack {
                                    Text(portion.name)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(Int(portion.amount))ml")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button("取消") {
                    dismiss()
                }
                .padding(.bottom)
            }
            .presentationDetents([.medium])
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add PortionPickerSheet for portion selection"
```

---

### Task 16: iPhone App — HistoryView 历史统计 + 评估

**Files:**
- Create: `HydrateApp/Views/HistoryView.swift`

- [ ] **Step 1: 编写 HistoryView.swift**

```swift
import SwiftUI
import HydrateKit
import Charts

struct HistoryView: View {
    private let store = WaterRecordStore()
    private let engine = AssessmentEngine()

    @State private var weeklyData: [(Date, Double)] = []
    @State private var monthlyData: [(week: String, avg: Double)] = []
    @State private var assessment: WeeklyAssessment?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 周评估卡片
                    if let assessment = assessment {
                        assessmentCard(assessment)
                    }

                    // 本周柱状图
                    weekChart

                    // 本月趋势
                    monthChart
                }
                .padding()
            }
            .navigationTitle("统计")
            .onAppear { loadData() }
        }
    }

    // MARK: - 评估卡片

    private func assessmentCard(_ a: WeeklyAssessment) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("本周评估")
                    .font(.headline)
                Spacer()
                Text(a.grade.rawValue)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(gradeColor(a.grade))
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Label("日均 \(Int(a.avgDailyML))ml", systemImage: "drop.fill")
                    Label("达标 \(a.goalMetDays)/7 天", systemImage: "checkmark.circle")
                }
                Spacer()
                Text(a.trend.rawValue)
                    .font(.system(size: 48))
            }

            Text(a.suggestion)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 本周柱状图

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本周饮水")
                .font(.headline)

            Chart {
                ForEach(weeklyData, id: \.0) { day, ml in
                    BarMark(
                        x: .value("日期", day, unit: .day),
                        y: .value("ml", ml)
                    )
                    .foregroundStyle(ml >= 2000 ? Color.blue : Color.blue.opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 180)
        }
    }

    // MARK: - 本月趋势

    private var monthChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本月趋势")
                .font(.headline)

            Chart {
                ForEach(monthlyData, id: \.week) { item in
                    LineMark(
                        x: .value("周", item.week),
                        y: .value("日均", item.avg)
                    )
                    .foregroundStyle(.cyan)
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: - 数据加载

    private func loadData() {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        // 本周每天
        weeklyData = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let records = store.recordsForDate(date)
            let total = records.reduce(0) { $0 + $1.amount }
            return (date, total)
        }

        // 本月每周
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        monthlyData = (0..<5).compactMap { weekIdx in
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: weekIdx, to: monthStart) else { return nil }
            let end = calendar.date(byAdding: .day, value: 7, to: weekDate)!
            let records = store.recordsBetween(start: weekDate, end: end)
            let avg = records.isEmpty ? 0 : records.reduce(0) { $0 + $1.amount } / 7.0
            return ("W\(weekIdx + 1)", avg)
        }

        // 评估
        let dailyAmounts = weeklyData.map { $0.1 }
        let prevWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        let prevWeekEnd = weekStart
        let prevRecords = store.recordsBetween(start: prevWeekStart, end: prevWeekEnd)
        let prevAvg = prevRecords.isEmpty ? 0 : prevRecords.reduce(0) { $0 + $1.amount } / 7.0

        assessment = engine.assess(
            weekStart: weekStart,
            dailyAmounts: dailyAmounts,
            targetML: 2000,
            prevAvg: prevAvg
        )
    }

    private func gradeColor(_ grade: HydrateGrade) -> Color {
        switch grade {
        case .a: return .green
        case .b: return .blue
        case .c: return .orange
        case .d: return .red
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add HistoryView with weekly/monthly stats and assessment"
```

---

### Task 17: iPhone App — SettingsView + App 入口

**Files:**
- Create: `HydrateApp/Views/SettingsView.swift`
- Create: `HydrateApp/App.swift`

- [ ] **Step 1: 编写 SettingsView.swift**

```swift
import SwiftUI
import HydrateKit

struct SettingsView: View {
    @AppStorage("targetML") private var targetML: Double = 2000
    @AppStorage("startHour") private var startHour: Int = 9
    @AppStorage("startMinute") private var startMinute: Int = 0
    @AppStorage("endHour") private var endHour: Int = 21
    @AppStorage("endMinute") private var endMinute: Int = 0
    @AppStorage("baseIntervalMinutes") private var baseIntervalMinutes: Int = 45
    @AppStorage("weeklyReportEnabled") private var weeklyReportEnabled: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                // 每日目标
                Section("每日饮水目标") {
                    HStack {
                        Text("\(Int(targetML)) ml")
                        Spacer()
                        Stepper("", value: $targetML, in: 1000...4000, step: 100)
                    }
                }

                // 提醒时段
                Section("提醒时段") {
                    DatePicker("开始时间", selection: Binding(
                        get: { makeDate(hour: startHour, minute: startMinute) },
                        set: { date in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                            startHour = comps.hour ?? 9
                            startMinute = comps.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)

                    DatePicker("结束时间", selection: Binding(
                        get: { makeDate(hour: endHour, minute: endMinute) },
                        set: { date in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                            endHour = comps.hour ?? 21
                            endMinute = comps.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)

                    HStack {
                        Text("基础间隔")
                        Spacer()
                        Stepper("\(baseIntervalMinutes) 分钟", value: $baseIntervalMinutes, in: 15...120, step: 5)
                    }
                }

                // 每周报告
                Section("健康评估") {
                    Toggle("每周一推送评估报告", isOn: $weeklyReportEnabled)
                }

                // 关于
                Section("HealthKit") {
                    Button("请求 HealthKit 权限") {
                        Task {
                            try? await HealthKitService.shared.requestAuthorization()
                        }
                    }
                }

                Section("保存") {
                    Button("应用提醒设置") {
                        let rule = ReminderRule(
                            startHour: startHour,
                            startMinute: startMinute,
                            endHour: endHour,
                            endMinute: endMinute,
                            baseIntervalMinutes: baseIntervalMinutes,
                            enabledWeekdays: Set(1...7)
                        )
                        ReminderScheduler.shared.saveReminderRule(rule)
                        ReminderScheduler.shared.scheduleBackgroundRefresh()
                    }
                }
            }
            .navigationTitle("设置")
        }
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
}
```

- [ ] **Step 2: 编写 App.swift**

```swift
import SwiftUI
import HydrateKit
import BackgroundTasks

@main
struct HydrateApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        ReminderScheduler.shared.registerBackgroundTask()
        ReminderScheduler.shared.scheduleBackgroundRefresh()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        ReminderScheduler.shared.scheduleBackgroundRefresh()
                    }
                }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("今日", systemImage: "drop.fill")
                }
            HistoryView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add SettingsView and App entry point with tab navigation"
```

---

### Task 18: Watch App — WatchHomeView + PortionPickerView

**Files:**
- Create: `HydrateWatch/Views/WatchHomeView.swift`
- Create: `HydrateWatch/Views/PortionPickerView.swift`

- [ ] **Step 1: 编写 WatchHomeView.swift**

```swift
import SwiftUI
import HydrateKit

struct WatchHomeView: View {
    @State private var todayML: Double = 0
    @State private var targetML: Double = 2000

    private let store = WaterRecordStore()
    private let containers = DrinkContainer.defaults

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 进度环
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.15), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: min(todayML / targetML, 1.0))
                            .stroke(Color.cyan, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(Int(todayML))")
                                .font(.system(size: 24, weight: .bold))
                            Text("ml")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)

                    // 容器按钮
                    ForEach(containers) { container in
                        NavigationLink {
                            if case .portionSelect(let portions) = container.mode {
                                PortionPickerView(container: container, portions: portions) { amount in
                                    recordDrink(container: container, amount: amount)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: container.icon)
                                Text(container.name)
                                Spacer()
                                if case .oneTap = container.mode {
                                    Text("\(Int(container.totalAmount ?? 0))ml")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onTapGesture {
                            if case .oneTap = container.mode {
                                recordDrink(container: container, amount: container.totalAmount ?? 0)
                            }
                        }
                    }
                }
                .padding()
            }
            .onAppear { refresh() }
        }
    }

    private func recordDrink(container: DrinkContainer, amount: Double) {
        let record = WaterRecord(amount: amount, source: .watch)
        store.addRecord(record)
        WCManager.shared.sendRecord(record)
        refresh()

        // 震动反馈
        WKInterfaceDevice.current().play(.click)
    }

    private func refresh() {
        todayML = store.todayTotal()
    }
}
```

- [ ] **Step 2: 编写 PortionPickerView.swift**

```swift
import SwiftUI
import HydrateKit

struct PortionPickerView: View {
    let container: DrinkContainer
    let portions: [Portion]
    let onSelect: (Double) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(container.name) {
                ForEach(portions) { portion in
                    Button {
                        onSelect(portion.amount)
                        dismiss()
                    } label: {
                        HStack {
                            Text(portion.name)
                            Spacer()
                            Text("\(Int(portion.amount))ml")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: 提交**

```bash
git add -A && git commit -m "feat: add WatchHomeView and PortionPickerView"
```

---

### Task 19: Watch App — Complication + App 入口

**Files:**
- Create: `HydrateWatch/Complication/WaterProgressRing.swift`
- Create: `HydrateWatch/App.swift`

- [ ] **Step 1: 编写 WaterProgressRing.swift**

```swift
import SwiftUI
import WidgetKit
import HydrateKit

struct WaterProgressEntry: TimelineEntry {
    let date: Date
    let currentML: Double
    let targetML: Double
}

struct WaterProgressProvider: TimelineProvider {
    private let store = WaterRecordStore()

    func placeholder(in context: Context) -> WaterProgressEntry {
        WaterProgressEntry(date: Date(), currentML: 1200, targetML: 2000)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterProgressEntry) -> Void) {
        let entry = WaterProgressEntry(
            date: Date(),
            currentML: store.todayTotal(),
            targetML: 2000
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterProgressEntry>) -> Void) {
        let entry = WaterProgressEntry(
            date: Date(),
            currentML: store.todayTotal(),
            targetML: 2000
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WaterProgressRing: Widget {
    let kind = "WaterProgressRing"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProgressProvider()) { entry in
            WaterProgressEntryView(entry: entry)
                .containerBackground(.regularMaterial, for: .widget)
        }
        .configurationDisplayName("饮水进度")
        .description("显示今日饮水完成进度")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

struct WaterProgressEntryView: View {
    var entry: WaterProgressEntry

    var body: some View {
        let progress = entry.targetML > 0 ? min(entry.currentML / entry.targetML, 1.0) : 0

        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .medium))
        }
    }
}
```

- [ ] **Step 2: 编写 Watch App.swift**

```swift
import SwiftUI
import HydrateKit

@main
struct HydrateWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
```

- [ ] **Step 3: 提交**

```bash
git add -A && git commit -m "feat: add Watch complication and app entry point"
```

---

### Task 20: Siri Intents — LogWaterIntent

**Files:**
- Create: `HydrateApp/Intents/LogWaterIntent.swift`

- [ ] **Step 1: 编写 LogWaterIntent.swift**

```swift
import AppIntents
import HydrateKit

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "记录喝水"
    static let description = IntentDescription("快速记录一杯喝水")

    @Parameter(title: "毫升")
    var amount: Double

    init() {
        self.amount = 480
    }

    init(amount: Double) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        let record = WaterRecord(amount: amount, source: .siri)
        WaterRecordStore().addRecord(record)

        try? await HealthKitService.shared.saveWaterIntake(ml: amount)
        WCManager.shared.sendRecord(record)

        return .result(dialog: "已记录 \(Int(amount))ml 喝水")
    }
}

// Shortcut 注册
struct HydrateShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "记录喝了杯水",
                "记录喝水 \(\.$amount)",
                "我今天喝了水",
            ],
            shortTitle: "记录喝水"
        )
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add -A && git commit -m "feat: add Siri Intent for water logging"
```

---

### Task 21: HealthKitService 补充 — 便捷方法

**Files:**
- Modify: `HydrateKit/Sources/HydrateKit/Storage/HealthKitService.swift`

在 `saveWaterIntake` 方法后追加：

```swift
// 便捷方法 — 同步版本（用于非 async 上下文）
public func saveWater(ml: Double, date: Date = Date()) {
    Task {
        try? await saveWaterIntake(ml: ml, date: date)
    }
}
```

- [ ] **Step 1: 编辑并提交**

```bash
git add -A && git commit -m "feat: add sync convenience method to HealthKitService"
```

---

### Task 22: 最终集成 — 编译验证

**注意:** 此任务在 macOS + Xcode 上执行。

- [ ] **Step 1: 确保所有文件已加入 Xcode targets**

在 Xcode 中检查：
- HydrateApp target 的 Compile Sources 包含所有 iPhone Views + Intents
- HydrateWatch target 的 Compile Sources 包含所有 Watch Views + Complication
- HydrateKit 的 Sources 自动包含

- [ ] **Step 2: 编译 iPhone target**

```bash
xcodebuild -project HydrateApp.xcodeproj \
  -scheme HydrateApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
# Expected: BUILD SUCCEEDED
```

- [ ] **Step 3: 编译 Watch target**

```bash
xcodebuild -project HydrateApp.xcodeproj \
  -scheme HydrateWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
  build
# Expected: BUILD SUCCEEDED
```

- [ ] **Step 4: 运行 HydrateKit 单元测试**

```bash
xcodebuild test -project HydrateApp.xcodeproj \
  -scheme HydrateKit \
  -destination 'platform=iOS Simulator,name=iPhone 16'
# Expected: ALL TESTS PASSED
```

- [ ] **Step 5: 最终提交**

```bash
git add -A && git commit -m "chore: final integration verification"
```

---

## 自审清单

1. **Spec coverage:** 每个 spec 需求都有对应任务 — 快捷记录(T14-15, T18)、智能提醒(T9-10)、HealthKit(T8)、同步(T11)、健康评估(T12, T16)、Siri(T20)、表盘组件(T19)、错误处理(各 task 已内嵌)
2. **Placeholder scan:** 无 TBD/TODO，所有代码完整展示
3. **Type consistency:** 所有模型在 Task 2-5 定义，WaterRecordStore 的 `todayTotal()` → Double, `recordsForDate()` → [WaterRecord]；AdaptiveCalculator 的 `nextInterval()` → TimeInterval，所有调用处签名一致

