enum ConversationStoreFailureType {
  invalidData,
  unsupportedVersion,
  readFailed,
  writeFailed,
  unknown,
}

class ConversationStoreException implements Exception {
  const ConversationStoreException({
    required this.type,
    required this.message,
    this.cause,
  });

  final ConversationStoreFailureType type;
  final String message;
  final Object? cause;

  @override
  String toString() {
    return 'ConversationStoreException(type: $type, message: $message)';
  }
}
