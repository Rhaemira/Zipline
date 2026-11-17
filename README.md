<!-- Created by Amirali Yazdani. -->

# Zipline

**A little path. A lot of logic.** A polished, native SwiftUI number-path puzzle game by **Amirali Yazdani**.

Zipline is published as two deliberately distinct iOS editions. They share the same platform-independent puzzle engine, but have separate app targets, entry points, asset catalogs, deployment targets, and release artifacts.

## Choose your edition

| | **Zipline — Main Edition** | **Zipline Classic — iOS 15 Edition** |
|---|---|---|
| Xcode scheme | \`Zipline\` | \`ZiplineClassic\` |
| Product name | Zipline | Zipline Classic |
| Bundle ID | \`com.amiraliyazdani.zipline\` | \`com.amiraliyazdani.zipline.classic\` |
| Minimum iOS | **17.0** | **15.0** |
| Devices | iPhone and iPad | iPhone (including iPhone 6s) |
| Visual treatment | Liquid Glass on iOS 26+ | Classic native materials; no Liquid Glass APIs |
| App icon | \`Resources/Modern.xcassets\` | \`Resources/Legacy.xcassets\` |
| Entry point | \`Sources/ModernApp\` | \`Sources/LegacyApp\` |

Choose Main for iOS 17 or later. Choose Classic for iOS 15/16 devices and specifically for iPhone 6s. Classic is a separate target with its own bundle identifier and iPhone-only device family.

## Experience

- Focused puzzle board with generous spacing, rounded cells, numbered checkpoints, and live progress.
- Drag across the board or tap adjacent cells; step backwards, undo, or reset.
- Fresh generated challenges from 4×4 through 8×8 with Easy, Medium, and Hard checkpoint layouts.
- System, Light, and Dark modes, remembered independently by each installed edition.
- Subtle selection, impact, and completion haptics where supported.
- Respects Reduce Motion and provides descriptive labels for puzzle cells.
- Offline by design: no account, tracking, ads, or network dependency.

### Main Edition: Liquid Glass

Main opts into Apple's native Liquid Glass material on **iOS 26 or later**. On iOS 17–25 it gracefully falls back to system materials.

### Classic Edition: iPhone 6s

Classic has an iOS 15.0 deployment target, an iPhone-only device family, and does not opt into Liquid Glass. It uses adaptive system colors and native materials for older hardware.

## Rules

1. Start on checkpoint **1**.
2. Move one cell at a time, horizontally or vertically. No diagonal moves.
3. Visit numbered checkpoints in ascending order.
4. Never visit a cell twice.
5. Fill every cell exactly once and finish on the final checkpoint.

## Build

Requirements: macOS, Xcode 26 (for Liquid Glass SDK symbols), and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

\`\`\`bash
brew install xcodegen
xcodegen generate

# Main Edition (iOS 17+)
xcodebuild -project Zipline.xcodeproj -scheme Zipline \\
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

# Classic Edition (iOS 15+, iPhone)
xcodebuild -project Zipline.xcodeproj -scheme ZiplineClassic \\
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

swift test --package-path Packages/ZiplineCore
\`\`\`

For iPhone 6s, use an iOS 15 simulator runtime or a physical device running iOS 15 and a correctly signed build. Simulator compilation alone does not certify physical-device installation.

## Repository layout

\`\`\`text
Sources/
  ModernApp/                 Main Edition app entry point
  LegacyApp/                  iOS 15 Classic app entry point
  Shared/                     Shared SwiftUI game interface and adaptive style
Packages/ZiplineCore/         Platform-independent puzzle engine and tests
Resources/
  Modern.xcassets/            Main Edition app icon
  Legacy.xcassets/             Classic Edition app icon
.github/workflows/ci.yml      Independent builds + core tests
project.yml                  XcodeGen project and target definitions
Docs/                         Release checklist
\`\`\`

The targets share \`ZiplineHomeView\` and \`ZiplineCore\` to keep game behavior consistent. The \`modernExperience\` configuration enables the iOS 26 Liquid Glass enhancement only for Main; availability checks preserve its iOS 17 minimum. Classic uses the non-glass native surface style.

## Continuous integration

GitHub Actions runs shared puzzle-engine unit tests and independent simulator builds of Main and Classic. The workflow uses Xcode 26 on macOS 26 so Liquid Glass is available at compile time. Simulator builds disable code signing. CI verifies compilation and tests; it does not perform App Store signing or physical-device installation.

## Inspiration and credits

An independent implementation inspired by the number-path puzzle format and configurable practice experience at [Zip Game Unlimited](https://www.zipgameunlimited.com/). Zipline is not affiliated with that website and does not reuse its branding or assets.

Created by **Amirali Yazdani**.

## License

MIT. See [LICENSE](LICENSE).