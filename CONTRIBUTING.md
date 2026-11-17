<!-- Created by Amirali Yazdani. -->

# Contributing

1. Keep puzzle rules in \`Packages/ZiplineCore\` rather than duplicating them in UI code.
2. Add or update unit tests for every game-rule change.
3. Preserve iOS 15 compatibility in \`Sources/Shared\`; newer-only APIs belong behind availability checks or in the modern target.
4. Run \`swift test --package-path Packages/ZiplineCore\` and build both XcodeGen schemes before opening a pull request.
5. Keep the \`Created by Amirali Yazdani\` header on every newly created source/configuration file where a header is appropriate.