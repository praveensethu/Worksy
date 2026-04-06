import CoreData

class AuditService {
    static let shared = AuditService()

    private init() {}

    // MARK: - Log without saving (default)

    @discardableResult
    func logCreate(entityType: String, entityId: UUID, details: [String: Any], context: NSManagedObjectContext) -> AuditLog {
        createLog(entityType: entityType, entityId: entityId, action: "created", details: details, context: context)
    }

    @discardableResult
    func logUpdate(entityType: String, entityId: UUID, field: String, oldValue: String?, newValue: String?, context: NSManagedObjectContext) -> AuditLog {
        let details: [String: Any] = [
            "field": field,
            "oldValue": oldValue ?? "nil",
            "newValue": newValue ?? "nil"
        ]
        return createLog(entityType: entityType, entityId: entityId, action: "updated", details: details, context: context)
    }

    @discardableResult
    func logMove(entityType: String, entityId: UUID, fromColumn: String, toColumn: String, context: NSManagedObjectContext) -> AuditLog {
        let details: [String: Any] = [
            "fromColumn": fromColumn,
            "toColumn": toColumn
        ]
        return createLog(entityType: entityType, entityId: entityId, action: "moved", details: details, context: context)
    }

    @discardableResult
    func logDelete(entityType: String, entityId: UUID, details: [String: Any], context: NSManagedObjectContext) -> AuditLog {
        createLog(entityType: entityType, entityId: entityId, action: "deleted", details: details, context: context)
    }

    // MARK: - Log and save variants

    @discardableResult
    func logCreateAndSave(entityType: String, entityId: UUID, details: [String: Any], context: NSManagedObjectContext) -> AuditLog {
        let log = logCreate(entityType: entityType, entityId: entityId, details: details, context: context)
        saveContext(context)
        return log
    }

    @discardableResult
    func logUpdateAndSave(entityType: String, entityId: UUID, field: String, oldValue: String?, newValue: String?, context: NSManagedObjectContext) -> AuditLog {
        let log = logUpdate(entityType: entityType, entityId: entityId, field: field, oldValue: oldValue, newValue: newValue, context: context)
        saveContext(context)
        return log
    }

    @discardableResult
    func logMoveAndSave(entityType: String, entityId: UUID, fromColumn: String, toColumn: String, context: NSManagedObjectContext) -> AuditLog {
        let log = logMove(entityType: entityType, entityId: entityId, fromColumn: fromColumn, toColumn: toColumn, context: context)
        saveContext(context)
        return log
    }

    @discardableResult
    func logDeleteAndSave(entityType: String, entityId: UUID, details: [String: Any], context: NSManagedObjectContext) -> AuditLog {
        let log = logDelete(entityType: entityType, entityId: entityId, details: details, context: context)
        saveContext(context)
        return log
    }

    // MARK: - Query

    func history(for entityId: UUID, context: NSManagedObjectContext) -> [AuditLog] {
        let request = NSFetchRequest<AuditLog>(entityName: "AuditLog")
        request.predicate = NSPredicate(format: "entityId == %@", entityId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("AuditService: Failed to fetch history for \(entityId): \(error)")
            return []
        }
    }

    // MARK: - Private helpers

    private func createLog(entityType: String, entityId: UUID, action: String, details: [String: Any], context: NSManagedObjectContext) -> AuditLog {
        let jsonString = serializeDetails(details)
        return AuditLog(context: context, entityType: entityType, entityId: entityId, action: action, details: jsonString)
    }

    private func serializeDetails(_ details: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(details) else {
            return "{}"
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: details, options: [.sortedKeys])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("AuditService: Failed to serialize details: \(error)")
            return "{}"
        }
    }

    private func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("AuditService: Failed to save context: \(error)")
        }
    }
}
