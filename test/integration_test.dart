import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:grpc_note_server/generated/note_service.pbgrpc.dart';
import 'package:grpc_note_server/repositories/note_repository.dart';
import 'package:grpc_note_server/server.dart';
import 'package:test/test.dart';

/// Integration tests for the gRPC Note API Server
/// Tests the complete end-to-end workflow with a real server and client
void main() {
  late NoteServer server;
  late ClientChannel channel;
  late NoteServiceClient client;
  const testPort = 50052; // Use different port to avoid conflicts

  // Setup: Start server before all tests
  setUpAll(() async {
    // Create server with fresh repository
    final repository = InMemoryNoteRepository();
    server = NoteServer(port: testPort, repository: repository);

    // Start the server
    await server.start();

    // Give server a moment to fully initialize
    await Future.delayed(const Duration(milliseconds: 100));

    // Create client channel
    channel = ClientChannel(
      'localhost',
      port: testPort,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );

    // Create client
    client = NoteServiceClient(channel);
  });

  // Teardown: Stop server and cleanup after all tests
  tearDownAll(() async {
    // Shutdown client channel
    await channel.shutdown();

    // Stop server
    await server.stop();
  });

  group('Complete CRUD Workflow', () {
    test(
      'should create, read, update, and delete notes successfully',
      () async {
        // CREATE - Create a note
        final createRequest = CreateNoteRequest()
          ..title = 'Integration Test Note'
          ..content = 'This is a test note for integration testing.';

        final createResponse = await client.createNote(createRequest);

        expect(createResponse.note.id, isNotEmpty);
        expect(createResponse.note.title, equals('Integration Test Note'));
        expect(
          createResponse.note.content,
          equals('This is a test note for integration testing.'),
        );
        expect(createResponse.note.createdAt, greaterThan(0));
        expect(createResponse.note.updatedAt, greaterThan(0));

        final noteId = createResponse.note.id;

        // READ - Get the note by ID
        final getRequest = GetNoteRequest()..id = noteId;
        final getResponse = await client.getNote(getRequest);

        expect(getResponse.note.id, equals(noteId));
        expect(getResponse.note.title, equals('Integration Test Note'));

        // UPDATE - Update the note
        final updateRequest = UpdateNoteRequest()
          ..id = noteId
          ..title = 'Updated Integration Test Note'
          ..content = 'This content has been updated.';

        final updateResponse = await client.updateNote(updateRequest);

        expect(updateResponse.note.id, equals(noteId));
        expect(
          updateResponse.note.title,
          equals('Updated Integration Test Note'),
        );
        expect(
          updateResponse.note.content,
          equals('This content has been updated.'),
        );
        expect(
          updateResponse.note.updatedAt,
          greaterThan(createResponse.note.updatedAt),
        );

        // DELETE - Delete the note
        final deleteRequest = DeleteNoteRequest()..id = noteId;
        final deleteResponse = await client.deleteNote(deleteRequest);

        expect(deleteResponse.success, isTrue);

        // Verify note is deleted
        try {
          await client.getNote(getRequest);
          fail('Should have thrown NOT_FOUND error');
        } on GrpcError catch (e) {
          expect(e.code, equals(StatusCode.notFound));
        }
      },
    );

    test('should list all notes correctly', () async {
      // Create multiple notes
      final note1 = CreateNoteRequest()
        ..title = 'Note 1'
        ..content = 'Content 1';
      final note2 = CreateNoteRequest()
        ..title = 'Note 2'
        ..content = 'Content 2';

      await client.createNote(note1);
      await client.createNote(note2);

      // List all notes
      final listRequest = ListNotesRequest();
      final listResponse = await client.listNotes(listRequest);

      expect(listResponse.notes.length, greaterThanOrEqualTo(2));

      // Verify notes are in the list
      final titles = listResponse.notes.map((n) => n.title).toList();
      expect(titles, contains('Note 1'));
      expect(titles, contains('Note 2'));
    });
  });

  group('Error Scenarios', () {
    test(
      'should return INVALID_ARGUMENT for empty title and content',
      () async {
        final invalidRequest = CreateNoteRequest()
          ..title = ''
          ..content = '';

        try {
          await client.createNote(invalidRequest);
          fail('Should have thrown INVALID_ARGUMENT error');
        } on GrpcError catch (e) {
          expect(e.code, equals(StatusCode.invalidArgument));
          expect(e.message, contains('cannot be empty'));
        }
      },
    );

    test('should return NOT_FOUND when getting non-existent note', () async {
      final getRequest = GetNoteRequest()..id = 'non-existent-id-12345';

      try {
        await client.getNote(getRequest);
        fail('Should have thrown NOT_FOUND error');
      } on GrpcError catch (e) {
        expect(e.code, equals(StatusCode.notFound));
        expect(e.message, contains('not found'));
      }
    });

    test('should return NOT_FOUND when updating non-existent note', () async {
      final updateRequest = UpdateNoteRequest()
        ..id = 'non-existent-id-67890'
        ..title = 'Updated Title'
        ..content = 'Updated Content';

      try {
        await client.updateNote(updateRequest);
        fail('Should have thrown NOT_FOUND error');
      } on GrpcError catch (e) {
        expect(e.code, equals(StatusCode.notFound));
        expect(e.message, contains('not found'));
      }
    });

    test('should return NOT_FOUND when deleting non-existent note', () async {
      final deleteRequest = DeleteNoteRequest()..id = 'non-existent-id-99999';

      try {
        await client.deleteNote(deleteRequest);
        fail('Should have thrown NOT_FOUND error');
      } on GrpcError catch (e) {
        expect(e.code, equals(StatusCode.notFound));
        expect(e.message, contains('not found'));
      }
    });
  });

  group('Concurrent Operations', () {
    test('should handle concurrent create operations', () async {
      // Create multiple notes concurrently
      final futures = <Future<CreateNoteResponse>>[];

      for (int i = 0; i < 10; i++) {
        final request = CreateNoteRequest()
          ..title = 'Concurrent Note $i'
          ..content = 'Content for concurrent note $i';
        futures.add(client.createNote(request));
      }

      final responses = await Future.wait(futures);

      // Verify all notes were created successfully
      expect(responses.length, equals(10));

      // Verify all IDs are unique
      final ids = responses.map((r) => r.note.id).toSet();
      expect(ids.length, equals(10));

      // Verify all notes can be retrieved
      final listResponse = await client.listNotes(ListNotesRequest());
      final concurrentNotes = listResponse.notes
          .where((n) => n.title.startsWith('Concurrent Note'))
          .toList();
      expect(concurrentNotes.length, equals(10));
    });

    test('should handle concurrent read operations', () async {
      // Create a note
      final createRequest = CreateNoteRequest()
        ..title = 'Concurrent Read Test'
        ..content = 'Testing concurrent reads';

      final createResponse = await client.createNote(createRequest);
      final noteId = createResponse.note.id;

      // Read the same note concurrently from multiple clients
      final futures = <Future<GetNoteResponse>>[];

      for (int i = 0; i < 20; i++) {
        final request = GetNoteRequest()..id = noteId;
        futures.add(client.getNote(request));
      }

      final responses = await Future.wait(futures);

      // Verify all reads succeeded
      expect(responses.length, equals(20));

      // Verify all responses have the same data
      for (final response in responses) {
        expect(response.note.id, equals(noteId));
        expect(response.note.title, equals('Concurrent Read Test'));
      }
    });

    test('should handle concurrent update operations', () async {
      // Create a note
      final createRequest = CreateNoteRequest()
        ..title = 'Concurrent Update Test'
        ..content = 'Initial content';

      final createResponse = await client.createNote(createRequest);
      final noteId = createResponse.note.id;

      // Update the note concurrently
      final futures = <Future<UpdateNoteResponse>>[];

      for (int i = 0; i < 5; i++) {
        final request = UpdateNoteRequest()
          ..id = noteId
          ..title = 'Updated Title $i'
          ..content = 'Updated content $i';
        futures.add(client.updateNote(request));
      }

      final responses = await Future.wait(futures);

      // Verify all updates succeeded
      expect(responses.length, equals(5));

      // Verify the note exists and has been updated
      final getRequest = GetNoteRequest()..id = noteId;
      final getResponse = await client.getNote(getRequest);
      expect(getResponse.note.id, equals(noteId));
      expect(getResponse.note.title, startsWith('Updated Title'));
    });

    test('should handle mixed concurrent operations', () async {
      // Perform various operations concurrently
      final futures = <Future>[];

      // Create operations
      for (int i = 0; i < 5; i++) {
        final request = CreateNoteRequest()
          ..title = 'Mixed Op Note $i'
          ..content = 'Content $i';
        futures.add(client.createNote(request));
      }

      // List operations
      for (int i = 0; i < 3; i++) {
        futures.add(client.listNotes(ListNotesRequest()));
      }

      // Wait for all operations to complete
      await Future.wait(futures);

      // Verify system is still functional
      final listResponse = await client.listNotes(ListNotesRequest());
      expect(listResponse.notes.length, greaterThan(0));
    });
  });
}
