# SwiftData Migrations & Versioning

Deep-dive on `VersionedSchema`, `SchemaMigrationPlan`, lightweight migrations, and custom migration stages.

---

## Why Migrations Matter

SwiftData stores the schema version alongside your data. When you ship a new app version with a changed schema, SwiftData checks whether the on-disk version matches the current schema. If it doesn't match and there is no migration plan, SwiftData will **refuse to open the store** and throw a fatal error.

Always add a `SchemaMigrationPlan` before shipping any breaking schema change to production users.

---

## VersionedSchema

Each distinct schema version is declared as a `VersionedSchema`-conforming enum. All your `@Model` types for that version are nested inside it:

```swift
import SwiftData

// Version 1 — initial schema
enum BookSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Book.self]
    }

    @Model final class Book {
        var title: String
        var author: String
        var isbn: String

        init(title: String, author: String, isbn: String) {
            self.title = title
            self.author = author
            self.isbn = isbn
        }
    }
}

// Version 2 — added publishedYear, renamed isbn → isbnCode
enum BookSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Book.self]
    }

    @Model final class Book {
        var title: String
        var author: String
        @Attribute(originalName: "isbn") var isbnCode: String   // renamed
        var publishedYear: Int?                                  // new optional property

        init(title: String, author: String, isbnCode: String) {
            self.title = title
            self.author = author
            self.isbnCode = isbnCode
        }
    }
}
```

**Key rule:** Each `VersionedSchema` is a **frozen snapshot**. Never modify a `VersionedSchema` after you've shipped it. Add a new version instead.

---

## SchemaMigrationPlan

A `SchemaMigrationPlan` declares the ordered list of migration stages from the oldest supported version to the current version:

```swift
enum BookMigrationPlan: SchemaMigrationPlan {
    // The current schema (latest version)
    static var currentSchema: any VersionedSchema.Type {
        BookSchemaV2.self
    }

    // All migration stages, in order from oldest to newest
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: BookSchemaV1.self,
        toVersion: BookSchemaV2.self
    )
}
```

Wire the plan into the `ModelContainer`:

```swift
let container = try ModelContainer(
    for: BookSchemaV2.Book.self,
    migrationPlan: BookMigrationPlan.self,
    configurations: ModelConfiguration("Bookshelf")
)
```

SwiftData will automatically migrate through all stages in order. If the on-disk store is at V1, it runs `migrateV1toV2`. If it's already at V2, no migration runs.

---

## Lightweight Migrations

Lightweight migration handles schema changes that SwiftData can apply **automatically** without any data transformation code:

| Change | Lightweight? |
|---|---|
| Add an optional property | Yes |
| Add a non-optional property with a default value | Yes |
| Remove a property | Yes (data is discarded) |
| Rename a property with `@Attribute(originalName:)` | Yes |
| Add a new `@Model` type | Yes |
| Change a non-optional to optional | Yes |
| Change a property type (e.g., `Int` → `String`) | **No** — requires custom stage |
| Change a non-optional to non-optional with different default | **No** — requires custom stage |
| Split one property into two | **No** — requires custom stage |
| Merge two properties into one | **No** — requires custom stage |

```swift
// Example: add an optional property and rename another — both lightweight
static let migrateV1toV2 = MigrationStage.lightweight(
    fromVersion: BookSchemaV1.self,
    toVersion: BookSchemaV2.self
    // No code needed — SwiftData handles it automatically
)
```

---

## Custom Migration Stages

Use a custom stage when you need to transform data during migration:

```swift
// V2 → V3: split "author" (String) into separate firstName + lastName
enum BookSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [Book.self] }

    @Model final class Book {
        var title: String
        var firstName: String
        var lastName: String
        var isbnCode: String
        var publishedYear: Int?

        init(title: String, firstName: String, lastName: String, isbnCode: String) {
            self.title = title
            self.firstName = firstName
            self.lastName = lastName
            self.isbnCode = isbnCode
        }
    }
}

// Custom stage with willMigrate closure
static let migrateV2toV3 = MigrationStage.custom(
    fromVersion: BookSchemaV2.self,
    toVersion: BookSchemaV3.self,
    willMigrate: { context in
        // willMigrate runs BEFORE the schema is applied — use fromVersion types
        let books = try context.fetch(FetchDescriptor<BookSchemaV2.Book>())
        for book in books {
            // Store split data somewhere accessible post-migration
            // (e.g., a temporary UserDefaults key, or encoded in another field)
            // NOTE: You cannot write to V3 fields here — the V3 schema isn't applied yet
        }
    },
    didMigrate: { context in
        // didMigrate runs AFTER the schema is applied — use toVersion types
        let books = try context.fetch(FetchDescriptor<BookSchemaV3.Book>())
        for book in books {
            // book.author is gone; split into firstName/lastName
            // In practice: store the old value in willMigrate, read it here
            let parts = book.title.split(separator: " ", maxSplits: 1)
            book.firstName = String(parts.first ?? "")
            book.lastName = parts.count > 1 ? String(parts[1]) : ""
        }
        try context.save()
    }
)
```

**`willMigrate` vs `didMigrate`:**

| Hook | Schema in effect | `@Model` types available | Typical use |
|---|---|---|---|
| `willMigrate` | `fromVersion` schema | Old model types | Read old data, stash values for `didMigrate` |
| `didMigrate` | `toVersion` schema | New model types | Write transformed values using new model layout |

---

## Multi-Version Migration Chain

If users may be on any version (V1, V2, or V3), list all stages:

```swift
enum BookMigrationPlan: SchemaMigrationPlan {
    static var currentSchema: any VersionedSchema.Type { BookSchemaV3.self }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]   // order matters — oldest first
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: BookSchemaV1.self,
        toVersion: BookSchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: BookSchemaV2.self,
        toVersion: BookSchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            // transform V2 → V3 data
            try context.save()
        }
    )
}
```

A user on V1 will run both stages sequentially. A user already on V2 will only run the second stage.

---

## Testing Migrations

Always test migrations with an actual on-disk store from the previous version:

```swift
final class MigrationTests: XCTestCase {

    func test_migrationV1toV2_preservesData() throws {
        // 1. Create a V1 store with seed data
        let v1Config = ModelConfiguration("test-v1", isStoredInMemoryOnly: true)
        let v1Container = try ModelContainer(
            for: BookSchemaV1.Book.self,
            configurations: v1Config
        )
        let v1Context = ModelContext(v1Container)
        v1Context.insert(BookSchemaV1.Book(title: "Dune", author: "Frank Herbert",
                                           isbn: "978-0-441-17271-9"))
        try v1Context.save()

        // 2. Re-open the same store URL with the migration plan
        let v2Config = ModelConfiguration("test-v1", isStoredInMemoryOnly: true)
        let v2Container = try ModelContainer(
            for: BookSchemaV2.Book.self,
            migrationPlan: BookMigrationPlan.self,
            configurations: v2Config
        )
        let v2Context = ModelContext(v2Container)

        // 3. Assert migrated data is correct
        let books = try v2Context.fetch(FetchDescriptor<BookSchemaV2.Book>())
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books[0].isbnCode, "978-0-441-17271-9")   // renamed field
        XCTAssertNil(books[0].publishedYear)                      // new optional = nil
    }
}
```

For on-disk migration tests, write the V1 store to a temp file, then open it with the migration plan pointing at the same URL.

---

## Common Pitfalls

| Pitfall | Consequence | Fix |
|---|---|---|
| Modifying a shipped `VersionedSchema` | On-disk hash mismatch → store open failure | Never modify; always add a new version |
| Wrong stage order in `stages` array | Skipped or double-applied stages → corruption | Keep stages oldest-first, one stage per version bump |
| Forgetting `try context.save()` in `didMigrate` | Transformed data is lost after migration | Always save at the end of `didMigrate` |
| Writing to `toVersion` types in `willMigrate` | Crash — new schema not applied yet | Use `willMigrate` only to read old data; write in `didMigrate` |
| Shipping a non-optional property addition without a default | Lightweight migration fails for existing rows | Always make new properties optional, or provide a default via the model's `init` |
| Using CloudKit + custom migration | CloudKit sync does not support custom migration plans | Stick to lightweight-only migrations with CloudKit, or disable CloudKit during migration |
