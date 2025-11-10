import 'validator.dart';

/// Validation schemas for Note operations.
class NoteValidators {
  NoteValidators._();

  /// Validator for note title.
  /// - Must be a string
  /// - Trimmed automatically
  /// - Maximum 200 characters
  static final title = Z.string().trimmed().max(200);

  /// Validator for note content.
  /// - Must be a string
  /// - Trimmed automatically
  /// - Maximum 10,000 characters
  static final content = Z.string().trimmed().max(10000);

  /// Validator for creating a note.
  /// Ensures at least one of title or content is non-empty.
  static ValidationResult<CreateNoteInput> validateCreate({
    required String title,
    required String content,
  }) {
    final errors = <ValidationError>[];

    // Validate title
    final titleResult = NoteValidators.title.validate(title);
    if (!titleResult.isValid) {
      errors.addAll(
        titleResult.errors.map(
          (e) => ValidationError(
            field: 'title',
            message: e.message,
            value: e.value,
          ),
        ),
      );
    }

    // Validate content
    final contentResult = NoteValidators.content.validate(content);
    if (!contentResult.isValid) {
      errors.addAll(
        contentResult.errors.map(
          (e) => ValidationError(
            field: 'content',
            message: e.message,
            value: e.value,
          ),
        ),
      );
    }

    // At least one must be non-empty
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();

    if (trimmedTitle.isEmpty && trimmedContent.isEmpty) {
      errors.add(
        const ValidationError(
          field: 'note',
          message: 'Both title and content cannot be empty',
        ),
      );
    }

    return errors.isEmpty
        ? ValidationSuccess(
            CreateNoteInput(title: trimmedTitle, content: trimmedContent),
          )
        : ValidationFailure(errors);
  }

  /// Validator for updating a note.
  /// Same rules as create.
  static ValidationResult<UpdateNoteInput> validateUpdate({
    required String id,
    required String title,
    required String content,
  }) {
    final errors = <ValidationError>[];

    // Validate ID (must be non-empty)
    if (id.trim().isEmpty) {
      errors.add(
        const ValidationError(field: 'id', message: 'Note ID cannot be empty'),
      );
    }

    // Validate title
    final titleResult = NoteValidators.title.validate(title);
    if (!titleResult.isValid) {
      errors.addAll(
        titleResult.errors.map(
          (e) => ValidationError(
            field: 'title',
            message: e.message,
            value: e.value,
          ),
        ),
      );
    }

    // Validate content
    final contentResult = NoteValidators.content.validate(content);
    if (!contentResult.isValid) {
      errors.addAll(
        contentResult.errors.map(
          (e) => ValidationError(
            field: 'content',
            message: e.message,
            value: e.value,
          ),
        ),
      );
    }

    // At least one must be non-empty
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();

    if (trimmedTitle.isEmpty && trimmedContent.isEmpty) {
      errors.add(
        const ValidationError(
          field: 'note',
          message: 'Both title and content cannot be empty',
        ),
      );
    }

    return errors.isEmpty
        ? ValidationSuccess(
            UpdateNoteInput(
              id: id.trim(),
              title: trimmedTitle,
              content: trimmedContent,
            ),
          )
        : ValidationFailure(errors);
  }

  /// Validator for note ID.
  static ValidationResult<String> validateId(String id) {
    final trimmedId = id.trim();

    if (trimmedId.isEmpty) {
      return const ValidationFailure([
        ValidationError(field: 'id', message: 'Note ID cannot be empty'),
      ]);
    }

    return ValidationSuccess(trimmedId);
  }
}

/// Input data for creating a note (validated).
class CreateNoteInput {
  final String title;
  final String content;

  const CreateNoteInput({required this.title, required this.content});
}

/// Input data for updating a note (validated).
class UpdateNoteInput {
  final String id;
  final String title;
  final String content;

  const UpdateNoteInput({
    required this.id,
    required this.title,
    required this.content,
  });
}
