# SkiPoints iOS App

A native iOS app for calculating and tracking FIS (International Ski Federation) alpine skiing points in real-time during races.

## Features

- Real-time race data from FIS website
- Live FIS points calculations using official formulas
- Athlete favorites tracking
- Auto-refresh for live races
- Clean SwiftUI interface

## Project Structure

```
SkiPointsApp/
├── SkiPointsApp.xcodeproj/          # Xcode project file
└── SkiPointsApp/                    # Main app source
    ├── SkiPointsApp.swift           # App entry point
    ├── ContentView.swift            # Tab navigation
    ├── Models.swift                 # Data models
    ├── PreviewData.swift            # Sample data for previews
    ├── RaceListView.swift           # Main race list view
    ├── RaceDetailView.swift         # Race details with results
    ├── FavoritesView.swift          # Favorite athletes view
    ├── SettingsView.swift           # Settings view
    ├── Services/                    # Network layer
    │   ├── FISNetworkService.swift  # Network service (CORRECTED)
    │   └── FISHTMLParser.swift      # HTML parser (CORRECTED)
    ├── ViewModels/                  # View models
    │   └── ViewModels.swift         # All view models (CORRECTED)
    └── Assets.xcassets/             # App assets
```

## Key Files with CORRECTIONS

### FISNetworkService.swift ✅
- **Fixed User-Agent**: Now uses proper iOS Safari user agent
- **Fixed Date Format**: Uses dd.MM.yyyy format expected by FIS
- Includes proper rate limiting and error handling

### FISHTMLParser.swift ✅
- Enhanced event parsing from calendar HTML
- Improved location extraction with fallbacks
- Better discipline, gender, and status detection

### ViewModels.swift ✅
- Added console logging for debugging
- Falls back to preview data in DEBUG builds
- Proper error handling and state management

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Open `SkiPointsApp.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

## Development Notes

- The app uses web scraping since FIS doesn't provide a public API
- HTML parsing patterns may need updates if FIS changes their website structure
- Preview data is used as fallback during development
- The User-Agent header is critical for successful FIS website access

## Next Steps

- Test with real FIS race data
- Add persistent favorites storage (UserDefaults)
- Implement push notifications for live races
- Add more detailed athlete profiles
- Expand to include more FIS disciplines

## Author

Björn
