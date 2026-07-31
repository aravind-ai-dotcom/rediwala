import FirebaseCore
import FirebaseDatabase
import Foundation

/// RTDB for `rediwala-development` lives at the default `.firebaseio.com` host.
/// Setting `FirebaseOptions.databaseURL` before `configure` prevents the SDK from
/// opening a wrong-region default socket (and killing the connection).
///
/// Methods are `nonisolated` so AppDelegate / early bootstrap work under
/// SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor.
enum FirebaseDatabaseConfig: Sendable {
    nonisolated static let databaseURL = "https://rediwala-development-default-rtdb.firebaseio.com"

    nonisolated static func configureIfNeeded() {
        if FirebaseApp.app() == nil {
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: path) {
                options.databaseURL = databaseURL
                FirebaseApp.configure(options: options)
            } else {
                FirebaseApp.configure()
            }
        }
        // Always talk to the explicit regional URL — never rely on an unset plist key.
        Database.database(url: databaseURL).goOnline()
    }

    nonisolated static var database: Database {
        configureIfNeeded()
        let db = Database.database(url: databaseURL)
        db.goOnline()
        return db
    }

    nonisolated static var root: DatabaseReference {
        database.reference()
    }

    /// One-shot reads fail with "client offline" when the WebSocket is not up yet
    /// (common right after Auth sign-in). Retry with a short connection wait.
    nonisolated static func getData(
        at reference: DatabaseReference,
        attempts: Int = 6
    ) async throws -> DataSnapshot {
        _ = database
        var lastError: Error?
        for attempt in 0..<attempts {
            do {
                if attempt > 0 {
                    try await waitForConnection(timeoutSeconds: 2.5)
                }
                return try await reference.getData()
            } catch {
                lastError = error
                guard isOfflineError(error), attempt < attempts - 1 else { throw error }
                let delayMs = UInt64((150 * (attempt + 1)) * 1_000_000)
                try? await Task.sleep(nanoseconds: delayMs)
            }
        }
        throw lastError ?? NSError(
            domain: "com.firebase.core",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unable to read from Realtime Database."]
        )
    }

    nonisolated static func isOfflineError(_ error: Error) -> Bool {
        let ns = error as NSError
        let message = ns.localizedDescription.lowercased()
        if message.contains("client offline") || message.contains("network error") {
            return true
        }
        if ns.domain == "com.firebase.core" || ns.domain.contains("FirebaseDatabase") {
            return ns.code == 1
        }
        return false
    }

    nonisolated private static func waitForConnection(timeoutSeconds: Double) async throws {
        let connectedRef = database.reference(withPath: ".info/connected")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            final class State: @unchecked Sendable {
                private let lock = NSLock()
                private var handle: DatabaseHandle?
                private var finished = false
                private let connectedRef: DatabaseReference
                private let continuation: CheckedContinuation<Void, Error>

                init(
                    connectedRef: DatabaseReference,
                    continuation: CheckedContinuation<Void, Error>
                ) {
                    self.connectedRef = connectedRef
                    self.continuation = continuation
                }

                func setHandle(_ handle: DatabaseHandle) {
                    lock.lock()
                    self.handle = handle
                    lock.unlock()
                }

                func complete(_ result: Result<Void, Error>) {
                    lock.lock()
                    guard !finished else {
                        lock.unlock()
                        return
                    }
                    finished = true
                    let handle = self.handle
                    self.handle = nil
                    lock.unlock()

                    if let handle {
                        connectedRef.removeObserver(withHandle: handle)
                    }
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            let state = State(connectedRef: connectedRef, continuation: continuation)
            let handle = connectedRef.observe(.value) { snapshot in
                guard (snapshot.value as? Bool) == true else { return }
                state.complete(.success(()))
            }
            state.setHandle(handle)

            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                state.complete(.failure(NSError(
                    domain: "com.firebase.core",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Timed out waiting for Realtime Database connection."]
                )))
            }
        }
    }
}
