# SkiPoints

A native iOS app for calculating and tracking FIS (International Ski Federation) alpine skiing points in real-time during races.

## Features

- **Live Race Tracking** — View races happening today with real-time status updates
- **FIS Points Calculator** — Official FIS formula implementation for accurate point calculations
- **Race Results** — Full results with times, rankings, and calculated points
- **Athlete Profiles** — Detailed athlete information with recent results
- **Favorites** — Track your favorite athletes across races

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### As a Swift Package

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SkiPoints", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter repository URL

### As an iOS App

1. Clone the repository
2. Open `Package.swift` in Xcode
3. Build and run on your device or simulator

## Project Structure

```
SkiPoints/
├── Package.swift
├── Sources/
│   └── SkiPoints/
│       ├── App/                    # App entry point
│       ├── Models/                 # Data models
│       │   ├── Athlete.swift
│       │   ├── Race.swift
│       │   ├── RaceResult.swift
│       │   └── Enums/
│       │       ├── Discipline.swift
│       │       ├── EventType.swift
│       │       ├── Gender.swift
│       │       ├── RaceStatus.swift
│       │       └── ResultStatus.swift
│       ├── Services/               # Business logic
│       │   └── FISPointsCalculator.swift
│       ├── Extensions/             # Helper extensions
│       │   ├── TimeInterval+RaceTime.swift
│       │   └── Color+SkiPoints.swift
│       ├── Preview/                # Sample data
│       │   └── PreviewData.swift
│       └── Views/                  # SwiftUI views
│           ├── Components/
│           │   ├── RaceRowView.swift
│           │   └── ResultRowView.swift
│           └── Screens/
│               ├── RaceListView.swift
│               ├── RaceDetailView.swift
│               └── AthleteProfileView.swift
└── Tests/
    └── SkiPointsTests/
        └── SkiPointsTests.swift
```

## Usage

### FIS Points Calculation

```swift
import SkiPoints

let calculator = FISPointsCalculator()
let points = calculator.calculatePoints(
    raceTime: 105.54,      // Athlete's time in seconds
    winnerTime: 105.19,    // Winner's time
    discipline: .superG
)
// Returns 3.96 — matches official FIS result ✓
```

### Working with Athletes

```swift
let athlete = Athlete(
    fisCode: "512269",
    firstName: "Marco",
    lastName: "ODERMATT",
    nation: "SUI",
    yearOfBirth: 1997,
    gender: .men,
    skiBrand: "Stoeckli"
)

print(athlete.fullName)    // "Marco ODERMATT"
print(athlete.flagEmoji)   // "🇨🇭"
print(athlete.age)         // Current age
```

### Time Formatting

```swift
let time: TimeInterval = 105.19
print(time.raceTimeFormatted)  // "1:45.19"

let diff: TimeInterval = 0.35
print(diff.diffFormatted)      // "+0.35"
```

## FIS Points Formula

The official FIS points formula:

```
Race Points = ((Race Time - Winner Time) / Winner Time) × F + Penalty
```

Where F (factor) varies by discipline:
- Downhill: 1330
- Super G: 1190
- Giant Slalom: 1010
- Slalom: 730

## Development Phases

- [x] **Phase 1** — Data validation and FIS scraping feasibility
- [x] **Phase 2.3** — Swift data models
- [x] **Phase 2.4** — Network layer (in progress)
- [x] **Phase 2.5** — Core UI
- [ ] **Phase 3** — Features (favorites, notifications)
- [ ] **Phase 4** — App Store submission

## Data Source

Race data is sourced from [fis-ski.com](https://www.fis-ski.com).

## License

MIT License - see LICENSE file for details.

## Author

Björn

---

*SkiPoints is not affiliated with FIS (International Ski Federation).*
