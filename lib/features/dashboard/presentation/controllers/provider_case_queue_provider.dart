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

class ProviderQueueCase {
  const ProviderQueueCase({
    required this.id,
    required this.name,
    required this.area,
    required this.meta,
    required this.symptoms,
    required this.risk,
    required this.referralStatus,
    required this.lastUpdate,
  });

  final String id;
  final String name;
  final String area;
  final String meta;
  final String symptoms;
  final ProviderCaseRisk risk;
  final ProviderReferralStatus referralStatus;
  final String lastUpdate;
}

final providerCaseQueueProvider = Provider<List<ProviderQueueCase>>((ref) {
  return const [
    ProviderQueueCase(
      id: 'mary-a',
      name: 'Mary A.',
      area: 'Bungoma',
      meta: '28 years • 32 weeks',
      symptoms: 'Bleeding + severe pain',
      risk: ProviderCaseRisk.high,
      referralStatus: ProviderReferralStatus.sent,
      lastUpdate: '2 hours ago',
    ),
    ProviderQueueCase(
      id: 'fatuma-k',
      name: 'Fatuma K.',
      area: 'Webuye',
      meta: '34 years • 24 weeks',
      symptoms: 'Cramping',
      risk: ProviderCaseRisk.moderate,
      referralStatus: ProviderReferralStatus.pending,
      lastUpdate: 'Yesterday',
    ),
    ProviderQueueCase(
      id: 'achieng-o',
      name: 'Achieng O.',
      area: 'Kimilili',
      meta: '22 years • 18 weeks',
      symptoms: 'Nausea',
      risk: ProviderCaseRisk.low,
      referralStatus: ProviderReferralStatus.reached,
      lastUpdate: 'Today',
    ),
  ];
});
