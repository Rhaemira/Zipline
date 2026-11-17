#!/usr/bin/env bash
#
#  verify-repository.sh
#  Zipline
#
#  Created by Amirali Yazdani.
#
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

main_engine="Zipline Main/Zipline Main/Models/ZipPuzzle.swift"
classic_engine="Zipline Classic/Zipline Classic/Models/ZipPuzzle.swift"
core_engine="Packages/ZiplineCore/Sources/ZiplineCore/ZipPuzzle.swift"
main_view="Zipline Main/Zipline Main/Views/ZiplineHomeView.swift"
classic_view="Zipline Classic/Zipline Classic/Views/ZiplineHomeView.swift"

for file in "$main_engine" "$classic_engine" "$core_engine" "$main_view" "$classic_view"; do
    [[ -f "$file" ]] || { echo "Missing required source: $file" >&2; exit 1; }
done

cmp -s "$core_engine" "$main_engine" || { echo "Main puzzle engine differs from the tested core engine." >&2; exit 1; }
cmp -s "$core_engine" "$classic_engine" || { echo "Classic puzzle engine differs from the tested core engine." >&2; exit 1; }
cmp -s "$main_view" "$classic_view" || { echo "Main and Classic game views have drifted." >&2; exit 1; }

while IFS= read -r -d '' file; do
    if ! head -n 10 "$file" | grep -q "Created by Amirali Yazdani"; then
        echo "Missing author header: $file" >&2
        exit 1
    fi
done < <(git ls-files -z '*.swift' '*.pbxproj' '*.xcscheme' '*.yml' '*.md' '.gitignore')

while IFS= read -r -d '' file; do
    python3 -m json.tool "$file" >/dev/null
done < <(find . -name Contents.json -print0)

grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 17.0' "Zipline Main/Zipline Main.xcodeproj/project.pbxproj"
grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 15.0' "Zipline Classic/Zipline Classic.xcodeproj/project.pbxproj"

python3 - <<'PY'
import struct
from pathlib import Path

icons = [
    Path("Zipline Main/Zipline Main/Assets.xcassets/AppIcon.appiconset/AppIcon.png"),
    Path("Zipline Classic/Zipline Classic/Assets.xcassets/AppIcon.appiconset/AppIcon.png"),
]
for icon in icons:
    with icon.open("rb") as file:
        header = file.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"Invalid PNG app icon: {icon}")
    width, height = struct.unpack(">II", header[16:24])
    if (width, height) != (1024, 1024):
        raise SystemExit(f"App icon must be 1024x1024: {icon} is {width}x{height}")
print("Repository structure, source parity, author headers, JSON, deployment targets, and app icons verified.")
PY
