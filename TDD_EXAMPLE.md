# TDD Example: Message Validator

## 📋 Complete TDD Workflow Demonstrated

### What We Built
A `MessageValidator` utility using **Test-Driven Development** to validate postcard messages.

---

## 🔄 The TDD Cycle

### Phase 1: 🔴 RED - Write Failing Tests First

**File:** `NomadTests/MessageValidatorTests.swift`

```swift
@Test func messageExceedingMaxLength_isInvalid() {
    let message = String(repeating: "a", count: 281)
    let result = MessageValidator.validate(message)
    #expect(result.isValid == false)
    #expect(result.errors.contains(.tooLong))
}
```

**At this point:**
- ❌ Tests fail (MessageValidator doesn't exist)
- ❌ Code doesn't compile
- ✅ We know exactly what to build

---

### Phase 2: 🟢 GREEN - Make Tests Pass

**File:** `Utilities/MessageValidator.swift`

```swift
enum MessageValidator {
    static func validate(_ message: String?) -> ValidationResult {
        // Implementation that makes all tests pass
    }
}
```

**At this point:**
- ✅ All tests pass
- ✅ Code compiles
- ✅ Minimal implementation (no over-engineering)

---

### Phase 3: 🔵 REFACTOR - Improve Code

**Optional improvements:**
- Add convenience methods (`isValid()`, `characterCount()`)
- Better whitespace handling
- Performance optimizations
- Documentation

**At this point:**
- ✅ Tests still pass (regression protection)
- ✅ Code is cleaner
- ✅ Confidence to refactor

---

## 🧪 Unit Tests vs UI Tests

### Unit Tests (Fast, Isolated)

**Location:** `NomadTests/*.swift`  
**Framework:** Swift Testing (modern) or XCTest (legacy)  
**Speed:** Milliseconds  
**Purpose:** Test individual functions/classes

#### Real Example from Project:

```swift
// File: StampThemeHeuristicTests.swift
@Test func defaultsToCityWhenCoordinateIsNil() {
    let theme = StampThemeHeuristic.theme(for: nil)
    #expect(theme == StampTheme.city.rawValue)
}
```

**What it tests:**
- Single utility function
- No UI involved
- No network calls
- Pure logic

**Benefits:**
✅ Run in < 1 second  
✅ Easy to debug  
✅ Can test edge cases  
✅ Run on CI/CD server  

---

### UI Tests (Slow, End-to-End)

**Location:** `NomadUITests/*.swift`  
**Framework:** XCTest + XCUIApplication  
**Speed:** Seconds/Minutes  
**Purpose:** Test user workflows

#### Example UI Test (Not in project, but typical):

```swift
func testCaptureAndSendPostcard() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to camera
    app.tabBars.buttons["Camera"].tap()
    
    // Capture photo
    app.buttons["Capture"].tap()
    
    // Verify composer appears
    XCTAssertTrue(app.textFields["Message"].exists)
    
    // Type message
    app.textFields["Message"].tap()
    app.textFields["Message"].typeText("Hello from Paris!")
    
    // Select recipient
    app.buttons["Select Recipient"].tap()
    app.tables.cells.firstMatch.tap()
    
    // Send
    app.buttons["Send"].tap()
    
    // Verify success
    XCTAssertTrue(app.staticTexts["Sent!"].exists)
}
```

**What it tests:**
- Complete user journey
- Actual UI interactions
- Navigation flow
- Integration of all components

**Benefits:**
✅ Tests real user experience  
✅ Catches integration bugs  
✅ Documents user flows  

**Drawbacks:**
❌ Slow (minutes for full suite)  
❌ Brittle (breaks on UI changes)  
❌ Hard to test edge cases  
❌ Requires simulator/device  

---

## 📊 Comparison Table

| Aspect | Unit Tests | UI Tests |
|--------|-----------|----------|
| **Speed** | ⚡ Milliseconds | 🐌 Seconds/Minutes |
| **Scope** | Single function | Full user flow |
| **Flakiness** | Stable | Can be flaky |
| **Coverage** | Deep (edge cases) | Broad (happy path) |
| **Debugging** | Easy | Difficult |
| **Cost** | Low | High |
| **When to Use** | Always | Critical paths only |

---

## 🎯 Testing Strategy for Nomad

### Test Pyramid (Recommended)

```
        /\
       /UI\          ← Few UI tests (critical paths)
      /────\
     /Unit  \        ← Many unit tests (all utilities)
    /────────\
   /Integration\     ← Some integration tests (managers)
  /______________\
```

### What to Unit Test:
✅ Utilities (MessageValidator, ImageCompressor, StampThemeHeuristic)  
✅ Models (Postcard init, validation, computed properties)  
✅ Managers (CloudKit operations, location parsing)  
✅ Business logic (theme detection, export formats)  

### What to UI Test:
✅ Critical flows (capture → edit → send)  
✅ Onboarding  
✅ Authentication  
✅ Error states  

### What NOT to Test:
❌ SwiftUI view rendering (Apple's responsibility)  
❌ Third-party frameworks (already tested)  
❌ Simple getters/setters  

---

## 🔬 Running Tests

### Command Line (Terminal)
```bash
# Run all tests
xcodebuild test -scheme Nomad -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only unit tests
xcodebuild test -scheme Nomad -only-testing:NomadTests

# Run only UI tests  
xcodebuild test -scheme Nomad -only-testing:NomadUITests

# Run specific test
xcodebuild test -scheme Nomad -only-testing:NomadTests/MessageValidatorTests
```

### Xcode GUI
1. **Cmd + U** - Run all tests
2. **Cmd + 6** - Open Test Navigator
3. Click ▶️ next to specific test to run it
4. **Cmd + Ctrl + U** - Run tests for current file

### Swift Testing (Modern)
```bash
# Using swift test command
swift test --filter MessageValidatorTests
```

---

## 📝 Test Naming Conventions

### Good Test Names (Self-Documenting)

✅ **Given_When_Then Pattern:**
```swift
@Test func emptyMessage_whenValidated_returnsValid()
@Test func longMessage_whenExceedsLimit_returnsError()
```

✅ **Subject_Condition_Expectation:**
```swift
@Test func messageValidator_withEmptyString_returnsZeroCount()
@Test func messageValidator_withURL_detectsLink()
```

✅ **BDD Style (Behavior-Driven):**
```swift
@Test func shouldReturnValidForEmptyMessage()
@Test func shouldDetectURLsInMessage()
```

❌ **Bad Test Names:**
```swift
@Test func test1() // What does this test?
@Test func testValidate() // Too vague
```

---

## 🎓 TDD Benefits Demonstrated

### 1. **Requirement Documentation**
Tests serve as executable specifications:
```swift
@Test func messageAtMaxLength_isValid() {
    let message = String(repeating: "a", count: 280)
    // ^ Documents: Max length is 280 characters
}
```

### 2. **Regression Prevention**
If we accidentally break validation:
```swift
// Someone changes maxLength to 100
static let maxLength = 100  // Oops!

// Tests immediately catch this:
// ❌ messageAtMaxLength_isValid FAILED
```

### 3. **Design Improvement**
Writing tests first forces good API design:
```swift
// BAD (hard to test):
func validate(msg: String, max: Int, checkURL: Bool, trim: Bool) 

// GOOD (easy to test):
func validate(_ message: String?) -> ValidationResult
```

### 4. **Confidence in Refactoring**
Can safely optimize implementation:
```swift
// Before: Basic implementation
private static func containsURL(_ text: String) -> Bool {
    return text.contains("http")
}

// After: Better implementation
private static func containsURL(_ text: String) -> Bool {
    let detector = try? NSDataDetector(...)
    return !detector.matches(...).isEmpty
}

// Tests ensure behavior unchanged! ✅
```

---

## 🚀 Next Steps

### To use MessageValidator in the app:

1. **Add to PostcardComposerView:**
   ```swift
   let validation = MessageValidator.validate(draftMessage)
   ```

2. **Show character count:**
   ```swift
   Text("\(validation.characterCount)/280")
   ```

3. **Validate before sending:**
   ```swift
   .disabled(!validation.isValid)
   ```

4. **Trim whitespace:**
   ```swift
   postcard.message = validation.trimmedMessage
   ```

### To add more tests:

1. Add test to `MessageValidatorTests.swift`
2. Run tests (they fail - RED)
3. Update `MessageValidator.swift`
4. Tests pass - GREEN
5. Refactor if needed - REFACTOR

---

## 📚 Summary

### Unit Tests
- **What:** Test individual functions
- **When:** Always (fast, cheap, valuable)
- **Example:** MessageValidator, StampThemeHeuristic

### UI Tests  
- **What:** Test user workflows
- **When:** Critical paths only (slow, expensive)
- **Example:** Complete postcard send flow

### TDD Process
1. 🔴 **RED:** Write failing test
2. 🟢 **GREEN:** Make it pass
3. 🔵 **REFACTOR:** Clean up

### Benefits
✅ Better design  
✅ Living documentation  
✅ Regression protection  
✅ Confidence to refactor  
✅ Faster debugging  

**Result:** High-quality, maintainable code! 🎉
