import 'dart:async';

Future<T?> runWithTimeout<T>(
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  try {
    return await action().timeout(timeout);
  } on TimeoutException {
    return null;
  } catch (_) {
    return null;
  }
}

Future<T> runWithMinimumDuration<T>(
  Future<T> Function() action, {
  Duration minimum = const Duration(seconds: 5),
}) async {
  final results = await Future.wait([action(), Future<void>.delayed(minimum)]);
  return results.first as T;
}
