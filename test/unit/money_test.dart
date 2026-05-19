import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/domain/value_objects/money.dart';

void main() {
  group('Money arithmetic', () {
    test('addition', () {
      expect(Money.fromDouble(100.00) + Money.fromDouble(50.50),
          Money.fromDouble(150.50));
    });

    test('subtraction', () {
      expect(Money.fromDouble(100.00) - Money.fromDouble(30.00),
          Money.fromDouble(70.00));
    });

    test('multiplication', () {
      expect(Money.fromDouble(10.00) * 3, Money.fromDouble(30.00));
    });

    test('no floating point error: 0.1 + 0.2 == 0.3', () {
      expect(
          Money.fromDouble(0.1) + Money.fromDouble(0.2), Money.fromDouble(0.3));
    });

    test('negation', () {
      expect(-Money.fromDouble(50.00), Money.fromDouble(-50.00));
    });
  });

  group('Money comparisons', () {
    test('greater than', () {
      expect(Money.fromDouble(100) > Money.fromDouble(50), isTrue);
    });

    test('less than', () {
      expect(Money.fromDouble(10) < Money.fromDouble(20), isTrue);
    });

    test('equality', () {
      expect(Money.fromDouble(42.00), Money.fromDouble(42.00));
      expect(Money.fromCents(4200), Money.fromDouble(42.00));
    });
  });

  group('Money properties', () {
    test('zero', () {
      expect(Money.zero.isZero, isTrue);
      expect(Money.fromDouble(0).isZero, isTrue);
    });

    test('isNegative', () {
      expect(Money.fromDouble(-1).isNegative, isTrue);
      expect(Money.fromDouble(1).isNegative, isFalse);
    });

    test('isPositive', () {
      expect(Money.fromDouble(1).isPositive, isTrue);
      expect(Money.fromDouble(-1).isPositive, isFalse);
    });

    test('cents round-trip', () {
      expect(Money.fromCents(1234).cents, 1234);
      expect(Money.fromDouble(12.34).cents, 1234);
    });
  });
}
