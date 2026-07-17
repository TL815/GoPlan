import 'dart:math';

abstract interface class LocalConversationIdGenerator {
  String generate();
}

class SecureLocalConversationIdGenerator
    implements LocalConversationIdGenerator {
  SecureLocalConversationIdGenerator({DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _now;
  final Random _random;

  @override
  String generate() {
    final timestamp = _now().microsecondsSinceEpoch;
    final randomHex = List<String>.generate(
      4,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      growable: false,
    ).join();
    return 'goplan_conv_${timestamp}_$randomHex';
  }
}
