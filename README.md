<!-- Created by Amirali Yazdani. -->

# Zipline

**A little path. A lot of logic.** A native SwiftUI number-path puzzle game by **Amirali Yazdani**.

Zipline is distributed as two independent iOS apps. Each edition has its own directory, native .xcodeproj, scheme, app entry point, source files, puzzle engine copy, and asset catalog. Source duplication is intentional so either edition can be opened and maintained independently without XcodeGen or a cross-project dependency.

| | Zipline Main | Zipline Classic |
|---|---|---|
| Project | Zipline Main/Zipline Main.xcodeproj | Zipline Classic/Zipline Classic.xcodeproj |
| Minimum iOS | 17.0 | 15.0 |
| Devices | iPhone and iPad | iPhone, including iPhone 6s |
| Appearance | Liquid Glass on iOS 26+; material fallback on iOS 17–25 | Native classic surfaces |
| Bundle ID | com.amiraliyazdani.zipline | com.amiraliyazdani.zipline.classic |

## Run in Xcode
1. Download or clone this repository on your Mac.
2. Open either .xcodeproj directly in Xcode.
3. Choose a supported iPhone simulator or device, select the matching scheme, and press Run (⌘R).

No XcodeGen or project generation step is required. Classic targets iOS 15 and supports iPhone 6s running iOS 15 or later.

## Features
- 4×4 through 8×8 boards with Easy, Medium, and Hard checkpoint layouts.
- Drag or tap adjacent cells while visiting numbered checkpoints in order.
- Guaranteed Hamiltonian solution for generated puzzles.
- Undo, reset, new puzzle, progress feedback, and contextual hints.
- System, Light, and Dark appearance settings.
- Haptics and Reduce Motion support.
- Offline by design: no account, tracking, ads, or network dependency.

## Layout
Zipline Main and Zipline Classic each contain their own .xcodeproj, App, Views, Models, and Assets.xcassets folders. The duplicated source files allow either app to evolve independently. Packages/ZiplineCore is retained as a test harness for CI and is not an app dependency.

## CI
GitHub Actions runs the puzzle engine tests and independently builds both Xcode projects for iOS Simulator using Xcode 26 on macOS 26.

## Inspiration
An independent implementation inspired by the general number-path puzzle format at [Zip Game Unlimited](https://www.zipgameunlimited.com/). Zipline is not affiliated with that website and does not reuse its branding or assets.

Created by **Amirali Yazdani**. MIT licensed; see LICENSE.
