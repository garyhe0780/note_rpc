import 'package:test/test.dart';
import 'package:grpc_note_server/validation/note_validators.dart';

void main() {
  group('NoteValidators.validateCreate', () {
    test('validates valid note with title and content', () {
      final result = NoteValidators.validateCreate(
        title: 'Test Title',
        content: 'Test Content',
      );

      expect(result.isValid, isTrue);
      expect(result.value.title, equals('Test Title'));
      expect(result.value.content, equals('Test Content'));
    });

    test('trims whitespace from title and content', () {
      final result = NoteValidators.validateCreate(
        title: '  Test Title  ',
        content: '  Test Content  ',
      );

      expect(result.isValid, isTrue);
      expect(result.value.title, equals('Test Title'));
      expect(result.value.content, equals('Test Content'));
    });

    test('validates note with only title', () {
      final result = NoteValidators.validateCreate(
        title: 'Test Title',
        content: '',
      );

      expect(result.isValid, isTrue);
      expect(result.value.title, equals('Test Title'));
      expect(result.value.content, isEmpty);
    });

    test('validates note with only content', () {
      final result = NoteValidators.validateCreate(
        title: '',
        content: 'Test Content',
      );

      expect(result.isValid, isTrue);
      expect(result.value.title, isEmpty);
      expect(result.value.content, equals('Test Content'));
    });

    test('rejects note with empty title and content', () {
      final result = NoteValidators.validateCreate(title: '', content: '');

      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.message.contains('cannot be empty')),
        isTrue,
      );
    });

    test('rejects note with whitespace-only title and content', () {
      final result = NoteValidators.validateCreate(
        title: '   ',
        content: '   ',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.message.contains('cannot be empty')),
        isTrue,
      );
    });

    test('rejects title longer than 200 characters', () {
      final longTitle = 'a' * 201;
      final result = NoteValidators.validateCreate(
        title: longTitle,
        content: 'Content',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.field == 'title' && e.message.contains('200'),
        ),
        isTrue,
      );
    });

    test('accepts title with exactly 200 characters', () {
      final title = 'a' * 200;
      final result = NoteValidators.validateCreate(
        title: title,
        content: 'Content',
      );

      expect(result.isValid, isTrue);
    });

    test('rejects content longer than 10,000 characters', () {
      final longContent = 'a' * 10001;
      final result = NoteValidators.validateCreate(
        title: 'Title',
        content: longContent,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.field == 'content' && e.message.contains('10000'),
        ),
        isTrue,
      );
    });

    test('accepts content with exactly 10,000 characters', () {
      final content = 'a' * 10000;
      final result = NoteValidators.validateCreate(
        title: 'Title',
        content: content,
      );

      expect(result.isValid, isTrue);
    });

    test('returns multiple errors for multiple violations', () {
      final longTitle = 'a' * 201;
      final longContent = 'b' * 10001;

      final result = NoteValidators.validateCreate(
        title: longTitle,
        content: longContent,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(2));
    });
  });

  group('NoteValidators.validateUpdate', () {
    test('validates valid update with all fields', () {
      final result = NoteValidators.validateUpdate(
        id: 'test-id-123',
        title: 'Updated Title',
        content: 'Updated Content',
      );

      expect(result.isValid, isTrue);
      expect(result.value.id, equals('test-id-123'));
      expect(result.value.title, equals('Updated Title'));
      expect(result.value.content, equals('Updated Content'));
    });

    test('trims whitespace from all fields', () {
      final result = NoteValidators.validateUpdate(
        id: '  test-id-123  ',
        title: '  Updated Title  ',
        content: '  Updated Content  ',
      );

      expect(result.isValid, isTrue);
      expect(result.value.id, equals('test-id-123'));
      expect(result.value.title, equals('Updated Title'));
      expect(result.value.content, equals('Updated Content'));
    });

    test('rejects empty ID', () {
      final result = NoteValidators.validateUpdate(
        id: '',
        title: 'Title',
        content: 'Content',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.field == 'id' && e.message.contains('cannot be empty'),
        ),
        isTrue,
      );
    });

    test('rejects whitespace-only ID', () {
      final result = NoteValidators.validateUpdate(
        id: '   ',
        title: 'Title',
        content: 'Content',
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.field == 'id'), isTrue);
    });

    test('rejects empty title and content', () {
      final result = NoteValidators.validateUpdate(
        id: 'test-id',
        title: '',
        content: '',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.message.contains('cannot be empty')),
        isTrue,
      );
    });

    test('validates update with only title', () {
      final result = NoteValidators.validateUpdate(
        id: 'test-id',
        title: 'Updated Title',
        content: '',
      );

      expect(result.isValid, isTrue);
    });

    test('validates update with only content', () {
      final result = NoteValidators.validateUpdate(
        id: 'test-id',
        title: '',
        content: 'Updated Content',
      );

      expect(result.isValid, isTrue);
    });

    test('applies same length constraints as create', () {
      final longTitle = 'a' * 201;
      final result = NoteValidators.validateUpdate(
        id: 'test-id',
        title: longTitle,
        content: 'Content',
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.field == 'title'), isTrue);
    });
  });

  group('NoteValidators.validateId', () {
    test('validates non-empty ID', () {
      final result = NoteValidators.validateId('test-id-123');

      expect(result.isValid, isTrue);
      expect(result.value, equals('test-id-123'));
    });

    test('trims whitespace from ID', () {
      final result = NoteValidators.validateId('  test-id-123  ');

      expect(result.isValid, isTrue);
      expect(result.value, equals('test-id-123'));
    });

    test('rejects empty ID', () {
      final result = NoteValidators.validateId('');

      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.message.contains('cannot be empty')),
        isTrue,
      );
    });

    test('rejects whitespace-only ID', () {
      final result = NoteValidators.validateId('   ');

      expect(result.isValid, isFalse);
    });
  });

  group('CreateNoteInput', () {
    test('creates input with provided values', () {
      const input = CreateNoteInput(
        title: 'Test Title',
        content: 'Test Content',
      );

      expect(input.title, equals('Test Title'));
      expect(input.content, equals('Test Content'));
    });
  });

  group('UpdateNoteInput', () {
    test('creates input with provided values', () {
      const input = UpdateNoteInput(
        id: 'test-id',
        title: 'Test Title',
        content: 'Test Content',
      );

      expect(input.id, equals('test-id'));
      expect(input.title, equals('Test Title'));
      expect(input.content, equals('Test Content'));
    });
  });
}
