import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sample Tests', () {
    test('Basic math test', () {
      expect(2 + 2, equals(4));
    });

    test('String manipulation', () {
      expect('ConnexUS'.toLowerCase(), equals('connexus'));
    });
  });
}
