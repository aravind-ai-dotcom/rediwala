import FirebaseCore
import FirebaseDatabase
import Foundation

/// Chennai pilot RTDB lives in asia-southeast1; the plist omits `DATABASE_URL`.
enum FirebaseDatabaseConfig {
    static let databaseURL = "https://rediwala-development-default-rtdb.asia-southeast1.firebasedatabase.app"

    static func configureIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    static var database: Database {
        configureIfNeeded()
        return Database.database(url: databaseURL)
    }

    static var root: DatabaseReference {
        database.reference()
    }
}
