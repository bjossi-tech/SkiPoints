# SkiPoints App — Known Issues & Problematic Functions

This document catalogs all identified problems, bugs, and code quality issues across the
SkiPoints iOS app codebase (13 Swift files, ~1,353 lines of code).

---

## Table of Contents

- [Critical Issues](#critical-issues)
- [Error Handling Issues](#error-handling-issues)
- [Incomplete Implementations & Dead Code](#incomplete-implementations--dead-code)
- [Hard-Coded Values](#hard-coded-values)
- [Problematic Logic & Potential Bugs](#problematic-logic--potential-bugs)
- [Network & API Issues](#network--api-issues)
- [Code Quality & Maintainability](#code-quality--maintainability)
- [Summary](#summary)

---

## Critical Issues

### 1. Force Unwrapping (`!`) — Crash Risk

Force unwrapping causes an immediate crash if the value is `nil`.

| File | Line | Code |
|------|------|------|
| `SettingsView.swift` | 14 | `URL(string: "https://www.fis-ski.com")!` |
| `PreviewData.swift` | 198 | `Calendar.current.date(byAdding: .hour, value: 3, to: Date())!` |
| `PreviewData.swift` | 212 | `Calendar.current.date(byAdding: .hour, value: -4, to: Date())!` |
| `PreviewData.swift` | 257 | `Calendar.current.date(byAdding: .day, value: 1, to: Date())!` |
| `FISNetworkService.swift` | 98 | `calendar.date(byAdding: .day, value: 1, to: today)!` |
| `FISNetworkService.swift` | 127 | `calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!` |

**Recommendation:** Replace all force unwraps with `guard let` or `if let` optional binding.

---

### 2. Array Access Without Bounds Checking

Direct subscript access without verifying the array has enough elements will crash on
an out-of-bounds index.

| File | Line(s) | Code |
|------|---------|------|
| `FISHTMLParser.swift` | 491 | `let lastName = components[0]` |
| `FISHTMLParser.swift` | 506–507 | `Double(components[0])`, `Double(components[1])` |
| `PreviewData.swift` | 269 | `static var sampleRace: Race { races[0] }` |
| `PreviewData.swift` | 273 | `static var sampleAthlete: Athlete { athletes[0] }` |
| `PreviewData.swift` | 277 | `static var sampleResult: RaceResult { races[0].results[0] }` |

**Recommendation:** Add bounds checks or use `.first` with optional handling.

---

## Error Handling Issues

### 3. Silent Error Suppression (`try?`)

Errors are silently swallowed, making debugging difficult and hiding real failures.

| File | Line | Code |
|------|------|------|
| `FISNetworkService.swift` | 64 | `try? await Task.sleep(nanoseconds: ...)` |
| `ViewModels.swift` | 109 | `try? await Task.sleep(...)` |
| `ViewModels.swift` | 267 | `try? await Task.sleep(nanoseconds: 15_000_000_000)` |
| `ViewModels.swift` | 435 | `try? await Task.sleep(nanoseconds: 300_000_000)` |
| `FISHTMLParser.swift` | 24 | `try? NSRegularExpression(...)` — throws on failure |
| `FISHTMLParser.swift` | 144 | `try? NSRegularExpression(...)` — returns empty array on failure |
| `FISHTMLParser.swift` | 226 | `try? NSRegularExpression(...)` — throws on failure |
| `FISHTMLParser.swift` | 420 | `try? NSRegularExpression(...)` — returns empty array on failure |
| `FISHTMLParser.swift` | 457 | `try? NSRegularExpression(...)` — returns nil on failure |

**Note:** The inconsistency is itself a problem — some paths throw errors, others
silently return empty data.

### 4. Incomplete Error Handling in Production

| File | Line(s) | Description |
|------|---------|-------------|
| `ViewModels.swift` | 68–71 | On fetch error, preview data is loaded only in `#if DEBUG`. In production, the user sees an empty state with no explanation. |

**Recommendation:** Surface a user-facing error message for all error paths.

---

## Incomplete Implementations & Dead Code

### 5. `skiBrand` Property Always Returns `nil`

**File:** `Models.swift:54–58`

```swift
var skiBrand: String? {
    // This would typically be fetched from athlete biography
    // Returning nil as placeholder
    nil
}
```

This makes every UI branch that checks `skiBrand` dead code:

| File | Line(s) | Dead UI Code |
|------|---------|--------------|
| `FavoritesView.swift` | 37–41 | Shows ski brand in favorites list — never executes |
| `RaceDetailView.swift` | 268–272 | Shows ski brand in race detail — never executes |

### 6. Unused Extracted Variable

**File:** `FISHTMLParser.swift:42`

```swift
_ = String(html[seasonRange]) // seasonCode extracted but not currently used
```

The season code is parsed from HTML then immediately discarded.

---

## Hard-Coded Values

### 7. Magic Numbers in Business Logic

| File | Line | Value | Purpose |
|------|------|-------|---------|
| `Models.swift` | 31 | `999.99` | Default FIS points when missing |
| `Models.swift` | 251 | `990` | Points filter threshold (inconsistent with 999.99) |
| `Models.swift` | 257 | `100.0` | Default penalty |
| `Models.swift` | 261 | `0.75` | Points multiplier |
| `Models.swift` | 576 | `50.0` | Default component A |

### 8. Magic Numbers in Timing & Configuration

| File | Line | Value | Purpose |
|------|------|-------|---------|
| `FISNetworkService.swift` | 42 | `0.5` sec | Minimum request interval (rate limit) |
| `FISNetworkService.swift` | 46 | `30` sec | HTTP request timeout |
| `ViewModels.swift` | 102 | `30` sec | Auto-refresh default interval |
| `ViewModels.swift` | 267 | `15` sec | Refresh sleep duration |
| `ViewModels.swift` | 435 | `300` ms | Search debounce time |

### 9. Magic Numbers in Preview / UI

| File | Line | Value | Purpose |
|------|------|-------|---------|
| `PreviewData.swift` | 125 | `65.50` | Hard-coded winner time |
| `PreviewData.swift` | 129 | `0.35`, `0.2` | Time variation values |
| `PreviewData.swift` | 146 | `5.0` | FIS penalty offset |
| `PreviewData.swift` | 147 | `100`, `8` | Cup points formula constants |
| `SettingsView.swift` | 10 | `"1.0.0"` | Version string (should use bundle version) |

**Recommendation:** Extract all magic numbers into named constants or a configuration
object.

---

## Problematic Logic & Potential Bugs

### 10. Complex String Index Calculations

The HTML parser performs complex, fragile string slicing with hard-coded offsets that
are difficult to verify and maintain.

| File | Line(s) | Offsets Used |
|------|---------|--------------|
| `FISHTMLParser.swift` | 90–95 | `-2000`, `+500` |
| `FISHTMLParser.swift` | 191–196 | `-1000`, `+300` |
| `FISHTMLParser.swift` | 313–316 | Complex `<tr>` scanning |

**Risk:** Off-by-one errors, boundary violations, and extreme fragility if HTML
structure changes.

### 11. SwiftUI State Mutation Bypass

**File:** `ViewModels.swift:209–225`

```swift
for i in 0..<results.count {
    results[i].fisPoints = FISPointsCalculator.calculateFISPoints(...)
}
```

Mutating array elements through index access bypasses SwiftUI's `@Published`
observation mechanism. The UI may not update to reflect the new values.

**File:** `ViewModels.swift:180`

```swift
race.results = results
```

Direct mutation of a potentially shared model object can cause race conditions with
SwiftUI rendering.

**Recommendation:** Replace the entire array to trigger SwiftUI observation:
`results = results.map { ... }`.

### 12. Inefficient Loop Operation

**File:** `RaceDetailView.swift:221`

```swift
if result.id != viewModel.race.results.last?.id {
    Divider()
}
```

`.last` is called on every iteration of the loop. While `.last` is O(1) on `Array`,
the repeated optional chain and comparison is better extracted to a local variable.

---

## Network & API Issues

### 13. Brittle HTML Parsing via Regex

The entire data layer depends on scraping FIS website HTML with regular expressions.
Any change to the FIS website structure will break parsing silently.

| File | Line | Pattern |
|------|------|---------|
| `FISHTMLParser.swift` | 22 | Event ID regex |
| `FISHTMLParser.swift` | 142 | Race ID regex |
| `FISHTMLParser.swift` | 224 | Competitor ID regex |

**Risk:** High — no official API fallback, no validation of parsed structure.

### 14. Hard-Coded User-Agent String

**File:** `FISNetworkService.swift:49`

```swift
"User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) ..."
```

This identifies as iOS 17.0 and will become outdated. Some servers block stale
User-Agent strings.

### 15. No Network Retry Logic

There is no retry mechanism for transient network failures anywhere in
`FISNetworkService.swift`. A single timeout or connection drop causes a complete
failure with no recovery attempt.

### 16. No Certificate Pinning

**File:** `FISNetworkService.swift:54`

The default `URLSession` configuration is used without certificate pinning, leaving
the app vulnerable to man-in-the-middle attacks on public WiFi networks.

---

## Code Quality & Maintainability

### 17. Excessive Debug Logging (`print()` statements)

Over 30 `print()` statements are scattered across the codebase. These should be
replaced with a proper logging framework (e.g., `os.Logger`).

| File | Approximate Count |
|------|-------------------|
| `FISNetworkService.swift` | 11 |
| `ViewModels.swift` | 22 |
| `FISHTMLParser.swift` | 8 |

### 18. Duplicated Season Code Calculation

The same season-code logic appears in three places:

| File | Line(s) |
|------|---------|
| `FISNetworkService.swift` | 76–79 |
| `FISNetworkService.swift` | 112–114 |
| `FISNetworkService.swift` | 540–548 |

```swift
let month = calendar.component(.month, from: now)
let year = calendar.component(.year, from: now)
let seasonCode = month >= 7 ? year + 1 : year
```

**Recommendation:** Extract to a single shared helper function.

### 19. Potential Memory Leak — Task Retention

**File:** `ViewModels.swift:14, 153, 417`

```swift
private var autoRefreshTask: Task<Void, Never>?
```

While cancellation is attempted, tasks could retain `self` through closures if
cancellation doesn't complete synchronously.

### 20. No Caching of Parsed Data

HTML is re-fetched and re-parsed on every request. There is no caching layer for
parsed race data, athlete data, or results — causing unnecessary network usage and
slower load times.

---

## Summary

| Category | Count | Severity |
|----------|-------|----------|
| Force Unwrapping (`!`) | 6 | **High** |
| Array Bounds Issues | 5 | **High** |
| Silent Error Suppression (`try?`) | 9 | **High** |
| Incomplete Error Handling | 1 | **High** |
| Dead Code / Incomplete Impl. | 4 | Medium |
| Hard-Coded Values (magic numbers) | 20+ | Medium |
| State Mutation Issues | 2 | Medium |
| Network Fragility | 4 | Medium |
| Duplicated Logic | 1 (3 locations) | Medium |
| Excessive Debug Logging | 30+ | Low |
| Memory / Performance | 3 | Low |
| **Total Identified Issues** | **80+** | |
