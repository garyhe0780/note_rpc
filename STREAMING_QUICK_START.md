# gRPC Streaming Quick Start

## 30-Second Demo

```bash
# Terminal 1: Start server
dart run bin/server.dart

# Terminal 2: Run streaming demo
dart run bin/streaming_client.dart
```

You'll see real-time events as notes are created, updated, and deleted!

## Basic Client Code

```dart
import 'package:grpc/grpc.dart';
import 'lib/generated/note_service.pbgrpc.dart';

Future<void> main() async {
  // Connect
  final channel = ClientChannel('localhost', port: 50051);
  final client = NoteServiceClient(channel);

  // Watch all notes
  final stream = client.watchNotes(WatchNotesRequest());

  // Handle events
  await for (final event in stream) {
    print('${event.eventType}: ${event.note.title}');
  }

  await channel.shutdown();
}
```

## Event Types

- `CREATED` - New note created
- `UPDATED` - Note modified
- `DELETED` - Note removed

## Filter by Note ID

```dart
// Watch only specific note
final stream = client.watchNotes(
  WatchNotesRequest(noteId: 'your-note-id'),
);
```

## What You Get

Each event includes:
- `eventType` - What happened (CREATED/UPDATED/DELETED)
- `note` - The full note object
- `timestamp` - When it happened (milliseconds)

## Full Documentation

See [STREAMING_GUIDE.md](STREAMING_GUIDE.md) for complete details.
