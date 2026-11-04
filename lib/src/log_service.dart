part of 'notification_service.dart';

class Log {
  static const int _defaultWidth = 120;

  Log({
    Function(String message)? i,
    Function(String message, {Object? error, StackTrace? stackTrace})? e,
    Function(String message)? w,
  }) {
    if (i != null) this.i = i;
    if (e != null) this.e = e;
    if (w != null) this.w = w;
  }

  Function(String message) i = (message) {
    _print(message, symbol: '💡', width: _defaultWidth);
  };
  Function(String message) w = (message) {
    _print(message, symbol: '⚠️', width: _defaultWidth);
  };
  Function(String message, {Object? error, StackTrace? stackTrace}) e =
      (message, {error, stackTrace}) {
        final fullMessage = StringBuffer(message);
        if (error != null) fullMessage.write('\nError: $error');
        if (stackTrace != null) fullMessage.write('\nStackTrace:\n$stackTrace');

        _print(fullMessage.toString(), symbol: '❌', width: _defaultWidth);
      };

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
      debugPrint('│ $symbol $line [Bellflow]');
    }
    debugPrint(bottomBorder);
  }
}
