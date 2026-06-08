import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('appRouter includes key routes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    final paths = <String>[];

    void collect(RouteBase route) {
      if (route is GoRoute) {
        paths.add(route.path);
      }
    }

    for (final route in router.configuration.routes) {
      collect(route);
    }

    expect(paths, contains('/splash'));
    expect(paths, contains('/auth'));
    expect(paths, contains('/auth/sign-in'));
    expect(paths, contains('/auth/chp'));
    expect(paths, contains('/auth/create-account'));
    expect(paths, contains('/auth/recover'));
    expect(paths, contains('/login/transition'));
    expect(paths, contains('/how-it-works'));
    expect(paths, contains('/triage/analyzing'));
    expect(paths, contains('/triage/risk-result'));
    expect(paths, contains('/triage/symptom-report'));
    expect(paths, contains('/medication-tracking'));
  });

  test('route helpers separate public patient and provider routes', () {
    expect(isPublicRoute('/auth'), isTrue);
    expect(isPublicRoute('/auth/chp'), isTrue);
    expect(isPublicRoute('/medication-tracking'), isFalse);
    expect(isSharedProtectedRoute('/medication-tracking'), isTrue);
    expect(isPatientRoute('/'), isTrue);
    expect(isPatientRoute('/referral'), isTrue);
    expect(isPatientRoute('/dashboard/provider'), isFalse);
    expect(isProviderRoute('/dashboard/provider'), isTrue);
    expect(isProviderRoute('/'), isFalse);
  });
}
