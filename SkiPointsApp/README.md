# SkiPoints

A native iOS app for calculating and tracking FIS (International Ski Federation) alpine skiing points in real-time during races.

## Features

- **Live Race Tracking** - See all ski races happening today with real-time updates
- **FIS Points Calculation** - Automatic calculation using official FIS formulas
- **Athlete Favorites** - Track your favorite skiers across races
- **Podium Display** - Visual podium view for completed races
- **Auto-Refresh** - Live races automatically update every 30 seconds
- **Clean Native UI** - Modern SwiftUI interface optimized for iOS

## Screenshots

The app features three main tabs:
- **Races** - Browse live, completed, and upcoming races
- **Favorites** - Quick access to your favorite athletes
- **Settings** - App info and FIS website link

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/SkiPointsApp.git
   ```

2. Open the project in Xcode:
   ```bash
   cd SkiPointsApp
   open SkiPointsApp.xcodeproj
   ```

3. Select your target device or simulator

4. Press `Cmd+R` to build and run

## Project Structure

```
SkiPointsApp/
├── SkiPointsApp.xcodeproj/     # Xcode project
└── SkiPointsApp/               # Source code
    ├── SkiPointsApp.swift      # App entry point
    ├── ContentView.swift       # Tab navigation
    ├── Models.swift            # Data models (Race, Athlete, etc.)
    ├── PreviewData.swift       # Sample data for previews
    ├── RaceListView.swift      # Main race list
    ├── RaceDetailView.swift    # Race details & results
    ├── FavoritesView.swift     # Favorite athletes
    ├── SettingsView.swift      # Settings
    ├── Services/
    │   ├── FISNetworkService.swift  # Network layer
    │   └── FISHTMLParser.swift      # HTML parsing
    ├── ViewModels/
    │   └── ViewModels.swift    # View models
    └── Assets.xcassets/        # App assets
```

## How It Works

### Data Source
The app fetches race data from the official FIS website (fis-ski.com) since no public API is available. HTML responses are parsed to extract race information, results, and athlete details.

### FIS Points Formula
Points are calculated using the official FIS formula:
```
Points = ((Race Time - Winner Time) / Winner Time) × F-Factor + Penalty
```

Where F-Factor varies by discipline:
- Downhill: 1330
- Super G: 1190
- Giant Slalom: 1010
- Slalom: 730

### Supported Race Types
- World Cup (WC)
- Europa Cup (EC)
- FIS Races

### Supported Disciplines
- Downhill (DH)
- Super G (SG)
- Giant Slalom (GS)
- Slalom (SL)

## Development

### Debug Mode
In DEBUG builds, the app falls back to preview data when network requests fail, enabling development without live FIS data.

### Key Technical Details
- Uses iOS Safari User-Agent for FIS compatibility
- Handles both UTF-8 and ISO-8859-1 encodings
- Implements rate limiting (0.5s between requests)
- Date format: dd.MM.yyyy (FIS requirement)

## Future Enhancements

- [ ] Persistent favorites storage
- [ ] Push notifications for live races
- [ ] Detailed athlete profiles
- [ ] Historical race data
- [ ] Widget support
- [ ] Additional FIS disciplines

## License

MIT License - See LICENSE file for details

## Author

Björn

## Acknowledgments

- Race data sourced from [FIS](https://www.fis-ski.com)
- Built with SwiftUI and modern Swift concurrency
