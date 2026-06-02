# Dependencies note

The mobile hackathon build uses a **minimal** `pubspec.yaml`. Packages listed below were removed from active use but remain planned for production (see [repairai.co.ke](https://repairai.co.ke/)):

| Package | Planned use |
|---------|-------------|
| `isar` | Offline structured storage |
| `tflite_flutter` | On-device clinical model |
| `dio` | Backend API |
| `geolocator` / maps | GIS smart referrals |
| `workmanager` / `connectivity_plus` | Background sync |

Re-add when implementing backend or GIS features.
