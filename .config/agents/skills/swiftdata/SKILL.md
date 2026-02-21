---
name: swiftdata
description: SwiftData best practices and architecture expert - advises on @Model schema design, ModelContext/ModelContainer lifecycle, @Query fetching, relationships, migrations, SwiftUI integration, performance, testing, and CloudKit sync. Use when the user asks about SwiftData, @Model, @Query, ModelContext, ModelContainer, SwiftData relationships, SwiftData migrations, SwiftData CloudKit, SwiftData performance, or testing with SwiftData.
---

# SwiftData Architecture & Best Practices Expert

Expert guidance on building correct, performant, and maintainable SwiftData-backed applications. Covers schema design, context lifecycle, reactive querying, relationships, migrations, SwiftUI integration, and testing.

## Core Mental Model: Three-Layer Stack

SwiftData's architecture maps cleanly to three layers:

```
ModelContainer   — persistent store configuration (one per app)
      ↓
ModelContext     — unit of work / scratch pad (main context is @MainActor-bound)
      ↓
@Model instances — in-memory representations of persisted objects
```

- **`ModelContainer`** owns the schema and the underlying store file. Created once at app startup.
- **`ModelContext`** tracks in-memory objects and coordinates inserts, deletes, and saves. The **main context** runs on `@MainActor`; create **background contexts** for heavy writes.
- **`@Model` instances** are live objects. Any property change on the main context is automatically tracked and can trigger `@Query` view updates.

`@Query` is a property wrapper that keeps a SwiftUI view in sync with the store. It runs a live fetch and re-renders the view whenever matching objects change.

```
ModelContainer → provides context → @Model instances mutated → @Query re-fetches → View updates
```

---

## @Model & Schema Design

### Defining a Model

```swift
import SwiftData

@Model
final class Book {
    // Stored properties are persisted automatically
    var title: String
    var author: String
    var publishedYear: Int
    var rating: Double?            // Optional — can be nil in the store

    // @Attribute customizes persistence behavior
    @Attribute(.unique) var isbn: String                      // enforces uniqueness
    @Attribute(originalName: "desc") var summary: String      // rename without migration
    @Attribute(.externalStorage) var coverImage: Data?        // stored outside SQLite row

    // Relationships
    @Relationship(deleteRule: .cascade) var chapters: [Chapter] = []

    // Transient — not persisted, recomputed each time
    @Transient var displayTitle: String { title.isEmpty ? "Untitled" : title }

    init(title: String, author: String, isbn: String, publishedYear: Int) {
        self.title = title
        self.author = author
        self.isbn = isbn
        self.publishedYear = publishedYear
        self.summary = ""
    }
}
```

### @Attribute Options

| Option | Purpose |
|---|---|
| `.unique` | Enforce uniqueness; upsert on duplicate insert |
| `.externalStorage` | Store large `Data` blobs outside the SQLite row (e.g., images) |
| `originalName: "old"` | Rename a property without a migration stage |
| `.spotlight` | Index for Spotlight search |
| `.allowsCloudEncryption` | Encrypt field in CloudKit (iCloud Keychain-backed) |

### Transient vs Computed Properties

```swift
@Model final class Product {
    var priceInCents: Int

    // GOOD: @Transient — excluded from persistence, recomputed on access
    @Transient var formattedPrice: String {
        "$\(Double(priceInCents) / 100.0)"
    }

    // BAD: plain computed property — NOT persisted, but SwiftData may warn
    // var formattedPrice: String { ... }   // use @Transient explicitly
}
```

---

## ModelContainer & ModelContext

### App Entry Point Setup

```swift
@main
struct BookshelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Registers the container in the environment for all child views
        .modelContainer(for: [Book.self, Chapter.self])
    }
}
```

### Custom Container Configuration

```swift
let config = ModelConfiguration(
    "Bookshelf",
    schema: Schema([Book.self, Chapter.self]),
    url: customStoreURL,
    isStoredInMemoryOnly: false,
    allowsSave: true
)
let container = try ModelContainer(
    for: Schema([Book.self, Chapter.self]),
    configurations: config
)
```

### Background Context for Heavy Writes

```swift
// Never use the main context for bulk operations — it blocks the UI
Task.detached(priority: .background) {
    let context = ModelContext(container)   // new background context
    context.autosaveEnabled = false        // manual save for bulk control

    for item in largeDataset {
        context.insert(MyModel(data: item))
    }
    try context.save()   // single save for the entire batch
}
```

### autosaveEnabled

The main context autosaves on each run-loop tick by default. Disable for explicit control (e.g., form editing with a "Cancel" button):

```swift
@Environment(\.modelContext) private var context

func discardChanges() {
    context.rollback()   // undo all unsaved changes
}

func saveChanges() throws {
    try context.save()
}
```

---

## @Query & Fetching

### Basic @Query

```swift
struct BookListView: View {
    // Live fetch — re-renders the view whenever any Book changes
    @Query(sort: \Book.title) private var books: [Book]

    var body: some View {
        List(books) { book in Text(book.title) }
    }
}
```

### Filtering with #Predicate

```swift
// Static predicate
@Query(filter: #Predicate<Book> { $0.rating ?? 0 >= 4.0 },
       sort: \Book.title)
private var topRatedBooks: [Book]

// Dynamic predicate — passed from parent via init
struct BookListView: View {
    init(authorFilter: String) {
        _books = Query(
            filter: #Predicate<Book> { $0.author == authorFilter },
            sort: \Book.publishedYear, order: .reverse
        )
    }
    @Query private var books: [Book]
}
```

**`#Predicate` limitations:** Only a subset of Swift expressions is supported — no custom functions, no regex. Supported string ops: `.contains`, `.hasPrefix`, `.hasSuffix`, `.localizedStandardContains`. Use `FetchDescriptor` for predicates that `#Predicate` can't express.

### Imperative Fetching with FetchDescriptor

```swift
// One-off fetch in a store method, background task, or unit test
func fetchTopRated(in context: ModelContext) throws -> [Book] {
    var descriptor = FetchDescriptor<Book>(
        predicate: #Predicate { $0.rating ?? 0 >= 4.0 },
        sortBy: [SortDescriptor(\Book.title)]
    )
    descriptor.fetchLimit = 20
    descriptor.includePendingChanges = true   // include unsaved inserts
    return try context.fetch(descriptor)
}
```

### @Query Animation

```swift
@Query(sort: \Book.title, animation: .default)
private var books: [Book]
```

---

## Relationships

### One-to-Many

```swift
@Model final class Author {
    var name: String
    // SwiftData requires bidirectional inverse declarations
    @Relationship(deleteRule: .cascade, inverse: \Book.author)
    var books: [Book] = []
}

@Model final class Book {
    var title: String
    var author: Author?   // the "many" side holds an optional back-reference
}
```

### Delete Rules

| Rule | Behavior |
|---|---|
| `.nullify` (default) | Set the inverse to nil on delete |
| `.cascade` | Delete all related objects when parent is deleted |
| `.deny` | Prevent deletion if related objects exist |
| `.noAction` | Do nothing — manage manually |

### Inverse Relationship Requirement

SwiftData **requires** every relationship to have an inverse. Omitting it causes silent data corruption:

```swift
// WRONG — missing inverse
@Model final class Shelf {
    @Relationship(deleteRule: .cascade) var books: [Book] = []
}

// RIGHT — inverse declared on both sides
@Model final class Shelf {
    @Relationship(deleteRule: .cascade, inverse: \Book.shelf)
    var books: [Book] = []
}
@Model final class Book {
    var shelf: Shelf?
}
```

### Many-to-Many

```swift
@Model final class Book {
    @Relationship(inverse: \Tag.books) var tags: [Tag] = []
}
@Model final class Tag {
    var name: String
    @Relationship(inverse: \Book.tags) var books: [Book] = []
}
```

---

## SwiftUI Integration

### modelContainer Modifier

```swift
// Single type
.modelContainer(for: Book.self)

// Multiple types
.modelContainer(for: [Book.self, Author.self, Tag.self])

// Custom container
.modelContainer(myContainer)
```

### Inserting & Deleting from Views

```swift
struct BookListView: View {
    @Environment(\.modelContext) private var context
    @Query private var books: [Book]

    var body: some View {
        List {
            ForEach(books) { book in Text(book.title) }
                .onDelete(perform: deleteBooks)
        }
        .toolbar {
            Button("Add") { addBook() }
        }
    }

    private func addBook() {
        let book = Book(title: "New Book", author: "Unknown",
                        isbn: UUID().uuidString, publishedYear: 2024)
        context.insert(book)   // autosave picks this up on the next run-loop tick
    }

    private func deleteBooks(at offsets: IndexSet) {
        offsets.map { books[$0] }.forEach { context.delete($0) }
    }
}
```

### Editing Model Properties

SwiftUI bindings work directly on `@Model` properties via `@Bindable`:

```swift
struct BookEditView: View {
    @Bindable var book: Book   // @Bindable enables $book.title two-way binding

    var body: some View {
        Form {
            TextField("Title", text: $book.title)
            TextField("Author", text: $book.author)
        }
    }
}
```

---

## Performance & Optimization

### Use fetchLimit to Avoid Loading Everything

```swift
// BAD: loads all 10,000 books; view renders 10
@Query(sort: \Book.title) private var books: [Book]

// GOOD: limit imperative fetches
var descriptor = FetchDescriptor<Book>(sortBy: [SortDescriptor(\Book.title)])
descriptor.fetchLimit = 50
let page = try context.fetch(descriptor)
```

### Prefetch Relationships to Avoid N+1

```swift
// BAD: each iteration fires a separate fault for the author relationship
for book in books { print(book.author?.name ?? "") }

// GOOD: prefetch with FetchDescriptor
var descriptor = FetchDescriptor<Book>()
descriptor.relationshipKeyPathsForPrefetching = [\Book.author]
let books = try context.fetch(descriptor)
```

### Push Filters into #Predicate

```swift
// BAD: @Query loads all rows, Swift filters in memory
@Query private var allBooks: [Book]
var filtered: [Book] { allBooks.filter { $0.publishedYear >= 2020 } }

// GOOD: filter at the store level — view only observes matching rows
@Query(filter: #Predicate<Book> { $0.publishedYear >= 2020 })
private var recentBooks: [Book]
```

### Background Saves for Bulk Operations

```swift
func importBooks(_ data: [BookData], into container: ModelContainer) async throws {
    try await Task.detached(priority: .background) {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        for item in data {
            context.insert(Book(title: item.title, author: item.author,
                                isbn: item.isbn, publishedYear: item.year))
        }
        try context.save()   // single save — far cheaper than per-object autosave
    }.value
}
```

---

## Testing Strategies

### In-Memory Container

```swift
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Book.self, configurations: config)
}

final class BookTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    func test_insertBook_persistsToStore() throws {
        let book = Book(title: "Test", author: "Author", isbn: "1234", publishedYear: 2024)
        context.insert(book)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Book>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].title, "Test")
    }

    func test_deleteBook_removesFromStore() throws {
        let book = Book(title: "To Delete", author: "Author", isbn: "5678", publishedYear: 2024)
        context.insert(book)
        try context.save()
        context.delete(book)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Book>())
        XCTAssertTrue(fetched.isEmpty)
    }
}
```

### Previews with Pre-Populated Container

```swift
#Preview {
    let container = try! ModelContainer(
        for: Book.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    ctx.insert(Book(title: "Swift in Depth", author: "Tjeerd in 't Veen",
                    isbn: "9781617294600", publishedYear: 2019))
    return BookListView()
        .modelContainer(container)
}
```

### Testing Business Logic Without SwiftData

Extract logic into plain Swift types for fast, dependency-free unit tests:

```swift
struct BookRatingCalculator {
    static func average(for ratings: [Double?]) -> Double {
        let rated = ratings.compactMap { $0 }
        return rated.isEmpty ? 0 : rated.reduce(0, +) / Double(rated.count)
    }
}

func test_averageRating_ignoresNils() {
    let ratings: [Double?] = [4.0, 5.0, nil]
    XCTAssertEqual(BookRatingCalculator.average(for: ratings), 4.5)
}
```

---

## Common Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Using main `ModelContext` off `@MainActor` | Data race — main context is not thread-safe | Create a new `ModelContext(container)` on the background task |
| Omitting inverse relationships | Silent data corruption, broken cascades | Always declare `inverse:` on both sides of a relationship |
| Filtering `@Query` results in Swift | Over-fetches all rows; re-renders on any change | Push the filter into `#Predicate` inside `@Query` |
| Saving in the wrong context | Changes don't persist (different in-memory graph) | Always save the same context you inserted/deleted from |
| Schema changes without a migration plan | Store incompatibility crash on upgrade | Add a `SchemaMigrationPlan` stage before shipping breaking changes |
| `.unique` attribute with CloudKit | CloudKit doesn't support unique constraints | Remove `.unique` and enforce uniqueness in app logic |
| Large `Data` blobs stored inline | Bloats SQLite row, slows all fetches | Use `@Attribute(.externalStorage)` for images/files |
| Fetching inside a `@Model` init | Initializer runs during fetch — infinite recursion risk | Never call `context.fetch` inside a `@Model` initializer |
| Non-`Codable` custom types as properties | Won't serialize to the store | Use primitives or conform custom types to `Codable` |

---

## Decision Guide

**`@Query` vs `FetchDescriptor`:**
- Driving a SwiftUI view with live updates → `@Query`
- One-off fetch in a store method, background task, or unit test → `FetchDescriptor`
- Complex predicate `#Predicate` can't express → `FetchDescriptor`

**Main context vs background context:**
- Reading data for display → main context via `@Query` or `@Environment(\.modelContext)`
- Bulk inserts, imports → background `ModelContext(container)` with `autosaveEnabled = false`
- Editing a single object in a form → main context with `context.rollback()` on cancel

**Which delete rule:**
- Parent owns children (e.g., post → comments) → `.cascade`
- Children can exist without parent → `.nullify`
- Prevent accidental deletion of parent when children exist → `.deny`

**Migration approach:**
- Adding an optional property, or renaming with `originalName` → no migration stage needed
- Changing non-optional to optional, splitting/merging properties, changing types → `SchemaMigrationPlan` with a custom stage
- See [Migrations deep dive](docs/migrations.md) for full details

**CloudKit sync:**
- Simple sync, no unique constraints → SwiftData + CloudKit works well
- Custom migrations, unique constraints, or write-heavy offline-first → reconsider or avoid CloudKit
- See [CloudKit deep dive](docs/cloudkit.md) for full details

---

## Reference Docs

- [Migrations & Versioning](docs/migrations.md) — VersionedSchema, SchemaMigrationPlan, lightweight vs custom stages, pitfalls
- [CloudKit Sync](docs/cloudkit.md) — configuration, schema constraints, conflict resolution, limitations, testing
