import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CareStepType { report, referral, support, followUp }

enum FollowUpStatus { unknown, reachedCare, notYet, needsHelp }

class CareJourneyNotifier extends StateNotifier<FollowUpStatus> {
  CareJourneyNotifier() : super(FollowUpStatus.unknown) {
    _load();
  }

  static const _storageKey = 'care_follow_up_status';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    state = FollowUpStatus.values.firstWhere(
      (status) => status.name == stored,
      orElse: () => FollowUpStatus.unknown,
    );
  }

  Future<void> setFollowUpStatus(FollowUpStatus status) async {
    state = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, status.name);
  }
}

final careJourneyProvider =
    StateNotifierProvider<CareJourneyNotifier, FollowUpStatus>((ref) {
      return CareJourneyNotifier();
    });
