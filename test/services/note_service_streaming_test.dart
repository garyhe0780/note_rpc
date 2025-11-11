import 'dart:async';
import 'dart:io';
import 'package:grpc/grpc.dart';
import 'package:test/test.dart';
import 'package:grpc_note_server/generated/note_service.pbgrpc.dart';
import 'package:grpc_note_server/repositories/note_repository.dart';
import 'package:grpc_note_server/services/note_service_impl.dart';

void main() {
  group('NoteService WatchNotes Streaming', () {
    late NoteRepository repository;
    late NoteServiceImpl service;

    setUp(() {
      repository = InMemoryNoteRepository();
      service = NoteServiceImpl(repository);
    });

    test('should stream note creation events', () async {
      final request = WatchNotesRequest();
      final call = _MockServiceCall();

      final events = <NoteEvent>[];
      final streamCompleter = Completer<void>();

      // Start watching
      service.watchNotes(call, request).listen((event) {
        events.add(event);
        if (events.length == 2) {
          streamCompleter.complete();
        }
      }, onError: (e) => streamCompleter.completeError(e));

      // Give the stream time to start
      await Future.delayed(const Duration(milliseconds: 100));

      // Create notes
      await repository.create('Note 1', 'Content 1');
      await repository.create('Note 2', 'Content 2');

      // Wait for events
      await streamCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Did not receive events'),
      );

      expect(events, hasLength(2));
      expect(events[0].eventType, equals(NoteEventType.CREATED));
      expect(events[0].note.title, equals('Note 1'));
      expect(events[1].eventType, equals(NoteEventType.CREATED));
      expect(events[1].note.title, equals('Note 2'));
    });

    test('should stream note update events', () async {
      final request = WatchNotesRequest();
      final call = _MockServiceCall();

      // Create a note first
      final note = await repository.create('Original', 'Content');

      final events = <NoteEvent>[];
      final streamCompleter = Completer<void>();

      // Start watching
      service.watchNotes(call, request).listen((event) {
        events.add(event);
        if (event.eventType == NoteEventType.UPDATED) {
          streamCompleter.complete();
        }
      }, onError: (e) => streamCompleter.completeError(e));

      await Future.delayed(const Duration(milliseconds: 100));

      // Update the note
      await repository.update(note.id, 'Updated', 'New content');

      await streamCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Did not receive update event'),
      );

      final updateEvent = events.firstWhere(
        (e) => e.eventType == NoteEventType.UPDATED,
      );
      expect(updateEvent.note.title, equals('Updated'));
      expect(updateEvent.note.content, equals('New content'));
    });

    test('should stream note deletion events', () async {
      final request = WatchNotesRequest();
      final call = _MockServiceCall();

      // Create a note first
      final note = await repository.create('To Delete', 'Content');

      final events = <NoteEvent>[];
      final streamCompleter = Completer<void>();

      // Start watching
      service.watchNotes(call, request).listen((event) {
        events.add(event);
        if (event.eventType == NoteEventType.DELETED) {
          streamCompleter.complete();
        }
      }, onError: (e) => streamCompleter.completeError(e));

      await Future.delayed(const Duration(milliseconds: 100));

      // Delete the note
      await repository.delete(note.id);

      await streamCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Did not receive delete event'),
      );

      final deleteEvent = events.firstWhere(
        (e) => e.eventType == NoteEventType.DELETED,
      );
      expect(deleteEvent.note.id, equals(note.id));
    });

    test('should filter events by note ID', () async {
      // Create two notes
      final note1 = await repository.create('Note 1', 'Content 1');
      final note2 = await repository.create('Note 2', 'Content 2');

      final request = WatchNotesRequest(noteId: note1.id);
      final call = _MockServiceCall();

      final events = <NoteEvent>[];
      final streamCompleter = Completer<void>();

      // Start watching only note1
      service.watchNotes(call, request).listen((event) {
        events.add(event);
        if (event.eventType == NoteEventType.UPDATED) {
          streamCompleter.complete();
        }
      }, onError: (e) => streamCompleter.completeError(e));

      await Future.delayed(const Duration(milliseconds: 100));

      // Update both notes
      await repository.update(note2.id, 'Updated 2', 'Content 2');
      await repository.update(note1.id, 'Updated 1', 'Content 1');

      await streamCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () =>
            throw TimeoutException('Did not receive filtered event'),
      );

      // Should only receive events for note1
      expect(events.every((e) => e.note.id == note1.id), isTrue);
      expect(events.any((e) => e.note.id == note2.id), isFalse);
    });

    test('should include timestamp in events', () async {
      final request = WatchNotesRequest();
      final call = _MockServiceCall();

      final events = <NoteEvent>[];
      final streamCompleter = Completer<void>();

      service.watchNotes(call, request).listen((event) {
        events.add(event);
        streamCompleter.complete();
      }, onError: (e) => streamCompleter.completeError(e));

      await Future.delayed(const Duration(milliseconds: 100));

      final beforeCreate = DateTime.now().millisecondsSinceEpoch;
      await repository.create('Test', 'Content');
      final afterCreate = DateTime.now().millisecondsSinceEpoch;

      await streamCompleter.future.timeout(const Duration(seconds: 2));

      expect(events, hasLength(1));
      final timestamp = events[0].timestamp.toInt();
      expect(timestamp, greaterThanOrEqualTo(beforeCreate));
      expect(timestamp, lessThanOrEqualTo(afterCreate));
    });
  });
}

/// Mock ServiceCall for testing
class _MockServiceCall extends ServiceCall {
  @override
  final Map<String, String> clientMetadata = {};

  @override
  final DateTime deadline = DateTime.now().add(const Duration(minutes: 5));

  @override
  bool isCanceled = false;

  @override
  bool get isTimedOut => false;

  Future<void> get onCancel => Future.value();

  Map<String, String>? get trailers => null;

  @override
  Map<String, String>? get headers => null;

  @override
  X509Certificate? get clientCertificate => null;

  @override
  InternetAddress? get remoteAddress => null;

  @override
  void sendHeaders() {}

  @override
  void sendTrailers({int? status, String? message}) {}
}
