import 'package:test/test.dart';
import 'package:grpc_note_server/repositories/note_repository.dart';

void main() {
  group('InMemoryNoteRepository', () {
    late InMemoryNoteRepository repository;

    setUp(() {
      repository = InMemoryNoteRepository();
    });

    group('create', () {
      test('creates note with valid data', () async {
        final note = await repository.create('Test Title', 'Test Content');

        expect(note.id, isNotEmpty);
        expect(note.title, equals('Test Title'));
        expect(note.content, equals('Test Content'));
        expect(note.createdAt, isNotNull);
        expect(note.updatedAt, isNotNull);
        expect(note.createdAt, equals(note.updatedAt));
      });

      test('generates unique IDs for multiple notes', () async {
        final note1 = await repository.create('Title 1', 'Content 1');
        final note2 = await repository.create('Title 2', 'Content 2');

        expect(note1.id, isNot(equals(note2.id)));
      });

      test('persists created note', () async {
        final created = await repository.create('Title', 'Content');
        final retrieved = await repository.getById(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(created.id));
        expect(retrieved.title, equals(created.title));
        expect(retrieved.content, equals(created.content));
      });
    });

    group('getById', () {
      test('returns note with existing ID', () async {
        final created = await repository.create('Title', 'Content');
        final retrieved = await repository.getById(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(created.id));
        expect(retrieved.title, equals('Title'));
        expect(retrieved.content, equals('Content'));
      });

      test('returns null for non-existent ID', () async {
        final retrieved = await repository.getById('non-existent-id');

        expect(retrieved, isNull);
      });
    });

    group('getAll', () {
      test('returns empty list when no notes exist', () async {
        final notes = await repository.getAll();

        expect(notes, isEmpty);
      });

      test('returns all notes when storage is populated', () async {
        await repository.create('Title 1', 'Content 1');
        await repository.create('Title 2', 'Content 2');
        await repository.create('Title 3', 'Content 3');

        final notes = await repository.getAll();

        expect(notes.length, equals(3));
        expect(
          notes.map((n) => n.title),
          containsAll(['Title 1', 'Title 2', 'Title 3']),
        );
      });
    });

    group('update', () {
      test('updates note with valid ID', () async {
        final created = await repository.create(
          'Original Title',
          'Original Content',
        );

        // Small delay to ensure updatedAt timestamp is different
        await Future.delayed(const Duration(milliseconds: 10));

        final updated = await repository.update(
          created.id,
          'Updated Title',
          'Updated Content',
        );

        expect(updated, isNotNull);
        expect(updated!.id, equals(created.id));
        expect(updated.title, equals('Updated Title'));
        expect(updated.content, equals('Updated Content'));
        expect(updated.createdAt, equals(created.createdAt));
        expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
      });

      test('returns null for non-existent ID', () async {
        final updated = await repository.update(
          'non-existent-id',
          'Title',
          'Content',
        );

        expect(updated, isNull);
      });

      test('persists updated note', () async {
        final created = await repository.create('Original', 'Original');
        await repository.update(created.id, 'Updated', 'Updated');

        final retrieved = await repository.getById(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('Updated'));
        expect(retrieved.content, equals('Updated'));
      });
    });

    group('delete', () {
      test('deletes note with valid ID', () async {
        final created = await repository.create('Title', 'Content');
        final deleted = await repository.delete(created.id);

        expect(deleted, isTrue);

        final retrieved = await repository.getById(created.id);
        expect(retrieved, isNull);
      });

      test('returns false for non-existent ID', () async {
        final deleted = await repository.delete('non-existent-id');

        expect(deleted, isFalse);
      });

      test('removes note from storage', () async {
        final note1 = await repository.create('Title 1', 'Content 1');
        final note2 = await repository.create('Title 2', 'Content 2');

        await repository.delete(note1.id);

        final allNotes = await repository.getAll();
        expect(allNotes.length, equals(1));
        expect(allNotes.first.id, equals(note2.id));
      });
    });

    group('concurrent access', () {
      test('handles concurrent create operations', () async {
        final futures = List.generate(
          10,
          (i) => repository.create('Title $i', 'Content $i'),
        );

        final notes = await Future.wait(futures);

        expect(notes.length, equals(10));
        final ids = notes.map((n) => n.id).toSet();
        expect(ids.length, equals(10), reason: 'All IDs should be unique');

        final allNotes = await repository.getAll();
        expect(allNotes.length, equals(10));
      });

      test('handles concurrent read operations', () async {
        final created = await repository.create('Title', 'Content');

        final futures = List.generate(
          20,
          (_) => repository.getById(created.id),
        );

        final results = await Future.wait(futures);

        expect(results.every((note) => note != null), isTrue);
        expect(results.every((note) => note!.id == created.id), isTrue);
      });

      test('handles concurrent update operations', () async {
        final created = await repository.create('Original', 'Original');

        final futures = List.generate(
          5,
          (i) => repository.update(created.id, 'Title $i', 'Content $i'),
        );

        final results = await Future.wait(futures);

        expect(results.every((note) => note != null), isTrue);

        final finalNote = await repository.getById(created.id);
        expect(finalNote, isNotNull);
        expect(finalNote!.title, startsWith('Title '));
      });

      test('handles mixed concurrent operations', () async {
        // Create initial notes
        final note1 = await repository.create('Note 1', 'Content 1');
        final note2 = await repository.create('Note 2', 'Content 2');

        // Mix of operations
        final futures = <Future>[
          repository.create('Note 3', 'Content 3'),
          repository.getById(note1.id),
          repository.update(note2.id, 'Updated 2', 'Updated Content 2'),
          repository.getAll(),
          repository.create('Note 4', 'Content 4'),
          repository.delete(note1.id),
        ];

        await Future.wait(futures);

        final allNotes = await repository.getAll();
        expect(allNotes.length, equals(3)); // note2 (updated), note3, note4
      });
    });
  });
}
