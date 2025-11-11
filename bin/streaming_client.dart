import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:grpc_note_server/generated/note_service.pbgrpc.dart';

/// Example client demonstrating gRPC server streaming for real-time note updates
Future<void> main() async {
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
  );

  final client = NoteServiceClient(channel);

  print('Starting note watcher...\n');

  // Start watching for note changes in a separate task
  final watchTask = _watchNotes(client);

  // Give the watcher time to start
  await Future.delayed(const Duration(milliseconds: 500));

  // Perform some operations to trigger events
  print('Creating notes...');
  final note1 = await client.createNote(
    CreateNoteRequest(title: 'First Note', content: 'This is the first note'),
  );
  print('Created: ${note1.note.title}\n');

  await Future.delayed(const Duration(seconds: 1));

  final note2 = await client.createNote(
    CreateNoteRequest(title: 'Second Note', content: 'This is the second note'),
  );
  print('Created: ${note2.note.title}\n');

  await Future.delayed(const Duration(seconds: 1));

  print('Updating first note...');
  await client.updateNote(
    UpdateNoteRequest(
      id: note1.note.id,
      title: 'Updated First Note',
      content: 'This note has been updated',
    ),
  );

  await Future.delayed(const Duration(seconds: 1));

  print('Deleting second note...');
  await client.deleteNote(DeleteNoteRequest(id: note2.note.id));

  // Wait a bit to see the events
  await Future.delayed(const Duration(seconds: 2));

  print('\nShutting down...');
  await channel.shutdown();
  await watchTask;
}

/// Watches for note changes and prints events
Future<void> _watchNotes(NoteServiceClient client) async {
  try {
    final stream = client.watchNotes(WatchNotesRequest());

    await for (final event in stream) {
      final eventType = switch (event.eventType) {
        NoteEventType.CREATED => 'CREATED',
        NoteEventType.UPDATED => 'UPDATED',
        NoteEventType.DELETED => 'DELETED',
        _ => 'UNKNOWN',
      };

      print('📡 Event: $eventType');
      print('   Note ID: ${event.note.id}');
      print('   Title: ${event.note.title}');
      print(
        '   Timestamp: ${DateTime.fromMillisecondsSinceEpoch(event.timestamp.toInt())}',
      );
      print('');
    }
  } catch (e) {
    print('Watch stream error: $e');
  }
}
