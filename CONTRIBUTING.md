<!-- Created by Amirali Yazdani. -->

# Contributing

## Project structure

- Keep the canonical puzzle rules and tests in `Packages/ZiplineCore`.
- The Main and Classic Xcode projects intentionally carry independent copies of `ZipPuzzle.swift`. When changing game logic, update both copies and verify that all three engine files are identical.
- Keep every file in **Zipline Classic** compatible with iOS 15. Put newer APIs only in **Zipline Main**, or guard them with availability checks.

## Before opening a pull request

Run the engine tests:

```sh
swift test --package-path Packages/ZiplineCore
```

Build each app independently:

```sh
xcodebuild -project 'Zipline Main/Zipline Main.xcodeproj' -scheme 'Zipline Main' -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project 'Zipline Classic/Zipline Classic.xcodeproj' -scheme 'Zipline Classic' -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Add or update tests for every game-rule change. Keep the `Created by Amirali Yazdani` header on source and configuration files where the file format supports comments; do not add comments to strict JSON or binary assets.
