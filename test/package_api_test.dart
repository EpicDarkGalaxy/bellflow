import 'package:flutter_test/flutter_test.dart';
import 'package:bellflow/bellflow.dart';

void main() {
  test('NotificationService exposes a singleton instance', () {
    expect(identical(NotificationService(), NotificationService()), isTrue);
  });
}
