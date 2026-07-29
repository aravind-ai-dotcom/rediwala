import FirebaseDatabase
import Foundation

enum FirebaseRTDBHelpers {
    static func dictionary(from snapshot: DataSnapshot) -> [String: [String: Any]] {
        guard snapshot.exists(), let raw = snapshot.value as? [String: Any] else { return [:] }
        var result: [String: [String: Any]] = [:]
        for (key, value) in raw {
            if let dict = value as? [String: Any] {
                result[key] = dict
            }
        }
        return result
    }

    static func isoString(_ date: Date = Date()) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    static func date(from value: Any?) -> Date? {
        if let string = value as? String {
            return ISO8601DateFormatter().date(from: string)
        }
        return nil
    }
}
