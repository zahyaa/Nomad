# Swift & SwiftUI Cheat Sheet for Nomad Project

> **Quick reference for Swift 6, SwiftUI, SwiftData, and iOS 17+ features used in Nomad**

---

## 📱 Project Stack

- **Language:** Swift 6 (strict concurrency enabled)
- **UI:** SwiftUI (100% declarative, no UIKit/Storyboards)
- **Persistence:** SwiftData (local SQLite database)
- **Cloud:** CloudKit (public database sync)
- **Min iOS:** iOS 17+ (some features iOS 16+ with `@available`)
- **Testing:** Swift Testing framework + XCTest

---

## 🏷️ Property Wrappers

### App & Scene Level

```swift
@main                          // App entry point
struct NomadApp: App { }

@UIApplicationDelegateAdaptor  // Bridge to UIKit AppDelegate
var appDelegate: NomadAppDelegate
```

### SwiftUI View State

```swift
@State                         // View-local state (owned by view)
private var isShowing = false

@Binding                       // Two-way connection to parent's @State
var selectedItem: Item

@Environment                   // Read from environment
@Environment(\.modelContext) private var modelContext
@Environment(\.dismiss) private var dismiss

@EnvironmentObject             // Legacy shared state (use @Environment now)
@EnvironmentObject var settings: AppSettings
```

### SwiftData Models

```swift
@Model                         // SwiftData persistence model
final class Postcard {
    var id: UUID
    var name: String
}

@Relationship                  // Define relationships between models
@Relationship(deleteRule: .cascade)
var items: [Item]

@Query                         // Fetch SwiftData models in views
@Query(sort: \Postcard.timestamp) var postcards: [Postcard]

@Query(                        // Advanced query with filter
    filter: #Predicate<Postcard> { $0.isFavorite },
    sort: [SortDescriptor(\Postcard.timestamp, order: .reverse)]
) var postcards: [Postcard]
```

### Observable State (Swift 6)

```swift
@Observable                    // Modern observable class (replaces ObservableObject)
@MainActor
final class CameraManager {
    var status: Status = .unknown
}

@Bindable                      // Create bindings from @Observable
func textField(item: Item) -> some View {
    @Bindable var item = item
    TextField("Name", text: $item.name)
}
```

### Legacy Combine (Pre-Swift 6)

```swift
@Published                     // ObservableObject property (legacy)
@Published var count = 0

@ObservedObject                // Legacy observable (use @Observable now)
@ObservedObject var viewModel: ViewModel

@StateObject                   // Legacy owned observable (use @State now)
@StateObject var manager = LocationManager()
```

---

## 🔤 Swift Keywords & Attributes

### Access Control

```swift
public                         // Accessible everywhere
internal                       // Module-only (default)
private                        // File-only
fileprivate                    // File scope
```

### Type Modifiers

```swift
final                          // Cannot be subclassed
class                          // Reference type
struct                         // Value type (preferred in Swift)
enum                           // Enumeration
actor                          // Thread-safe reference type
```

### Value vs Reference

```swift
struct User { }                // VALUE: Copied on assignment
class User { }                 // REFERENCE: Shared pointer
```

### Async/Await Concurrency

```swift
async                          // Async function
await                          // Wait for async result
Task { }                       // Create async task

actor CameraManager { }        // Thread-safe isolated type
@MainActor                     // Runs on main thread
nonisolated                    // Opt out of actor isolation
```

### Error Handling

```swift
throw                          // Throw error
throws                         // Function can throw
try                            // Call throwing function
try?                           // Optional result (nil on error)
try!                           // Force unwrap (crash on error)
do { } catch { }               // Handle errors

Result<Success, Failure>       // Type-safe result
```

### Memory Management

```swift
weak                           // Weak reference (nullable)
unowned                        // Unowned reference (non-nullable)
[weak self]                    // Capture list in closures
```

### Protocols

```swift
protocol Nameable {            // Define contract
    var name: String { get }
}

extension User: Nameable { }   // Conform to protocol

Codable                        // Encodable + Decodable
Hashable                       // Can be hashed
Identifiable                   // Has stable `id`
Equatable                      // Can compare with ==
Sendable                       // Thread-safe (Swift 6)
```

### Generics

```swift
func process<T>(_ item: T)     // Generic function
where T: Codable               // Generic constraint

struct Box<T> { }              // Generic type
```

### Type Aliases

```swift
typealias StringDict = [String: String]
```

---

## 🎨 SwiftUI View Components

### Basic Views

```swift
Text("Hello")                  // Label
Image(systemName: "star")      // SF Symbol
Image("photo")                 // Asset image
Color.blue                     // Color view
Spacer()                       // Flexible space
Divider()                      // Horizontal/vertical line
```

### Layout Containers

```swift
VStack { }                     // Vertical stack
HStack { }                     // Horizontal stack
ZStack { }                     // Depth stack (layers)
LazyVStack { }                 // Lazy vertical (recycles views)
LazyHStack { }                 // Lazy horizontal
Grid { }                       // 2D grid layout
LazyVGrid(columns:) { }        // Vertical grid
ScrollView { }                 // Scrollable container
List { }                       // Platform-styled list
Form { }                       // Grouped settings style
```

### Input Controls

```swift
Button("Tap") { }              // Button
Toggle("On", isOn: $flag)      // Switch
TextField("Name", text: $name) // Text input
SecureField("Pass", text: $pw) // Password input
Slider(value: $val, in: 0...1) // Slider
Picker("Pick", selection: $s)  // Picker
DatePicker("Date", selection:) // Date picker
ColorPicker("Color", selection:)
Stepper("Count", value: $count)
```

### Navigation

```swift
NavigationStack { }            // Navigation container (iOS 16+)
NavigationLink("Go", value: item) // Navigation trigger
.navigationTitle("Title")      // Nav bar title
.navigationBarTitleDisplayMode(.inline)
.toolbar { }                   // Toolbar items

TabView { }                    // Tab bar
.tabItem { }                   // Tab bar item
```

### Presentation

```swift
.sheet(isPresented: $show) { } // Modal sheet
.fullScreenCover { }           // Full screen modal
.alert("Title", isPresented:)  // Alert dialog
.confirmationDialog { }        // Action sheet
.popover { }                   // Popover (iPad)
```

### Modifiers (Order Matters!)

```swift
.padding()                     // Add padding
.background(Color.blue)        // Background
.foregroundStyle(.red)         // Text/icon color
.font(.title)                  // Font style
.fontWeight(.bold)             // Font weight
.clipShape(Circle())           // Clip to shape
.cornerRadius(8)               // Round corners
.shadow(radius: 4)             // Drop shadow
.frame(width: 100, height: 50) // Fixed size
.overlay { }                   // Layer on top
.opacity(0.5)                  // Transparency
.offset(x: 10, y: 20)          // Position offset
.rotationEffect(.degrees(45))  // Rotation
.scaleEffect(1.2)              // Scale
.animation(.default, value: x) // Animate changes
.transition(.slide)            // Transition effect
.task { }                      // Async task on appear
.onAppear { }                  // On view appear
.onChange(of: value) { }       // Value changed
```

---

## 💾 SwiftData Usage

### Define Models

```swift
import SwiftData

@Model                         // Mark as persistent model
final class Postcard {
    var id: UUID               // Stored property
    var name: String
    var timestamp: Date
    
    @Relationship(deleteRule: .cascade)  // One-to-many
    var photos: [Photo]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.timestamp = .now
    }
}
```

### Setup Container

```swift
// In App
let schema = Schema([Postcard.self, User.self])
let config = ModelConfiguration(schema: schema)
let container = try ModelContainer(for: schema, configurations: [config])

WindowGroup { RootView() }
    .modelContainer(container)
```

### Query Data

```swift
// In View
@Query var postcards: [Postcard]                    // All items

@Query(sort: \Postcard.timestamp)                   // Sorted
var postcards: [Postcard]

@Query(                                             // Filtered
    filter: #Predicate<Postcard> { $0.isFavorite },
    sort: [SortDescriptor(\Postcard.timestamp, order: .reverse)]
) var postcards: [Postcard]
```

### Modify Data

```swift
@Environment(\.modelContext) private var context

// Create
let postcard = Postcard(name: "Paris")
context.insert(postcard)

// Update
postcard.name = "London"

// Delete
context.delete(postcard)

// Save
try? context.save()
```

### Relationships

```swift
// One-to-Many
@Model
final class Collection {
    @Relationship(deleteRule: .cascade)
    var postcards: [Postcard]?
}

// Many-to-Many
@Model
final class Postcard {
    @Relationship(deleteRule: .nullify, inverse: \Collection.postcards)
    var collections: [Collection]?
}
```

---

## ⚡ Async/Await & Concurrency

### Basic Async

```swift
func fetchData() async -> Data {
    // Async work
}

// Call async function
Task {
    let data = await fetchData()
}
```

### Actor Isolation

```swift
actor DataManager {                // Thread-safe
    var cache: [String: Data] = [:]
    
    func store(_ data: Data, key: String) {
        cache[key] = data
    }
}

@MainActor                         // Always on main thread
final class ViewModel {
    var items: [Item] = []
}

nonisolated                        // Opt out of actor
nonisolated let queue = DispatchQueue(label: "work")
```

### Async Sequences

```swift
for await value in stream {
    print(value)
}
```

### Task Groups

```swift
await withTaskGroup(of: Data.self) { group in
    group.addTask { await fetch(1) }
    group.addTask { await fetch(2) }
    
    for await data in group {
        process(data)
    }
}
```

---

## 🗺️ iOS Frameworks Used

### MapKit (Maps)

```swift
import MapKit

Map {
    Marker("Paris", coordinate: coord)
    MapPolyline(coordinates: path)
        .stroke(.blue, lineWidth: 3)
}
.mapStyle(.standard)
```

### AVFoundation (Camera)

```swift
import AVFoundation

let session = AVCaptureSession()
let output = AVCapturePhotoOutput()
session.addOutput(output)
session.startRunning()
```

### CloudKit (Cloud Sync)

```swift
import CloudKit

let database = CKContainer.default().publicCloudDatabase
let record = CKRecord(recordType: "Postcard")
try await database.save(record)
```

### CoreLocation (GPS)

```swift
import CoreLocation

let manager = CLLocationManager()
manager.requestWhenInUseAuthorization()
manager.startUpdatingLocation()
```

### WeatherKit (Weather)

```swift
import WeatherKit

let service = WeatherService()
let weather = try await service.weather(for: location)
```

### WidgetKit (Home Screen Widgets)

```swift
import WidgetKit

struct Provider: TimelineProvider { }

@main
struct NomadWidgetBundle: WidgetBundle {
    var body: some Widget {
        PostcardWidget()
    }
}
```

### AppIntents (Siri Shortcuts)

```swift
import AppIntents

struct OpenCameraIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Camera"
    
    func perform() async throws -> some IntentResult {
        // Action
        return .result()
    }
}
```

### PencilKit (Drawing)

```swift
import PencilKit

let canvas = PKCanvasView()
let tool = PKInkingTool(.pen, color: .black, width: 5)
canvas.tool = tool
```

---

## 🧪 Swift Testing Framework

### Test Structure

```swift
import Testing

@Test func emptyArray_returnsZero() {
    let result = count([])
    #expect(result == 0)
}

@Test func validInput_succeeds() throws {
    let result = try process("data")
    #expect(result.isValid)
}

@MainActor
@Test func viewModel_updatesState() {
    let vm = ViewModel()
    vm.load()
    #expect(vm.items.count > 0)
}
```

### Expectations

```swift
#expect(value == 10)           // Equality
#expect(value != nil)          // Non-nil
#expect(array.isEmpty)         // Bool
#expect(throws: MyError.self)  // Throws specific error
```

---

## 🏗️ Common Patterns in Nomad

### Enums with Raw Values

```swift
enum PostcardStatus: String, Codable {
    case draft, sent, received
}

// Usage
var statusRaw: String          // Store in SwiftData
var status: PostcardStatus {   // Computed property
    get { PostcardStatus(rawValue: statusRaw) ?? .draft }
    set { statusRaw = newValue.rawValue }
}
```

### Computed Properties

```swift
var cachedImage: UIImage? {
    guard let data = thumbnailData ?? renderedImageData else {
        return nil
    }
    return UIImage(data: data)
}
```

### Extensions

```swift
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

extension View {
    func cardStyle() -> some View {
        self.background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}
```

### Namespaces (Matched Geometry)

```swift
@Namespace private var animation

// In view
Text("Hello")
    .matchedGeometryEffect(id: "text", in: animation)
```

### Result Builders

```swift
@ViewBuilder                   // SwiftUI's DSL
var content: some View {
    if showTitle {
        Text("Title")
    }
    Text("Body")
}
```

### Environment Values

```swift
@Environment(\.modelContext) var modelContext
@Environment(\.dismiss) var dismiss
@Environment(\.colorScheme) var colorScheme

// Custom
extension EnvironmentValues {
    @Entry var theme: Theme = .default
}
```

### Preview Macros

```swift
#Preview {
    HistoryView()
        .modelContainer(previewContainer)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
```

---

## 📦 Common Swift Types

### Collections

```swift
Array<T> or [T]                // Ordered collection
Set<T>                         // Unordered unique
Dictionary<K, V> or [K: V]     // Key-value pairs
```

### Optionals

```swift
var name: String?              // Optional (can be nil)
let value = name ?? "Default"  // Nil coalescing
if let name = name { }         // Optional binding
guard let name = name else { return }
name?.uppercased()             // Optional chaining
```

### Result Type

```swift
Result<Success, Failure>       // Success or error

func load() -> Result<Data, Error> {
    if success {
        return .success(data)
    } else {
        return .failure(error)
    }
}

// Pattern match
switch result {
case .success(let data):
    print(data)
case .failure(let error):
    print(error)
}
```

### Tuples

```swift
let point = (x: 10, y: 20)
let (x, y) = point
```

---

## 🎯 Useful Swift Operators

```swift
??                             // Nil coalescing: value ?? default
...                            // Closed range: 0...10 (includes 10)
..<                            // Half-open range: 0..<10 (excludes 10)
$0, $1                         // Shorthand closure params
\\.propertyName                // Key path
===                            // Reference equality (same instance)
==                             // Value equality
&& || !                        // Logical AND, OR, NOT
```

---

## 🔧 Debugging & Development

### Print Debugging

```swift
print("Value: \(value)")       // Basic print
dump(object)                   // Detailed structure
debugPrint(value)              // Debug description
```

### Assertions

```swift
assert(condition, "Message")   // Debug only
precondition(condition)        // Always checked
fatalError("Should not reach") // Crash
```

### Preprocessor

```swift
#if DEBUG
    print("Debug mode")
#endif

#warning("TODO: Fix this")
#error("This is broken")
```

---

## 📝 Naming Conventions in Nomad

### Files

```swift
NomadApp.swift                 // App entry point
Models.swift                   // Data models
CameraManager.swift            // Manager suffix
HistoryView.swift              // View suffix
PostcardRenderer.swift         // Service/Utility
```

### Variables

```swift
var isShowing: Bool            // is/has prefix for Bool
var selectedItem: Item         // clear descriptive names
private var didConfigure: Bool // private with explicit access
```

### Functions

```swift
func fetchData()               // Verb-based
func validate(_ text: String)  // Action-based
func handleCapture()           // handle prefix for callbacks
```

### Constants

```swift
private let maxLength = 280    // camelCase for constants
```

---

## ⚙️ Project-Specific Utilities

### SwiftData Schema

```swift
let schema = Schema([
    Postcard.self,
    User.self,
    PostcardCollection.self,
    CustomStamp.self
])
```

### Error Handling Pattern

```swift
do {
    return try ModelContainer(for: schema)
} catch {
    print("⚠️ Error: \(error)")
    // Fallback
}
```

### Date Formatting

```swift
let formatter = DateFormatter()
formatter.dateStyle = .medium
formatter.timeStyle = .short
return formatter.string(from: date)
```

### Image Compression

```swift
let compressed = image.jpegData(compressionQuality: 0.7)
```

---

## 🎨 SF Symbols (Built-in Icons)

```swift
Image(systemName: "camera")
Image(systemName: "star.fill")
Image(systemName: "paperplane")
Image(systemName: "map")
Image(systemName: "cloud.sun.fill")
Image(systemName: "photo.stack")
Image(systemName: "person.circle")
```

**Browse all symbols:** Download "SF Symbols" app from Apple

---

## 🚀 Performance Tips

### Lazy Loading

```swift
LazyVStack { }                 // Only renders visible items
LazyVGrid { }                  // Grid version
```

### Avoid Heavy Work in Body

```swift
// ❌ BAD
var body: some View {
    let processed = heavyProcess() // Runs on EVERY redraw!
    Text(processed)
}

// ✅ GOOD
@State private var processed = ""
var body: some View {
    Text(processed)
        .task {
            processed = await heavyProcess()
        }
}
```

### Use @MainActor Wisely

```swift
@MainActor                     // Only for UI updates
final class ViewModel {
    var items: [Item] = []
}
```

---

## 📚 Quick Reference Card

| Concept | Syntax | Use Case |
|---------|--------|----------|
| **View State** | `@State` | View-owned state |
| **Two-way Bind** | `@Binding` | Parent-child connection |
| **Environment** | `@Environment` | System values |
| **SwiftData** | `@Model` + `@Query` | Persistence |
| **Observable** | `@Observable` | Modern state management |
| **Async** | `async`/`await` | Concurrency |
| **Actor** | `actor` | Thread-safe type |
| **Main Thread** | `@MainActor` | UI updates |
| **Navigation** | `NavigationStack` | Modern navigation |
| **Modal** | `.sheet()` | Present modally |
| **List** | `List { }` | Scrollable list |
| **Layout** | `VStack`/`HStack`/`ZStack` | Arrange views |

---

## 🎯 Most Used in Nomad

### Top Property Wrappers
1. `@State` - View state
2. `@Query` - SwiftData queries
3. `@Environment(\.modelContext)` - Database access
4. `@Observable` - Observable classes
5. `@Bindable` - Bindings from Observable

### Top View Types
1. `VStack`/`HStack`/`ZStack` - Layout
2. `NavigationStack` - Navigation
3. `List` - Lists
4. `Button` - Actions
5. `Text` - Labels
6. `Image` - Icons/Photos

### Top Modifiers
1. `.padding()` - Spacing
2. `.background()` - Background color
3. `.navigationTitle()` - Nav title
4. `.sheet()` - Modals
5. `.task { }` - Async tasks

---

## 📖 Learning Resources

- **Official Docs:** [developer.apple.com](https://developer.apple.com)
- **SwiftUI:** [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- **Swift Book:** [Swift Programming Language](https://docs.swift.org/swift-book/)
- **WWDC Videos:** Search "SwiftUI" or "SwiftData" on Apple Developer
- **Hacking with Swift:** [hackingwithswift.com](https://hackingwithswift.com)

---

**Quick Tip:** Use Xcode's autocomplete (Ctrl+Space) and Quick Help (Option+Click) to explore APIs!

---

_Last Updated: May 30, 2026_  
_Project: Nomad iOS App (Swift 6 + SwiftUI + SwiftData)_
