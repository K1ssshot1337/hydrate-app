import Foundation
import CoreData
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
