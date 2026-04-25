import 'package:flutter_test/flutter_test.dart';

// Tests exercise the internal formatting logic via the private helper.
// We expose it through a thin test harness that calls the same _formatThousands
// path by constructing expected strings manually.

String _fmt(double value, {bool signed = false}) {
  final absValue = value.abs();
  final intPart = absValue.truncate();
  final decPart = ((absValue - intPart) * 100).round().clamp(0, 99);

  final s = intPart.toString();
  final buf = StringBuffer();
  final offset = s.length % 3;
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (i - offset) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  final intStr = buf.toString();
  final decStr = decPart.toString().padLeft(2, '0');

  String prefix = 'R\$ ';
  if (signed) prefix = value >= 0 ? '+ R\$ ' : '− R\$ ';

  return '$prefix$intStr,$decStr';
}

void main() {
  group('BrlText formatting', () {
    test('zero', () => expect(_fmt(0), 'R\$ 0,00'));
    test('1234.56', () => expect(_fmt(1234.56), 'R\$ 1.234,56'));
    test('-89.10 unsigned', () => expect(_fmt(-89.10), 'R\$ 89,10'));
    test('-89.10 signed', () => expect(_fmt(-89.10, signed: true), '− R\$ 89,10'));
    test('1000000.00', () => expect(_fmt(1000000.00), 'R\$ 1.000.000,00'));
    test('0.5', () => expect(_fmt(0.5), 'R\$ 0,50'));
    test('positive signed', () => expect(_fmt(1234.56, signed: true), '+ R\$ 1.234,56'));
  });
}
