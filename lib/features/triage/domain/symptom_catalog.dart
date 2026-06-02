import 'package:flutter/material.dart';
import 'package:repair_ai/localization/app_localizations.dart';

/// Canonical English keys used by [TriageRules]; UI shows localized labels.
class SymptomCatalog {
  static const List<String> canonicalKeys = [
    'Vaginal Bleeding',
    'Severe Abdominal Pain',
    'Cramping',
    'Dizziness / Fainting',
    'Fever',
    'Nausea & Vomiting',
    'Reduced Fetal Movement',
    'Spotting',
  ];

  static IconData iconFor(String key) {
    switch (key) {
      case 'Vaginal Bleeding':
        return Icons.bloodtype;
      case 'Severe Abdominal Pain':
        return Icons.medical_services;
      case 'Cramping':
        return Icons.accessibility_new;
      case 'Dizziness / Fainting':
        return Icons.sick;
      case 'Fever':
        return Icons.thermostat;
      case 'Nausea & Vomiting':
        return Icons.emoji_emotions;
      case 'Reduced Fetal Movement':
        return Icons.baby_changing_station;
      case 'Spotting':
        return Icons.water_drop;
      default:
        return Icons.healing;
    }
  }

  static String label(AppLocalizations l10n, String key) {
    switch (key) {
      case 'Vaginal Bleeding':
        return l10n.symptomBleeding;
      case 'Severe Abdominal Pain':
        return l10n.symptomSeverePain;
      case 'Cramping':
        return l10n.symptomCramping;
      case 'Dizziness / Fainting':
        return l10n.symptomDizziness;
      case 'Fever':
        return l10n.symptomFever;
      case 'Nausea & Vomiting':
        return l10n.symptomNausea;
      case 'Reduced Fetal Movement':
        return l10n.symptomReducedMovement;
      case 'Spotting':
        return l10n.symptomSpotting;
      default:
        return key;
    }
  }
}
