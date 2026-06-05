import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProviderCaseRisk {
  high,
  moderate,
  low,
}

enum ProviderReferralStatus {
  sent,
  pending,
  reached,
}

enum ProviderTaskType {
  referralFollowUp,
  dangerSignFollowUp,
  medicationCheckIn,
}

enum ProviderFollowUpStatus {
  dueToday,
  overdue,
  completed,
}

class ProviderQueueCase {
  const ProviderQueueCase({
    required this.id,
    required this.name,
    required this.area,
    this.ageYears,
    this.pregnancyWeeks,
    this.dateOfBirth,
    required this.symptoms,
    required this.risk,
    required this.referralStatus,
    required this.lastUpdate,
    required this.dueLabel,
    required this.lastContact,
    required this.medicationStatus,
    required this.taskType,
    required this.followUpStatus,
  });

  final String id;
  final String name;
  final String area;
  final int? ageYears;
  final int? pregnancyWeeks;
  final DateTime? dateOfBirth;
  final String symptoms;
  final ProviderCaseRisk risk;
  final ProviderReferralStatus referralStatus;
  final String lastUpdate;
  final String dueLabel;
  final String lastContact;
  final String medicationStatus;
  final ProviderTaskType taskType;
  final ProviderFollowUpStatus followUpStatus;

  int? get effectiveAgeYears {
    final dob = dateOfBirth;
    if (dob == null) return ageYears;

    final now = DateTime.now();
    var years = now.year - dob.year;
    final birthdayThisYear = DateTime(now.year, dob.month, dob.day);
    if (now.isBefore(birthdayThisYear)) years -= 1;
    return years;
  }

  String get clinicalContextLabel {
    final parts = <String>[];
    final age = effectiveAgeYears;
    if (age != null) parts.add('$age years');
    if (pregnancyWeeks != null) parts.add('$pregnancyWeeks weeks');
    return parts.isEmpty ? 'Profile pending' : parts.join(' • ');
  }
}

final providerCaseQueueProvider = Provider<List<ProviderQueueCase>>((ref) {
  return const [
    ProviderQueueCase(
      id: 'mary-a',
      name: 'Mary A.',
      area: 'Bungoma',
      ageYears: 28,
      pregnancyWeeks: 32,
      symptoms: 'Bleeding + severe pain',
      risk: ProviderCaseRisk.high,
      referralStatus: ProviderReferralStatus.sent,
      lastUpdate: '2 hours ago',
      dueLabel: 'Overdue',
      lastContact: 'Not reached today',
      medicationStatus: 'Iron + folate pending review',
      taskType: ProviderTaskType.dangerSignFollowUp,
      followUpStatus: ProviderFollowUpStatus.overdue,
    ),
    ProviderQueueCase(
      id: 'fatuma-k',
      name: 'Fatuma K.',
      area: 'Webuye',
      ageYears: 34,
      pregnancyWeeks: 24,
      symptoms: 'Cramping',
      risk: ProviderCaseRisk.moderate,
      referralStatus: ProviderReferralStatus.pending,
      lastUpdate: 'Yesterday',
      dueLabel: 'Due today',
      lastContact: 'Called yesterday',
      medicationStatus: 'Supplements registered',
      taskType: ProviderTaskType.medicationCheckIn,
      followUpStatus: ProviderFollowUpStatus.dueToday,
    ),
    ProviderQueueCase(
      id: 'achieng-o',
      name: 'Achieng O.',
      area: 'Kimilili',
      ageYears: 22,
      pregnancyWeeks: 18,
      symptoms: 'Nausea',
      risk: ProviderCaseRisk.low,
      referralStatus: ProviderReferralStatus.reached,
      lastUpdate: 'Today',
      dueLabel: 'Completed',
      lastContact: 'Reached today',
      medicationStatus: 'No active prescription',
      taskType: ProviderTaskType.referralFollowUp,
      followUpStatus: ProviderFollowUpStatus.completed,
    ),
  ];
});
