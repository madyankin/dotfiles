---
name: swiftui-architecture
description: SwiftUI best practices and architecture expert - advises on state management, view composition, MVVM vs MV pattern, data flow, performance, navigation, and testing. Use when the user asks about SwiftUI architecture, state management (@State, @Binding, @Observable, @EnvironmentObject), view design, performance, or building scalable SwiftUI apps.
---

# SwiftUI Architecture & Best Practices Expert

Expert guidance on building maintainable, performant SwiftUI applications. Covers architecture patterns, state management, view composition, navigation, and testing.

## Core Mental Model: Identity, Lifetime, and Dependencies

SwiftUI operates on three fundamental concepts (from WWDC21 "Demystify SwiftUI"):

- **Identity**: How SwiftUI recognizes elements as the same or distinct across updates
- **Lifetime**: How SwiftUI tracks the existence of views and data over time
- **Dependencies**: How SwiftUI knows when and what to update

```
View Identity → Controls Lifetime → Drives Dependency Updates
```

State (`@State`, `@StateObject`) is storage tied to a view's **identity**, not its value.
When identity changes, state is reset. When identity is stable, state persists.

---

## Architecture Patterns

### The MV Pattern (Apple's Recommended Approach)

For client/server apps, Apple's own samples (Fruta, FoodTruck) use a **Model-View (MV)** pattern where views act as their own view model, backed by observable store objects:

```swift
// Store (ObservableObject / @Observable) = single source of truth per domain
@MainActor
@Observable
class FoodTruckStore {
    let httpClient: HTTPClient
    private(set) var products: [Product] = []
    private(set) var orders: [Order] = []

    // Computed properties for derived data live here, not in views
    var premiumProducts: [Product] {
        products.filter { $0.isPremium }
    }

    func loadAllProducts() async throws {
        products = try await httpClient.load(Resource(url: Constants.Urls.products))
    }

    func saveProduct(_ product: Product) async throws {
        // ...
    }
}

// View is the view model — no separate ViewModel class needed
struct ProductListScreen: View {
    @Environment(FoodTruckStore.self) private var store

    var body: some View {
        List(store.products) { product in
            ProductRowView(product: product)
        }
        .task { try? await store.loadAllProducts() }
    }
}
```

**Key principle**: Avoid creating a new `ObservableObject` (new source of truth) just because you added a new view. The source of truth for a client/server app is **the server**.

### MVVM — When It Makes Sense

Traditional MVVM (one ViewModel per view) is often overkill in SwiftUI and creates:
- Multiple competing sources of truth (each `ObservableObject` is a new source of truth)
- Unnecessary boilerplate (20 screens → 20 ViewModels)
- Complex dependency injection chains
- Redundant synchronization code (SwiftUI already provides bindings)

**Use MVVM** when:
- A view has complex, independently testable business logic
- You need isolation from SwiftUI (e.g., shared logic with UIKit)
- The ViewModel maps between domain model and view-specific presentation model

### Clean Architecture (3-Layer)

For large apps, apply Clean Architecture with three layers:

```
┌────────────────────────────────────────────┐
│           Presentation Layer               │
│      SwiftUI Views + Local @State          │
├────────────────────────────────────────────┤
│         Business Logic Layer               │
│   Interactors / Stores + AppState          │
├────────────────────────────────────────────┤
│          Data Access Layer                 │
│   Repositories / HTTP Clients / CoreData   │
└────────────────────────────────────────────┘
```

**AppState**: Single `ObservableObject` / `@Observable` class holding global app state (auth, routing, user data). Knows nothing about business logic.

**Interactor**: Stateless, encapsulates business logic for a group of views. Reads/writes `AppState` or `Binding`s. Never returns data directly — pushes results to state.

**Repository**: Stateless gateway to a single data source (network API, CoreData, etc.). Hidden behind a protocol for testability.

### Modular Architecture (Large Teams)

Divide the app by **bounded context** (domain-driven design):

```
App
├── CatalogModule/       ← CatalogStore + CatalogUI
├── OrderingModule/      ← OrderingStore + OrderingUI
├── ShippingModule/      ← ShippingStore + ShippingUI
└── FoundationCore/      ← Shared utilities, components, network layer
```

Each module can be an SPM package or folder. Teams work independently without interfering.

---

## State Management

### Property Wrapper Decision Guide

| Wrapper | Use When |
|---|---|
| `@State` | Local, private view state (transient UI state) |
| `@Binding` | Pass mutable state down to a child view |
| `@StateObject` | Own the lifecycle of an `ObservableObject` in a view |
| `@ObservedObject` | Reference an externally-owned `ObservableObject` |
| `@EnvironmentObject` | Share an `ObservableObject` across a deep view hierarchy |
| `@Environment` | Access environment values (colorScheme, locale, custom values) |
| `@Observable` (iOS 17+) | Modern replacement for `ObservableObject` — simpler, more performant |

### Modern State with `@Observable` (iOS 17+)

```swift
// Preferred for iOS 17+ — no @Published needed, automatic fine-grained updates
@Observable
class AppModel {
    var username: String = ""
    var isLoggedIn: Bool = false
    var cart: [CartItem] = []
}

// In views:
struct ProfileView: View {
    @Environment(AppModel.self) private var model  // read-only
    // or
    @Bindable var model: AppModel  // for two-way bindings

    var body: some View {
        TextField("Name", text: $model.username)  // requires @Bindable
    }
}
```

### Source of Truth Hierarchy

```
Server / Database
       ↓
  Store / AppState  (@Observable / @StateObject)
       ↓
  Screen Views      (@EnvironmentObject / @Environment)
       ↓
  Child Views       (@Binding / props)
```

Never create "shortcut" sources of truth. If a child view needs to mutate parent state, pass a `@Binding`, not a copy.

---

## View Composition & Design

### Screens vs Views

Distinguish between **screens** (full pages) and **reusable views** (components):

| Screens | Views |
|---|---|
| `MovieDetailScreen` | `RatingStarsView` |
| `LoginScreen` | `UserAvatarView` |
| `HomeScreen` | `ProductRowView` |

Screens are **container views** — they fetch data, hold state, and compose presentational views.
Presentational views receive data as parameters and have no external dependencies.

### Container / Presenter Pattern

```swift
// Container: fetches data, owns state, not reusable
struct ProductListScreen: View {
    @Environment(CatalogStore.self) private var store

    var body: some View {
        ProductListView(products: store.products)  // passes data to presenter
            .task { try? await store.loadAllProducts() }
    }
}

// Presenter: stateless, highly reusable, testable in previews
struct ProductListView: View {
    let products: [Product]

    var body: some View {
        List(products) { product in
            ProductRowView(product: product)
        }
    }
}
```

### Avoid AnyView — Use Generics or @ViewBuilder

```swift
// BAD: Erases type information, harms performance and diagnostics
func makeView(for breed: DogBreed) -> some View {
    if breed == .labrador {
        return AnyView(LabradorView())
    }
    return AnyView(PoodleView())
}

// GOOD: Use @ViewBuilder to preserve structural identity
@ViewBuilder
func makeView(for breed: DogBreed) -> some View {
    switch breed {
    case .labrador: LabradorView()
    case .poodle:   PoodleView()
    }
}
```

### View Decomposition

Break large views into smaller components. Views are value types — they are **cheap to create**:

```swift
// BAD: Monolithic body
var body: some View {
    VStack {
        // 200 lines of nested view code
    }
}

// GOOD: Extracted subviews, computed properties, or separate structs
var body: some View {
    VStack {
        headerSection
        ProductGrid(products: products)
        FooterView()
    }
}

private var headerSection: some View {
    HStack { /* ... */ }
}
```

---

## Identity & Performance

### Stable Identifiers in ForEach

```swift
// BAD: UUID() in a computed property generates new identity on every render
ForEach(items) { item in
    ItemView(item: item)
        .id(UUID())  // NEVER do this
}

// BAD: Using array indices as identity
ForEach(items.indices, id: \.self) { index in  // fragile on insertion/removal
    ItemView(item: items[index])
}

// GOOD: Use stable, unique IDs from data (database ID, persistent UUID)
struct Item: Identifiable {
    let id: UUID  // stable, generated once and persisted
    var name: String
}
ForEach(items) { item in
    ItemView(item: item)
}
```

### Prefer Single Conditional View (Inert Modifiers)

```swift
// BAD: Two separate identities, causes state reset and animation issues
if isExpired {
    TreatView(treat: treat).opacity(0.5)
} else {
    TreatView(treat: treat)
}

// GOOD: Single identity, condition drives modifier only
TreatView(treat: treat)
    .opacity(isExpired ? 0.5 : 1.0)
```

### Minimize Dependency Scope

```swift
// BAD: Entire view re-renders when any part of store changes
struct ProductDetailView: View {
    @Environment(CatalogStore.self) private var store
    let productId: UUID

    var product: Product? { store.products.first { $0.id == productId } }
}

// GOOD: Pass only what the view needs — limits re-renders to relevant data
struct ProductDetailView: View {
    let product: Product  // immutable, no unnecessary subscriptions
}
```

### @MainActor for UI-Touching Stores

```swift
@MainActor  // Ensures all UI mutations happen on main thread
@Observable
class CatalogStore {
    var products: [Product] = []

    func loadProducts() async throws {
        // Swift concurrency: network call runs on background, but
        // assignment to products (MainActor) automatically hops back
        products = try await httpClient.load(Resource(url: .products))
    }
}
```

---

## Navigation

### NavigationStack (iOS 16+)

```swift
// Preferred: NavigationStack with path for programmatic navigation
@Observable
class AppRouter {
    var path = NavigationPath()

    func navigate(to destination: AppRoute) {
        path.append(destination)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum AppRoute: Hashable {
    case productDetail(Product)
    case orderHistory
    case settings
}

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .productDetail(let product): ProductDetailScreen(product: product)
                    case .orderHistory:               OrderHistoryScreen()
                    case .settings:                   SettingsScreen()
                    }
                }
        }
        .environment(router)
    }
}
```

### TabView with Navigation

```swift
@Observable
class TabRouter {
    var selectedTab: Tab = .home

    enum Tab: Hashable {
        case home, catalog, orders, profile
    }
}

struct MainTabView: View {
    @State private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(TabRouter.Tab.home)

            CatalogScreen()
                .tabItem { Label("Catalog", systemImage: "square.grid.2x2") }
                .tag(TabRouter.Tab.catalog)
        }
        .environment(router)
    }
}
```

---

## Validation & Forms

### Simple Forms: Computed Properties in View

```swift
struct LoginScreen: View {
    @State private var username = ""
    @State private var password = ""

    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8
    }

    var body: some View {
        Form {
            TextField("Username", text: $username)
            SecureField("Password", text: $password)
            Button("Login") { /* submit */ }
                .disabled(!isFormValid)
        }
    }
}
```

### Complex Forms: Extract to a Struct

```swift
// Extracting logic into a struct enables unit testing
struct LoginFormConfig {
    var username: String = ""
    var password: String = ""

    var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8
    }

    var usernameError: String? {
        username.isEmpty ? "Username is required" : nil
    }
}

struct LoginScreen: View {
    @State private var form = LoginFormConfig()

    var body: some View {
        Form {
            TextField("Username", text: $form.username)
            if let error = form.usernameError {
                Text(error).foregroundStyle(.red).font(.caption)
            }
            Button("Login") { /* submit */ }.disabled(!form.isFormValid)
        }
    }
}
```

---

## Error Handling

```swift
// Error state in the store
@MainActor
@Observable
class CatalogStore {
    var products: [Product] = []
    var error: Error?
    var isLoading = false

    func loadProducts() async {
        isLoading = true
        error = nil
        do {
            products = try await httpClient.load(Resource(url: .products))
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// View handles error display
struct ProductListScreen: View {
    @Environment(CatalogStore.self) private var store

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
            } else {
                ProductListView(products: store.products)
            }
        }
        .alert("Error", isPresented: .constant(store.error != nil)) {
            Button("Retry") { Task { await store.loadProducts() } }
        } message: {
            Text(store.error?.localizedDescription ?? "Unknown error")
        }
        .task { await store.loadProducts() }
    }
}
```

---

## Grouping View Events with Enums

As child views grow in complexity, consolidate callbacks into an enum:

```swift
// Instead of multiple closure parameters...
struct ReminderCellView: View {
    let index: Int
    let onChecked: (Int) -> Void
    let onDelete: (Int) -> Void
    let onEdit: (Int) -> Void  // growing list of closures = messy
}

// ...group into a typed event enum
enum ReminderCellEvent {
    case checked(Int)
    case deleted(Int)
    case edited(Int)
}

struct ReminderCellView: View {
    let index: Int
    let onEvent: (ReminderCellEvent) -> Void

    var body: some View {
        HStack {
            Image(systemName: "square")
                .onTapGesture { onEvent(.checked(index)) }
            Text("Reminder \(index)")
            Spacer()
            Image(systemName: "trash")
                .onTapGesture { onEvent(.deleted(index)) }
        }
    }
}
```

---

## Testing Strategy

### Pyramid Approach

```
         E2E Tests (XCUITest)
        /     slowest, highest confidence
       /
      Integration Tests
     /    store + network mocks
    /
   Unit Tests
  /   form validation, business logic structs
 /
Xcode Previews
  fastest feedback for view layout/logic
```

### Unit Test Extracted Logic

```swift
// Testable form struct (no SwiftUI dependency)
struct ProductFilterForm {
    var minPrice: Double?
    var maxPrice: Double?

    func filter(_ products: [Product]) -> [Product] {
        guard let min = minPrice, let max = maxPrice else { return products }
        return products.filter { $0.price >= min && $0.price <= max }
    }
}

// Clean unit test
func test_filterByPrice_returnsCorrectProducts() {
    let products = [
        Product(id: 1, name: "Cheap", price: 10),
        Product(id: 2, name: "Mid", price: 100),
        Product(id: 3, name: "Expensive", price: 500),
    ]
    let form = ProductFilterForm(minPrice: 50, maxPrice: 200)
    let result = form.filter(products)
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].name, "Mid")
}
```

### Mock Network Layer with Protocols

```swift
protocol HTTPClientProtocol {
    func load<T: Decodable>(_ resource: Resource<T>) async throws -> T
}

// Production
struct HTTPClient: HTTPClientProtocol { /* URLSession impl */ }

// Test stub
struct HTTPClientStub: HTTPClientProtocol {
    let response: Any

    func load<T: Decodable>(_ resource: Resource<T>) async throws -> T {
        response as! T
    }
}

// Store is testable with injected stub
let store = CatalogStore(httpClient: HTTPClientStub(response: mockProducts))
```

### Xcode Previews as Fast Feedback

```swift
#Preview("Product List - Loaded") {
    ProductListScreen()
        .environment(CatalogStore(httpClient: HTTPClientStub(response: Product.samples)))
}

#Preview("Product List - Empty") {
    ProductListScreen()
        .environment(CatalogStore(httpClient: HTTPClientStub(response: [])))
}

#Preview("Product List - Loading") {
    ProductListScreen()
        .environment(CatalogStore.loading)  // custom factory for preview state
}
```

---

## Common Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| `AnyView` everywhere | Erases type info, hurts performance & diagnostics | Use `@ViewBuilder`, generics, or `Group` |
| One ViewModel per View | Creates many competing sources of truth | Use a Store per bounded context |
| Random `id` in `ForEach` | Forces full re-render, breaks animations | Use stable, persistent identifiers |
| `@ObservedObject` for owned state | Object can be destroyed while view lives | Use `@StateObject` to own lifecycle |
| Logic in `body` | Hard to test, slow preview compilation | Extract to computed properties or structs |
| Unnecessary `if/else` branching | Different identity per branch → state reset | Prefer inert modifiers (`.opacity`, `.hidden`) |
| Array indices as `id` | Unstable on insertion/deletion | Use `Identifiable` with persistent IDs |
| Nested `ObservableObject` properties | SwiftUI doesn't observe nested object changes | Flatten state or use `@Observable` (iOS 17+) |
| Deep `@EnvironmentObject` coupling in child views | Breaks reusability | Pass data as parameters to presentational views |

---

## Decision Guide

**Choosing an architecture:**
- Small app (< 5 screens): `@State` + `@StateObject`, no Store needed
- Medium client/server app: Single `@Observable` Store, MV pattern
- Large app (multiple domains/teams): Multiple Stores per bounded context, consider Clean Architecture layers

**Choosing state management:**
- "This value is only used here" → `@State`
- "A child needs to mutate this" → `@Binding`
- "I own this object" → `@StateObject` / `@State var model = MyModel()`
- "I reference this from a parent" → `@ObservedObject`
- "This is needed deep in the hierarchy" → `@EnvironmentObject` / `@Environment`
- "iOS 17+ and I want the simplest approach" → `@Observable` + `@Environment`

**Choosing navigation:**
- iOS 16+: `NavigationStack` with typed `NavigationPath`
- Deep linking needed: Store navigation path in a Router `@Observable`
- Tab-based app: `TabView` with `selection` bound to a Router

**Choosing where to put logic:**
- View-specific UI logic (simple): Computed property in view body
- View-specific UI logic (complex): Extract to a `struct` (testable)
- Business/domain logic: Interactor or Store method
- Data fetching: Store method calling Repository/HTTPClient
