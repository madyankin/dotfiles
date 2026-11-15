# SwiftData + CloudKit Sync

Deep-dive on enabling CloudKit sync with SwiftData, schema constraints, conflict resolution, testing, and known limitations.

---

## How It Works

SwiftData's CloudKit integration uses `NSPersistentCloudKitContainer` under the hood. When you configure a `ModelConfiguration` with a CloudKit container identifier, SwiftData automatically:

1. Mirrors all `@Model` records to the CloudKit private database
2. Syncs changes across devices signed into the same iCloud account
3. Handles conflict resolution with a last-write-wins strategy

This is the same mechanism as Core Data + CloudKit, but surfaced through SwiftData's API.

---

## Enabling CloudKit Sync

### Basic Setup

```swift
@main
struct BookshelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Book.self,
                        cloudKitDatabase: .private("iCloud.com.yourcompany.bookshelf"))
    }
}
```

### Custom Configuration

```swift
let cloudConfig = ModelConfiguration(
    "Bookshelf",
    schema: Schema([Book.self, Author.self]),
    cloudKitDatabase: .private("iCloud.com.yourcompany.bookshelf")
)
let container = try ModelContainer(
    for: Schema([Book.self, Author.self]),
    configurations: cloudConfig
)
```

### CloudKit Database Options

| Option | Behavior |
|---|---|
| `.private("container.id")` | Sync to the user's private iCloud database (default for user data) |
| `.public("container.id")` | Sync to the public CloudKit database (shared across all users — use carefully) |
| `.none` | No CloudKit sync (local-only store) |

### Entitlements Required

In your app target's `.entitlements` file:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.yourcompany.bookshelf</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

Also enable **iCloud** → **CloudKit** in Xcode's Signing & Capabilities tab for your target.

---

## Schema Constraints Imposed by CloudKit

CloudKit has stricter requirements than a local SQLite store. Violating these constraints causes a runtime crash when the container is initialized.

### 1. All Attributes Must Be Optional

CloudKit records can always have absent fields. SwiftData enforces this by requiring every stored property to be optional:

```swift
// WRONG — non-optional properties crash with CloudKit
@Model final class Book {
    var title: String          // ❌ crash at container init
    var publishedYear: Int     // ❌ crash at container init
}

// RIGHT — all stored properties must be optional
@Model final class Book {
    var title: String?
    var publishedYear: Int?
    var rating: Double?
}
```

**Practical pattern:** Use optional properties in the model, but provide non-optional computed accessors for the UI:

```swift
@Model final class Book {
    var title: String?

    var displayTitle: String { title ?? "Untitled" }
}
```

### 2. No `.unique` Attributes

CloudKit doesn't enforce field uniqueness at the database level. Using `@Attribute(.unique)` with a CloudKit-backed store will crash at container initialization:

```swift
// WRONG
@Attribute(.unique) var isbn: String?   // ❌ incompatible with CloudKit

// RIGHT — enforce uniqueness in app logic instead
var isbn: String?

func isbnAlreadyExists(_ isbn: String, in context: ModelContext) throws -> Bool {
    let descriptor = FetchDescriptor<Book>(
        predicate: #Predicate { $0.isbn == isbn }
    )
    return try !context.fetch(descriptor).isEmpty
}
```

### 3. No Custom Migration Plans

CloudKit sync is **incompatible** with `SchemaMigrationPlan` custom stages. If you need CloudKit, you are limited to lightweight migrations only (adding optional properties, renaming with `originalName`).

### 4. Relationship Constraints

- All relationships must be optional on both sides
- Many-to-many relationships are supported but require careful ordering to avoid CloudKit record conflicts
- Ordered relationships (`[Model]` with `@Relationship`) are supported via `NSOrderedSet` under the hood

### 5. No `@Attribute(.externalStorage)` in Public Database

External storage (assets) is supported in the private database but **not** in the public CloudKit database. Use `.private` for any model with `@Attribute(.externalStorage)`.

---

## Conflict Resolution

SwiftData + CloudKit uses **last-write-wins** conflict resolution based on the record's `modifiedAt` timestamp. The most recently modified version of a record wins.

### Designing for Last-Write-Wins

Structure your data to minimize conflicts:

```swift
// BAD: single counter — concurrent increments conflict, one update is lost
@Model final class Stats {
    var playCount: Int?   // Device A: 5, Device B: 5 → one write wins, other is lost
}

// GOOD: log individual events, derive the count
@Model final class PlayEvent {
    var bookId: String?
    var occurredAt: Date?
    // Each event is an independent record — no conflicts
}
// Derive count in a query or computed property
```

### Merge Fields Instead of Replacing

For list-like data where multiple devices may add items independently, store each item as a separate `@Model` record rather than as an array property on a parent:

```swift
// BAD: array property — concurrent additions on two devices → one device's additions lost
@Model final class ReadingList {
    var bookIDs: [String]?   // conflict on the whole array
}

// GOOD: each membership is its own record — no conflict
@Model final class ReadingListEntry {
    var listId: String?
    var bookId: String?
    var addedAt: Date?
}
```

---

## Handling Sync Events

SwiftData doesn't expose CloudKit sync events directly, but you can observe them via `NSPersistentCloudKitContainer` notifications:

```swift
import CoreData

// Observe remote change notifications to refresh UI after sync
NotificationCenter.default.publisher(
    for: NSPersistentCloudKitContainer.eventChangedNotification
)
.compactMap { $0.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
    as? NSPersistentCloudKitContainer.Event }
.filter { $0.type == .import && $0.endDate != nil }
.receive(on: DispatchQueue.main)
.sink { event in
    if let error = event.error {
        // Handle sync error (e.g., display a banner)
        print("CloudKit sync error: \(error)")
    }
    // Optionally trigger a manual UI refresh
}
.store(in: &cancellables)
```

---

## Testing CloudKit-Backed Stores

Never test against a real CloudKit container in unit tests — it's slow, requires a network, and pollutes production data.

### In-Memory Containers for Unit Tests

```swift
// Use isStoredInMemoryOnly — skips CloudKit sync entirely
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Book.self, configurations: config)
}
```

The in-memory configuration does not enforce the CloudKit schema constraints (optional-only properties), so you can test with non-optional properties in isolation. Be aware of this discrepancy when writing tests.

### Mocking the Sync Layer

If you need to test sync-dependent logic, abstract the sync behavior behind a protocol:

```swift
protocol SyncStatusProvider {
    var isSyncing: Bool { get }
    var lastSyncDate: Date? { get }
}

// Production: reads from NSPersistentCloudKitContainer events
struct CloudKitSyncStatus: SyncStatusProvider { ... }

// Test: simple mock
struct MockSyncStatus: SyncStatusProvider {
    var isSyncing: Bool = false
    var lastSyncDate: Date? = nil
}
```

### Simulator CloudKit Testing

Use the **CloudKit Dashboard** (developer.apple.com/icloud) to inspect and reset records in your development container. In Simulator, sign into a sandbox iCloud account to test real sync without affecting production data.

---

## Known Limitations

| Limitation | Details |
|---|---|
| All properties must be optional | Non-optional properties crash at container init with CloudKit |
| No `.unique` attributes | Not supported; enforce uniqueness in app logic |
| No custom migration stages | Only lightweight migrations are supported |
| No `@Attribute(.externalStorage)` in public DB | Assets only work in the private database |
| Last-write-wins only | No custom merge policies |
| Sync is opaque | No first-class SwiftData API for sync status; must use CoreData notifications |
| Offline queue size | CloudKit queues up to ~3MB of changes while offline; large bulk writes may need to be chunked |
| Public database quotas | Public DB has strict per-operation and storage limits; not suitable for per-user data |
| No Swift 6 strict concurrency guarantees | CloudKit sync callbacks may arrive on unexpected queues; always dispatch UI updates to `@MainActor` |

---

## Decision: Should You Use CloudKit?

Use SwiftData + CloudKit when:
- You need cross-device sync for a single user's private data
- Your schema is simple and stable (lightweight migrations only)
- You can accept last-write-wins conflict resolution
- All your model properties can be optional

**Avoid** SwiftData + CloudKit when:
- You need unique constraints enforced at the store level
- You have complex migrations requiring custom transformation stages
- You need custom conflict resolution (e.g., CRDTs, operational transforms)
- You're building a shared/collaborative multi-user database (consider CloudKit sharing APIs or a custom backend instead)
- You need to sync non-optional properties without wrapping them in optionals throughout your codebase
