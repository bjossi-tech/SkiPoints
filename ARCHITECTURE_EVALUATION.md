# SkiPoints Architecture Evaluation

## Verdict: Fix, Don't Rewrite

The app's MVVM architecture, SwiftUI patterns, and service layer are sound.
The problems are fixable incrementally without starting over.

---

## Current Scorecard

| Area                | Score | Notes |
|---------------------|-------|-------|
| Architecture        | 8/10  | Clean MVVM, proper async/await, actor-based services |
| Code Quality        | 6/10  | Good patterns but inconsistent error recovery |
| State Management    | 8/10  | Combine + @Published, proper @MainActor usage |
| Testing             | 0/10  | No tests at all |
| HTML Parsing        | 4/10  | Fragile regex-based, no fallbacks, single point of failure |
| Performance         | 5/10  | No caching, regex re-compilation, no pagination |
| Security            | 5/10  | User-Agent spoofing, no input validation |
| Build/Deploy        | 3/10  | Manual Xcode builds only, no CI/CD |
| Accessibility       | 2/10  | No VoiceOver labels or dynamic type support |
| **Overall**         | **4.5/10** | **Functional but fragile** |

---

## Critical Issues to Fix (Priority Order)

### 1. Add Test Coverage (Impact: High)

**Why:** The core value of this app is FIS point calculations. Without tests,
every change risks breaking the math. The HTML parser is complex and untested.

**What to test first:**
- FIS point calculation formulas (unit tests)
- HTML parsing with saved HTML snapshots (unit tests)
- ViewModel state transitions (unit tests)
- Favorites persistence (integration tests)

**Effort:** Medium — the code is already well-structured for testing.

### 2. Add Caching Layer (Impact: High)

**Why:** Every race detail view re-fetches from FIS. No ETag/Last-Modified
headers, no local cache. This makes the app feel slow and puts unnecessary
load on FIS servers.

**What to do:**
- Add in-memory cache with TTL in FISNetworkService
- Cache race results for 30s (live) or indefinitely (completed)
- Store last-known results for offline fallback

**Effort:** Low — the actor-based service already has the right structure.

### 3. Harden HTML Parser (Impact: High)

**Why:** 20+ regex patterns match exact HTML structure from fis-ski.com.
Any website change breaks the app completely. There are no fallback paths.

**What to do:**
- Add graceful degradation when patterns don't match
- Return partial results instead of failing completely
- Log parse failures with specifics for debugging
- Consider SwiftSoup for more robust HTML parsing
- Save sample HTML for test fixtures

**Effort:** Medium.

### 4. Fix Known Bugs (Impact: Medium)

| Bug | Location | Fix |
|-----|----------|-----|
| Default birth year 1990 when parse fails | FISHTMLParser:274 | Return nil instead of fake data |
| Auto-refresh task accumulation | ViewModels.swift | Cancel previous task before starting new |
| Regex crash on unexpected input | FISHTMLParser | Add try/catch around regex operations |
| No bounds checking in result extraction | FISHTMLParser:312 | Guard against nil ranges |

### 5. Add CI/CD (Impact: Medium)

**What to do:**
- GitHub Actions workflow for building on PRs
- Run tests automatically
- SwiftLint for code style consistency
- Consider fastlane for future App Store deployment

### 6. Add Accessibility (Impact: Medium)

**What to do:**
- VoiceOver labels on all interactive elements
- Dynamic Type support
- Meaningful accessibility descriptions for race results
- Test with VoiceOver enabled

---

## What NOT to Change

- **MVVM architecture** — it's the right pattern for this app
- **SwiftUI + Combine** — modern, well-supported
- **Zero external dependencies** — keep this as long as practical
- **Actor-based network service** — proper concurrency model
- **Tab-based navigation** — standard iOS pattern for this use case

---

## Long-Term Considerations

### FIS Data Source
The biggest architectural risk is dependency on HTML scraping. Options:
1. **Contact FIS** about official API access
2. **Build a proxy server** that scrapes and provides a stable JSON API
3. **Improve parser resilience** with better fallbacks and monitoring

### Cloud Sync
Currently favorites are UserDefaults-only (lost on uninstall). Consider:
- CloudKit for iCloud sync (free, Apple-native)
- No need for a custom backend for this feature

### Monetization/Distribution
Before App Store submission:
- Add proper error states for all failure modes
- Implement crash reporting
- Add privacy policy (required by App Store)
- Test on multiple device sizes
