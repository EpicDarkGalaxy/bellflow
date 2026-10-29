part of 'notification_service.dart';

class Log {
  static const int _defaultWidth = 120;

  static void i(
    String message, {
    String symbol = '💡',
    int width = _defaultWidth,
  }) {
    _print(message, symbol: symbol, width: width);
  }

  static void w(
    String message, {
    String symbol = '⚠️',
    int width = _defaultWidth,
  }) {
    _print(message, symbol: symbol, width: width);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String symbol = '❌',
    int width = _defaultWidth,
  }) {
    final fullMessage = StringBuffer(message);
    if (error != null) fullMessage.write('\nError: $error');
    if (stackTrace != null) fullMessage.write('\nStackTrace:\n$stackTrace');

    _print(fullMessage.toString(), symbol: symbol, width: width);
  }

  static void _print(
    String message, {
    required String symbol,
    required int width,
  }) {
    if (!kDebugMode) return;

    final topBorder = '┌${'─' * (width - 1)}';
    final bottomBorder = '└${'─' * (width - 1)}';

    debugPrint(topBorder);
    for (final line in message.split('\n')) {
      debugPrint('│ $symbol $line [Notification Service]');
    }
    debugPrint(bottomBorder);
  }
}
