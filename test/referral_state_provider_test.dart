import 'package:flutter_test/flutter_test.dart';
import 'package:repair_ai/features/referral/presentation/controllers/referral_state_provider.dart';

void main() {
  group('ReferralStateNotifier', () {
    test('advances through company referral states', () {
      final notifier = ReferralStateNotifier();

      expect(notifier.state.status, ReferralUiStatus.recommended);

      notifier.send();
      expect(notifier.state.status, ReferralUiStatus.sent);

      notifier.accept();
      expect(notifier.state.status, ReferralUiStatus.accepted);

      notifier.complete();
      expect(notifier.state.status, ReferralUiStatus.completed);
    });

    test('selecting another facility returns to recommended state', () {
      final notifier = ReferralStateNotifier()..send();

      notifier.selectFacility(1);

      expect(notifier.state.selectedFacility, 1);
      expect(notifier.state.status, ReferralUiStatus.recommended);
    });
  });
}
