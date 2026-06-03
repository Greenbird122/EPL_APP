# REPAIR-AI

**Reproductive Early Pregnancy AI Response System** — Flutter app for Kenyan mothers: symptom reporting, explainable on-device triage (demo), and facility referral.

**Website:** [https://repairai.co.ke/](https://repairai.co.ke/) — *Smart Care. Better Outcomes.*

## Run locally

```bash
flutter pub get
flutter run
```

Chrome:

```bash
flutter run -d chrome
```

## Demo script

See [DEMO.md](DEMO.md) — includes **How it works** intro and link to the full platform.

## Mother journey

1. Onboarding (hero images) → **How it works** (optional) → Login (**Try demo**)
2. Home (tagline, trust chips, impact stats from platform story)
3. Triage → AI analyzing → Risk result (explainability + emergency CTA if high)
4. Referral (maps link) → My Reports (persisted locally)

## Tech stack

- Flutter 3.24+ / Dart 3.5+
- Riverpod, go_router
- Client-side triage rules (demo — not a medical device)
- English + Kiswahili
- Light / dark mode

## Tests & CI

```bash
flutter test
flutter analyze lib test
```

GitHub Actions: [.github/workflows/flutter.yml](.github/workflows/flutter.yml)

## Dependencies

Active packages are minimal for the hackathon build. See [DEPENDENCIES.md](DEPENDENCIES.md) for planned production packages (Isar, TFLite, GIS, API).

## Disclaimer

Demo logic only — **not** a medical diagnosis. Always seek professional care when concerned.

