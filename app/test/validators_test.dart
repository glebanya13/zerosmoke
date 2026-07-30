import 'package:flutter_test/flutter_test.dart';
import 'package:zerosmoke/core/utils/validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts common valid emails', () {
      expect(isValidEmail('a@b.co'), isTrue);
      expect(isValidEmail('user.name+tag@example.com'), isTrue);
    });

    test('rejects invalid emails', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('not-an-email'), isFalse);
      expect(isValidEmail('@x.com'), isFalse);
      expect(isValidEmail('a@'), isFalse);
    });
  });
}
