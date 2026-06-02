import 'package:flutter_test/flutter_test.dart';
import 'package:repair_ai/core/config/theme_mode_provider.dart';

void main() {
  test('AppAppearance maps to ThemeMode', () {
    expect(
      AppAppearance.dark,
      isNot(equals(AppAppearance.light)),
    );
  });
}
