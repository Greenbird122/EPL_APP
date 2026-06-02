# REPAIR-AI — follow-ups (post-hackathon)

## Done in this pass

- Mother demo path: onboarding → how-it-works → login → triage → result → referral → history
- EN/SW localization sweep (onboarding, symptoms, mental health, language)
- Light/dark theme, auth guard, emergency CTAs, trimmed `pubspec.yaml`, CI workflow
- Site-aligned copy: tagline, trust chips, impact stats, [repairai.co.ke](https://repairai.co.ke/)

## Optional polish

- [ ] Add `docs/screenshots/` for README
- [ ] CHP `provider_dashboard.dart` visual pass (out of mother demo scope)
- [ ] Deeper visual match to marketing site (Phase 3)
- [ ] Record short demo video per `DEMO.md`

## Verify locally

```powershell
cd C:\Users\HomePC\Documents\repair_ai
flutter pub get
flutter analyze lib test
flutter test
flutter run
```
