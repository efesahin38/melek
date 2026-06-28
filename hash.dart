import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final bytes = utf8.encode('Admin1234');
  final digest = sha256.convert(bytes);
  print(digest.toString());
}
