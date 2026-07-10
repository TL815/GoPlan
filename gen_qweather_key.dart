import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  // Use a fixed seed for deterministic key generation
  // This seed = SHA-256 of "goplan-qweather-2026"
  const seedBase64 = 'QmuPFrHaZ1RP8gT8jpHxzeriGHOK15K-IFm5v4ytanY';
  final seed = _decode64(seedBase64);

  // Derive Ed25519 key pair from seed
  final keyPair = await Ed25519().newKeyPairFromSeed(seed);
  final publicKey = await keyPair.extractPublicKey();
  final publicKeyBytes = publicKey.bytes;
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

  // Output private key (base64url)
  final pkB64 = base64Url.encode(privateKeyBytes);
  print('PRIVATE_KEY_BASE64=$pkB64');

  // Construct PEM public key (SPKI format)
  // Ed25519 OID: 1.3.101.112 → 06 03 2B 65 70
  final algorithmSeq = Uint8List.fromList([0x30, 0x05, 0x06, 0x03, 0x2B, 0x65, 0x70]);
  final bitString = Uint8List.fromList([0x03, 0x21, 0x00, ...publicKeyBytes]);
  final derBytes = Uint8List.fromList([
    0x30,
    algorithmSeq.length + bitString.length,
    ...algorithmSeq,
    ...bitString,
  ]);
  final pkStandardB64 = base64.encode(derBytes);
  final pem = '-----BEGIN PUBLIC KEY-----\n$pkStandardB64\n-----END PUBLIC KEY-----';
  print('PUBLIC_KEY_PEM=$pem');

  // Verify
  final header = _b64url(jsonEncode({'alg': 'EdDSA', 'kid': 'T4WMKRC36F'}));
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final payload = _b64url(jsonEncode({
    'sub': 'T4WMKRC36F',
    'iat': now,
    'exp': now + 86400,
  }));
  final sig = await Ed25519().signString(
    '$header.$payload',
    keyPair: keyPair,
  );
  final sigB64 = _b64urlBytes(sig.bytes);
  print('JWT_TEST=$header.$payload.$sigB64');
  final valid = await Ed25519().verifyString('$header.$payload', signature: sig);
  print('VERIFY=${valid ? 'PASS' : 'FAIL'}');
}

String _b64url(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');
String _b64urlBytes(List<int> b) => base64Url.encode(b).replaceAll('=', '');

List<int> _decode64(String s) {
  final pad = s.padRight((s.length + 3) ~/ 4 * 4, '=');
  return base64Url.decode(pad);
}
