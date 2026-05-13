import Foundation
import CoreData
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
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BGTask schedule failed: \(error)")
            scheduleFallbackNotification()
        }
    }

    // MARK: - 后台刷新处理

    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        scheduleBackgroundRefresh()

        let exerciseMin = (try? await healthKit.todayExerciseMinutes()) ?? 0
        let currentML = store.todayTotal()
        let storedTarget = UserDefaults.standard.double(forKey: "targetML")
        let targetML = storedTarget > 0 ? storedTarget : 2000
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
        content.body = "点击记录你今天喝的水"
        content.sound = .default
        content.categoryIdentifier = "WATER_REMINDER"

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
            trigger: nil
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
