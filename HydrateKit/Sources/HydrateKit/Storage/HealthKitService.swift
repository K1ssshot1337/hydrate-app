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

    /// 便捷方法 — 同步版本（用于非 async 上下文）
    public func saveWater(ml: Double, date: Date = Date()) {
        Task {
            try? await saveWaterIntake(ml: ml, date: date)
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
        let sortDescriptor = SortDescriptor<HKQuantitySample>(\.endDate, order: .reverse)
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
