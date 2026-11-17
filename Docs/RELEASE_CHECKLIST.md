<!-- Created by Amirali Yazdani. -->

# Release checklist

- [ ] CI passes on \`main\` for both app schemes and core tests.
- [ ] Install and manually test Zipline on an iOS 17+ simulator.
- [ ] Install and manually test Zipline Classic on an iOS 15 simulator and physical iPhone 6s.
- [ ] Verify VoiceOver labels, dynamic text sizing, touch target sizing, and light/dark appearance.
- [ ] Add screenshots for both editions.
- [ ] Archive and sign each app with the intended Apple Developer team.
- [ ] Create version tags and GitHub releases after device validation.

The repository's CI build is not a substitute for signing, App Store validation, or physical-device QA.