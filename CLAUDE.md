# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**HuntTimer** (반려묘 사냥 놀이 타이머) — A data-driven iOS app for cat activity tracking and habit formation, targeting the veterinarian-recommended 75 minutes/day of hunting play.

- iOS 16.0+ | iPhone only | Portrait only | Light Mode optimized
- Bundle ID: `com.hyojung.HuntTimer`
- Xcode project: `HuntTimer/HuntTimer.xcodeproj`

## Build Commands

```bash
# Build (Debug)
xcodebuild -project HuntTimer/HuntTimer.xcodeproj -scheme HuntTimer -configuration Debug build

# Build (Release)
xcodebuild -project HuntTimer/HuntTimer.xcodeproj -scheme HuntTimer -configuration Release build

# Build for simulator
xcodebuild -project HuntTimer/HuntTimer.xcodeproj -scheme HuntTimer \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests (once a test target is added)
xcodebuild -project HuntTimer/HuntTimer.xcodeproj -scheme HuntTimer test \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

No test targets are currently configured. No CI/CD pipelines exist yet.

## Architecture

**MVVM with Input-Output Pattern** — ViewModels expose a `transform(input:)` method that maps an `Input` struct (user actions as Observables) to an `Output` struct (UI state as Observables). RxSwift drives all data binding.

**Atomic Design Pattern** for UI components (planned directory structure):
- `Atoms/` — Lowest-level: Color, Font, Button, Icon
- `Molecules/` — Composed: StatCard, Tag, Badge
- `Organisms/` — Complex: TimerBlock, Calendar, RecordList
- `Templates/Pages/` — Tab screens: Home, Play, Records, Profile, Shopping, Adoption

## Planned Tech Stack

The project skeleton is in place; dependencies have not yet been added via a package manager.

| Category | Libraries |
|---|---|
| Reactive | RxSwift |
| UI Frameworks | UIKit, SwiftUI (timer animations) |
| iOS Frameworks | ActivityKit (Live Activities), WidgetKit, UserNotifications |
| Database | Realm |
| Networking | Alamofire, Kingfisher |
| UI Libraries | FSCalendar, Charts, Toasts |
| External APIs | Naver Shopping API, 유기동물 정보 공공 API |

## Key Domain Rules

- Daily play goal: **75 minutes** (the core metric throughout the app)
- Timer flow: start timer first → match cat(s) and tag toy after session ends
- Achievement titles progress: 초보 낚시꾼 → 전설의 사냥꾼
- Sessions are stored in Realm with toy tag classification and optional photos
- Notifications are pattern-based (before activity, goal progress, achievement)
