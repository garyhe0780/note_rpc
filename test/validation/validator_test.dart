import 'package:test/test.dart';
import 'package:grpc_note_server/validation/validator.dart';

void main() {
  group('StringValidator', () {
    test('validates string type', () {
      final validator = Z.string();

      expect(validator.validate('hello').isValid, isTrue);
      expect(validator.validate(123).isValid, isFalse);
      expect(validator.validate(null).isValid, isFalse);
    });

    test('validates min length', () {
      final validator = Z.string().min(5);

      expect(validator.validate('hello').isValid, isTrue);
      expect(validator.validate('hi').isValid, isFalse);
      expect(validator.validate('').isValid, isFalse);
    });

    test('validates max length', () {
      final validator = Z.string().max(5);

      expect(validator.validate('hello').isValid, isTrue);
      expect(validator.validate('hello world').isValid, isFalse);
    });

    test('validates min and max length', () {
      final validator = Z.string().min(3).max(10);

      expect(validator.validate('hello').isValid, isTrue);
      expect(validator.validate('hi').isValid, isFalse);
      expect(validator.validate('hello world').isValid, isFalse);
    });

    test('trims whitespace when configured', () {
      final validator = Z.string().trimmed().min(3);

      final result = validator.validate('  hello  ');
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello'));
    });

    test('validates regex pattern', () {
      final validator = Z.string().regex(
        RegExp(r'^\d+$'),
        'Must be digits only',
      );

      expect(validator.validate('123').isValid, isTrue);
      expect(validator.validate('abc').isValid, isFalse);

      final result = validator.validate('abc');
      expect(result.errors.first.message, contains('Must be digits only'));
    });

    test('validates allowed values', () {
      final validator = Z.string().oneOf(['red', 'green', 'blue']);

      expect(validator.validate('red').isValid, isTrue);
      expect(validator.validate('yellow').isValid, isFalse);
    });

    test('returns detailed error messages', () {
      final validator = Z.string().min(5).max(10);

      final result = validator.validate('hi');
      expect(result.isValid, isFalse);
      expect(result.errors.first.message, contains('at least 5 characters'));
    });

    test('parse throws on invalid input', () {
      final validator = Z.string().min(5);

      expect(() => validator.parse('hi'), throwsA(isA<ValidationException>()));
    });

    test('safeParse returns null on invalid input', () {
      final validator = Z.string().min(5);

      expect(validator.safeParse('hi'), isNull);
      expect(validator.safeParse('hello'), equals('hello'));
    });
  });

  group('NumberValidator', () {
    test('validates number type', () {
      final validator = Z.number();

      expect(validator.validate(123).isValid, isTrue);
      expect(validator.validate(123.45).isValid, isTrue);
      expect(validator.validate('123').isValid, isFalse);
    });

    test('validates minimum value', () {
      final validator = Z.number().minimum(10);

      expect(validator.validate(15).isValid, isTrue);
      expect(validator.validate(5).isValid, isFalse);
    });

    test('validates maximum value', () {
      final validator = Z.number().maximum(100);

      expect(validator.validate(50).isValid, isTrue);
      expect(validator.validate(150).isValid, isFalse);
    });

    test('validates integer type', () {
      final validator = Z.number().int();

      expect(validator.validate(123).isValid, isTrue);
      expect(validator.validate(123.45).isValid, isFalse);
    });

    test('validates range', () {
      final validator = Z.number().minimum(10).maximum(100);

      expect(validator.validate(50).isValid, isTrue);
      expect(validator.validate(5).isValid, isFalse);
      expect(validator.validate(150).isValid, isFalse);
    });
  });

  group('ValidationResult', () {
    test('isValid returns correct value', () {
      final success = const ValidationSuccess('hello');
      final failure = const ValidationFailure<String>([
        ValidationError(
          field: 'test',
          message: 'error',
          code: ValidationErrorCode.custom,
        ),
      ]);

      expect(success.isValid, isTrue);
      expect(failure.isValid, isFalse);
    });

    test('value returns data on success', () {
      final result = const ValidationSuccess('hello');
      expect(result.value, equals('hello'));
    });

    test('value throws on failure', () {
      final result = const ValidationFailure<String>([
        ValidationError(
          field: 'test',
          message: 'error',
          code: ValidationErrorCode.custom,
        ),
      ]);

      expect(() => result.value, throwsA(isA<ValidationException>()));
    });

    test('valueOrNull returns null on failure', () {
      final success = const ValidationSuccess('hello');
      final failure = const ValidationFailure<String>([
        ValidationError(
          field: 'test',
          message: 'error',
          code: ValidationErrorCode.custom,
        ),
      ]);

      expect(success.valueOrNull, equals('hello'));
      expect(failure.valueOrNull, isNull);
    });

    test('errors returns empty list on success', () {
      final result = const ValidationSuccess('hello');
      expect(result.errors, isEmpty);
    });

    test('errors returns error list on failure', () {
      final error = const ValidationError(
        field: 'test',
        message: 'error',
        code: ValidationErrorCode.custom,
      );
      final result = ValidationFailure<String>([error]);

      expect(result.errors, hasLength(1));
      expect(result.errors.first, equals(error));
    });
  });

  group('ValidationException', () {
    test('formats error message correctly', () {
      final exception = const ValidationException([
        ValidationError(
          field: 'title',
          message: 'Too short',
          code: ValidationErrorCode.tooShort,
        ),
        ValidationError(
          field: 'content',
          message: 'Too long',
          code: ValidationErrorCode.tooLong,
        ),
      ]);

      expect(exception.message, contains('title: Too short'));
      expect(exception.message, contains('content: Too long'));
    });
  });
}
