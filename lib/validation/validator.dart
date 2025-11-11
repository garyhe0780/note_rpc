/// Validation framework inspired by Zod (TypeScript)
/// Provides fluent API for schema validation with detailed error messages.
library;

/// Error codes for validation failures.
enum ValidationErrorCode {
  /// Invalid type (e.g., expected string, got number)
  invalidType,

  /// Value is too short (string length, array length)
  tooShort,

  /// Value is too long (string length, array length)
  tooLong,

  /// Value is too small (number)
  tooSmall,

  /// Value is too large (number)
  tooLarge,

  /// Value doesn't match required pattern (regex)
  invalidFormat,

  /// Value is not in allowed list
  invalidEnum,

  /// Value is required but missing
  required,

  /// Custom validation failed
  custom,
}

/// Base class for all validation errors.
class ValidationError implements Exception {
  final String field;
  final String message;
  final ValidationErrorCode code;
  final dynamic value;

  const ValidationError({
    required this.field,
    required this.message,
    required this.code,
    this.value,
  });

  @override
  String toString() => 'ValidationError($field, $code): $message';

  /// Converts to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'field': field,
    'message': message,
    'code': code.name,
    if (value != null) 'value': value.toString(),
  };
}

/// Result of a validation operation.
sealed class ValidationResult<T> {
  const ValidationResult();

  /// Returns true if validation succeeded.
  bool get isValid => switch (this) {
    ValidationSuccess() => true,
    ValidationFailure() => false,
  };

  /// Returns the validated value or throws if validation failed.
  T get value => switch (this) {
    ValidationSuccess(:final data) => data,
    ValidationFailure(:final errors) => throw ValidationException(errors),
  };

  /// Returns the validated value or null if validation failed.
  T? get valueOrNull => switch (this) {
    ValidationSuccess(:final data) => data,
    ValidationFailure() => null,
  };

  /// Returns errors if validation failed, empty list otherwise.
  List<ValidationError> get errors => switch (this) {
    ValidationSuccess() => [],
    ValidationFailure(:final errors) => errors,
  };
}

/// Successful validation result.
final class ValidationSuccess<T> extends ValidationResult<T> {
  final T data;
  const ValidationSuccess(this.data);
}

/// Failed validation result.
final class ValidationFailure<T> extends ValidationResult<T> {
  @override
  final List<ValidationError> errors;
  const ValidationFailure(this.errors);
}

/// Exception thrown when accessing value from failed validation.
class ValidationException implements Exception {
  final List<ValidationError> errors;
  const ValidationException(this.errors);

  @override
  String toString() => 'ValidationException: ${errors.join(', ')}';

  /// Returns a formatted error message.
  String get message =>
      errors.map((e) => '${e.field}: ${e.message}').join('; ');
}

/// Base validator class.
abstract class Validator<T> {
  const Validator();

  /// Validates the input value.
  ValidationResult<T> validate(dynamic value);

  /// Validates and returns the value or throws.
  T parse(dynamic value) => validate(value).value;

  /// Validates and returns the value or null.
  T? safeParse(dynamic value) => validate(value).valueOrNull;
}

/// String validator with fluent API.
class StringValidator extends Validator<String> {
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  final String? patternMessage;
  final bool trim;
  final List<String>? allowedValues;

  const StringValidator({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.patternMessage,
    this.trim = false,
    this.allowedValues,
  });

  @override
  ValidationResult<String> validate(dynamic value) {
    final errors = <ValidationError>[];

    // Type check
    if (value is! String) {
      return ValidationFailure([
        ValidationError(
          field: 'value',
          message: 'Expected string, got ${value.runtimeType}',
          code: ValidationErrorCode.invalidType,
          value: value,
        ),
      ]);
    }

    var str = trim ? value.trim() : value;

    // Min length check
    if (minLength != null && str.length < minLength!) {
      errors.add(
        ValidationError(
          field: 'value',
          message: 'String must be at least $minLength characters',
          code: ValidationErrorCode.tooShort,
          value: str,
        ),
      );
    }

    // Max length check
    if (maxLength != null && str.length > maxLength!) {
      errors.add(
        ValidationError(
          field: 'value',
          message: 'String must be at most $maxLength characters',
          code: ValidationErrorCode.tooLong,
          value: str,
        ),
      );
    }

    // Pattern check
    if (pattern != null && !pattern!.hasMatch(str)) {
      errors.add(
        ValidationError(
          field: 'value',
          message: patternMessage ?? 'String does not match required pattern',
          code: ValidationErrorCode.invalidFormat,
          value: str,
        ),
      );
    }

    // Allowed values check
    if (allowedValues != null && !allowedValues!.contains(str)) {
      errors.add(
        ValidationError(
          field: 'value',
          message: 'Value must be one of: ${allowedValues!.join(', ')}',
          code: ValidationErrorCode.invalidEnum,
          value: str,
        ),
      );
    }

    return errors.isEmpty ? ValidationSuccess(str) : ValidationFailure(errors);
  }

  /// Creates a validator that requires minimum length.
  StringValidator min(int length) => StringValidator(
    minLength: length,
    maxLength: maxLength,
    pattern: pattern,
    patternMessage: patternMessage,
    trim: trim,
    allowedValues: allowedValues,
  );

  /// Creates a validator that requires maximum length.
  StringValidator max(int length) => StringValidator(
    minLength: minLength,
    maxLength: length,
    pattern: pattern,
    patternMessage: patternMessage,
    trim: trim,
    allowedValues: allowedValues,
  );

  /// Creates a validator that matches a pattern.
  StringValidator regex(RegExp pattern, [String? message]) => StringValidator(
    minLength: minLength,
    maxLength: maxLength,
    pattern: pattern,
    patternMessage: message,
    trim: trim,
    allowedValues: allowedValues,
  );

  /// Creates a validator that trims whitespace.
  StringValidator trimmed() => StringValidator(
    minLength: minLength,
    maxLength: maxLength,
    pattern: pattern,
    patternMessage: patternMessage,
    trim: true,
    allowedValues: allowedValues,
  );

  /// Creates a validator that only allows specific values.
  StringValidator oneOf(List<String> values) => StringValidator(
    minLength: minLength,
    maxLength: maxLength,
    pattern: pattern,
    patternMessage: patternMessage,
    trim: trim,
    allowedValues: values,
  );
}

/// Number validator with fluent API.
class NumberValidator extends Validator<num> {
  final num? min;
  final num? max;
  final bool integer;

  const NumberValidator({this.min, this.max, this.integer = false});

  @override
  ValidationResult<num> validate(dynamic value) {
    final errors = <ValidationError>[];

    // Type check
    if (value is! num) {
      return ValidationFailure([
        ValidationError(
          field: 'value',
          message: 'Expected number, got ${value.runtimeType}',
          code: ValidationErrorCode.invalidType,
          value: value,
        ),
      ]);
    }

    // Integer check
    if (integer && value is double) {
      errors.add(
        ValidationError(
          field: 'value',
          message: 'Expected integer, got double',
          code: ValidationErrorCode.invalidType,
          value: value,
        ),
      );
    }

    // Min check
    if (min != null && value < min!) {
      errors.add(
        ValidationError(
          field: 'value',
          message: 'Number must be at least $min',
          code: ValidationErrorCode.tooSmall,
          value: value,
        ),
      );
    }

    // Max check
    if (max != null && value > max!) {
      errors.add(
        ValidationError(
          field: 'value',
          message: 'Number must be at most $max',
          code: ValidationErrorCode.tooLarge,
          value: value,
        ),
      );
    }

    return errors.isEmpty
        ? ValidationSuccess(value)
        : ValidationFailure(errors);
  }

  /// Creates a validator that requires minimum value.
  NumberValidator minimum(num value) =>
      NumberValidator(min: value, max: max, integer: integer);

  /// Creates a validator that requires maximum value.
  NumberValidator maximum(num value) =>
      NumberValidator(min: min, max: value, integer: integer);

  /// Creates a validator that requires integer.
  NumberValidator int() => NumberValidator(min: min, max: max, integer: true);
}

/// Object validator for validating complex objects.
class ObjectValidator<T> extends Validator<T> {
  final T Function(Map<String, dynamic>) constructor;
  final Map<String, Validator> schema;

  const ObjectValidator({required this.constructor, required this.schema});

  @override
  ValidationResult<T> validate(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return ValidationFailure([
        ValidationError(
          field: 'value',
          message: 'Expected object, got ${value.runtimeType}',
          code: ValidationErrorCode.invalidType,
          value: value,
        ),
      ]);
    }

    final errors = <ValidationError>[];
    final validated = <String, dynamic>{};

    for (final entry in schema.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final fieldValue = value[fieldName];

      final result = validator.validate(fieldValue);
      if (result.isValid) {
        validated[fieldName] = result.value;
      } else {
        for (final error in result.errors) {
          errors.add(
            ValidationError(
              field: fieldName,
              message: error.message,
              code: error.code,
              value: error.value,
            ),
          );
        }
      }
    }

    return errors.isEmpty
        ? ValidationSuccess(constructor(validated))
        : ValidationFailure(errors);
  }
}

/// Factory class for creating validators (Zod-like API).
class Z {
  const Z._();

  /// Creates a string validator.
  static StringValidator string() => const StringValidator();

  /// Creates a number validator.
  static NumberValidator number() => const NumberValidator();

  /// Creates an object validator.
  static ObjectValidator<T> object<T>({
    required T Function(Map<String, dynamic>) constructor,
    required Map<String, Validator> schema,
  }) => ObjectValidator(constructor: constructor, schema: schema);
}
