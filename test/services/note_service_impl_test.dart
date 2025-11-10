import 'dart:io';
import 'package:test/test.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc_note_server/services/note_service_impl.dart';
import 'package:grpc_note_server/repositories/note_repository.dart';
import 'package:grpc_note_server/generated/note_service.pbgrpc.dart';

void main() {
  group('NoteServiceImpl', () {
    late NoteServiceImpl service;
    late InMemoryNoteRepository repository;

    setUp(() {
      repository = InMemoryNoteRepository();
      service = NoteServiceImpl(repository);
    });

    group('createNote', () {
      test('creates note with valid title and content', () async {
        final request = CreateNoteRequest(
          title: 'Test Title',
          content: 'Test Content',
        );

        final response = await service.createNote(_MockServiceCall(), request);

        expect(response.note.id, isNotEmpty);
        expect(response.note.title, equals('Test Title'));
        expect(response.note.content, equals('Test Content'));
        expect(response.note.createdAt, greaterThan(0));
        expect(response.note.updatedAt, greaterThan(0));
      });

      test('creates note with only title', () async {
        final request = CreateNoteRequest(title: 'Only Title', content: '');

        final response = await service.createNote(_MockServiceCall(), request);

        expect(response.note.title, equals('Only Title'));
        expect(response.note.content, isEmpty);
      });

      test('creates note with only content', () async {
        final request = CreateNoteRequest(title: '', content: 'Only Content');

        final response = await service.createNote(_MockServiceCall(), request);

        expect(response.note.title, isEmpty);
        expect(response.note.content, equals('Only Content'));
      });

      test(
        'throws INVALID_ARGUMENT when both title and content are empty',
        () async {
          final request = CreateNoteRequest(title: '', content: '');

          expect(
            () => service.createNote(_MockServiceCall(), request),
            throwsA(
              isA<GrpcError>()
                  .having((e) => e.code, 'code', StatusCode.invalidArgument)
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Both title and content cannot be empty'),
                  ),
            ),
          );
        },
      );

      test(
        'throws INVALID_ARGUMENT when both title and content are whitespace',
        () async {
          final request = CreateNoteRequest(title: '   ', content: '  ');

          expect(
            () => service.createNote(_MockServiceCall(), request),
            throwsA(
              isA<GrpcError>().having(
                (e) => e.code,
                'code',
                StatusCode.invalidArgument,
              ),
            ),
          );
        },
      );
    });

    group('getNote', () {
      test('returns note with existing ID', () async {
        // Create a note first
        final createRequest = CreateNoteRequest(
          title: 'Test Title',
          content: 'Test Content',
        );
        final createResponse = await service.createNote(
          _MockServiceCall(),
          createRequest,
        );
        final noteId = createResponse.note.id;

        // Get the note
        final getRequest = GetNoteRequest(id: noteId);
        final getResponse = await service.getNote(
          _MockServiceCall(),
          getRequest,
        );

        expect(getResponse.note.id, equals(noteId));
        expect(getResponse.note.title, equals('Test Title'));
        expect(getResponse.note.content, equals('Test Content'));
      });

      test('throws NOT_FOUND for non-existent ID', () async {
        final request = GetNoteRequest(id: 'non-existent-id');

        expect(
          () => service.getNote(_MockServiceCall(), request),
          throwsA(
            isA<GrpcError>()
                .having((e) => e.code, 'code', StatusCode.notFound)
                .having(
                  (e) => e.message,
                  'message',
                  contains('Note with id non-existent-id not found'),
                ),
          ),
        );
      });
    });

    group('listNotes', () {
      test('returns empty list when no notes exist', () async {
        final request = ListNotesRequest();
        final response = await service.listNotes(_MockServiceCall(), request);

        expect(response.notes, isEmpty);
      });

      test('returns all notes when storage is populated', () async {
        // Create multiple notes
        await service.createNote(
          _MockServiceCall(),
          CreateNoteRequest(title: 'Title 1', content: 'Content 1'),
        );
        await service.createNote(
          _MockServiceCall(),
          CreateNoteRequest(title: 'Title 2', content: 'Content 2'),
        );
        await service.createNote(
          _MockServiceCall(),
          CreateNoteRequest(title: 'Title 3', content: 'Content 3'),
        );

        // List all notes
        final request = ListNotesRequest();
        final response = await service.listNotes(_MockServiceCall(), request);

        expect(response.notes.length, equals(3));
        expect(
          response.notes.map((n) => n.title),
          containsAll(['Title 1', 'Title 2', 'Title 3']),
        );
      });
    });

    group('updateNote', () {
      test('updates note with valid ID and data', () async {
        // Create a note first
        final createResponse = await service.createNote(
          _MockServiceCall(),
          CreateNoteRequest(
            title: 'Original Title',
            content: 'Original Content',
          ),
        );
        final noteId = createResponse.note.id;
        final originalUpdatedAt = createResponse.note.updatedAt;

        // Small delay to ensure timestamp difference
        await Future.delayed(const Duration(milliseconds: 10));

        // Update the note
        final updateRequest = UpdateNoteRequest(
          id: noteId,
          title: 'Updated Title',
          content: 'Updated Content',
        );
        final updateResponse = await service.updateNote(
          _MockServiceCall(),
          updateRequest,
        );

        expect(updateResponse.note.id, equals(noteId));
        expect(updateResponse.note.title, equals('Updated Title'));
        expect(updateResponse.note.content, equals('Updated Content'));
        expect(updateResponse.note.updatedAt, greaterThan(originalUpdatedAt));
      });

      test('throws NOT_FOUND for non-existent ID', () async {
        final request = UpdateNoteRequest(
          id: 'non-existent-id',
          title: 'Title',
          content: 'Content',
        );

        expect(
          () => service.updateNote(_MockServiceCall(), request),
          throwsA(
            isA<GrpcError>()
                .having((e) => e.code, 'code', StatusCode.notFound)
                .having(
                  (e) => e.message,
                  'message',
                  contains('Note with id non-existent-id not found'),
                ),
          ),
        );
      });

      test(
        'throws INVALID_ARGUMENT when both title and content are empty',
        () async {
          // Create a note first
          final createResponse = await service.createNote(
            _MockServiceCall(),
            CreateNoteRequest(title: 'Title', content: 'Content'),
          );

          final request = UpdateNoteRequest(
            id: createResponse.note.id,
            title: '',
            content: '',
          );

          expect(
            () => service.updateNote(_MockServiceCall(), request),
            throwsA(
              isA<GrpcError>()
                  .having((e) => e.code, 'code', StatusCode.invalidArgument)
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Both title and content cannot be empty'),
                  ),
            ),
          );
        },
      );

      test(
        'throws INVALID_ARGUMENT when both title and content are whitespace',
        () async {
          // Create a note first
          final createResponse = await service.createNote(
            _MockServiceCall(),
            CreateNoteRequest(title: 'Title', content: 'Content'),
          );

          final request = UpdateNoteRequest(
            id: createResponse.note.id,
            title: '  ',
            content: '   ',
          );

          expect(
            () => service.updateNote(_MockServiceCall(), request),
            throwsA(
              isA<GrpcError>().having(
                (e) => e.code,
                'code',
                StatusCode.invalidArgument,
              ),
            ),
          );
        },
      );
    });

    group('deleteNote', () {
      test('deletes note with valid ID', () async {
        // Create a note first
        final createResponse = await service.createNote(
          _MockServiceCall(),
          CreateNoteRequest(title: 'Title', content: 'Content'),
        );
        final noteId = createResponse.note.id;

        // Delete the note
        final deleteRequest = DeleteNoteRequest(id: noteId);
        final deleteResponse = await service.deleteNote(
          _MockServiceCall(),
          deleteRequest,
        );

        expect(deleteResponse.success, isTrue);

        // Verify note is deleted
        final getRequest = GetNoteRequest(id: noteId);
        expect(
          () => service.getNote(_MockServiceCall(), getRequest),
          throwsA(
            isA<GrpcError>().having((e) => e.code, 'code', StatusCode.notFound),
          ),
        );
      });

      test('throws NOT_FOUND for non-existent ID', () async {
        final request = DeleteNoteRequest(id: 'non-existent-id');

        expect(
          () => service.deleteNote(_MockServiceCall(), request),
          throwsA(
            isA<GrpcError>()
                .having((e) => e.code, 'code', StatusCode.notFound)
                .having(
                  (e) => e.message,
                  'message',
                  contains('Note with id non-existent-id not found'),
                ),
          ),
        );
      });
    });

    group('error handling', () {
      test(
        'returns proper gRPC status codes for all error scenarios',
        () async {
          // INVALID_ARGUMENT for empty input
          expect(
            () => service.createNote(
              _MockServiceCall(),
              CreateNoteRequest(title: '', content: ''),
            ),
            throwsA(
              isA<GrpcError>().having(
                (e) => e.code,
                'code',
                StatusCode.invalidArgument,
              ),
            ),
          );

          // NOT_FOUND for non-existent note
          expect(
            () => service.getNote(
              _MockServiceCall(),
              GetNoteRequest(id: 'invalid'),
            ),
            throwsA(
              isA<GrpcError>().having(
                (e) => e.code,
                'code',
                StatusCode.notFound,
              ),
            ),
          );

          expect(
            () => service.updateNote(
              _MockServiceCall(),
              UpdateNoteRequest(id: 'invalid', title: 'T', content: 'C'),
            ),
            throwsA(
              isA<GrpcError>().having(
                (e) => e.code,
                'code',
                StatusCode.notFound,
              ),
            ),
          );

          expect(
            () => service.deleteNote(
              _MockServiceCall(),
              DeleteNoteRequest(id: 'invalid'),
            ),
            throwsA(
              isA<GrpcError>().having(
                (e) => e.code,
                'code',
                StatusCode.notFound,
              ),
            ),
          );
        },
      );
    });
  });
}

/// Mock ServiceCall implementation for testing
class _MockServiceCall extends ServiceCall {
  _MockServiceCall();

  @override
  final Map<String, String> clientMetadata = {};

  @override
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 30));

  @override
  bool get isCanceled => false;

  @override
  bool get isTimedOut => false;

  final String method = 'test';

  @override
  void sendHeaders() {}

  @override
  void sendTrailers({int? status, String? message}) {}

  @override
  Map<String, String>? get headers => null;

  @override
  Map<String, String>? get trailers => null;

  @override
  X509Certificate? get clientCertificate => null;

  @override
  InternetAddress? get remoteAddress => null;
}
