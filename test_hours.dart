import 'package:intl/intl.dart';

void main() {
  final s = Duration(hours: 10, minutes: 0);
  final e = Duration(hours: 18, minutes: 30);
  final b = 30;
  final diff = e.inMinutes - s.inMinutes - b;
  print("Computed: \${diff / 60.0}");
}
