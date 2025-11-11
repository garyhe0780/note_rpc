# gRPC Server Streaming Guide

This guide explains how to use the real-time note update streaming feature in the Note Service.

## Overview

The Note Service implements gRPC server streaming through the `WatchNotes` RPC method, allowing clients to receive real-time updates whenever notes are created, updated, or deleted.

## Features

- **Real-time Updates**: Receive instant notifications when notes change
- **Event Types**: Support for CREATE, UPDATE, and DELETE events
- **Filtering**: Optional filtering by specific note ID
- **Timestamps**: Each event includes a timestamp
- **Broadcast Support**: Multiple clients can watch simultaneously

## Protocol Definition

```protobuf
// Watch for real-time note updates
rpc WatchNotes(WatchNotesRequest) returns (stream NoteEvent);

message WatchNotesRequest {
  string note_id = 1;  // Optional: filter by specific note ID
}

enum NoteEventType {
  UNKNOWN = 0;
  CREATED = 1;
  UPDATED = 2;
  DELETED = 3;
}

message NoteEvent {
  NoteEventType event_type = 1;
  Note note = 2;
  int64 timestamp = 3;
}
```

## Usage Examples

### Basic Streaming Client

```dart
import 'package:grpc/grpc.dart';
import 'lib/generated/note_service.pbgrpc.dart';

Future<void> watchAllNotes() async {
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
    ),
  );

  final client = NoteServiceClient(channel);

  // Watch all note changes
  final stream = client.watchNotes(WatchNotesRequest());

  await for (final event in stream) {
    print('Event: ${event.eventType}');
    print('Note: ${event.note.title}');
    print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(event.timestamp.toInt())}');
  }

  await channel.shutdown();
}
```

### Filtering by Note ID

```dart
// Watch changes for a specific note only
final stream = client.watchNotes(
  WatchNotesRequest(noteId: 'specific-note-id'),
);

await for (final event in stream) {
  // Only receive events for the specified note
  handleEvent(event);
}
```

### Handling Different Event Types

```dart
await for (final event in stream) {
  switch (event.eventType) {
    case NoteEventType.CREATED:
      print('New note created: ${event.note.title}');
      break;
    case NoteEventType.UPDATED:
      print('Note updated: ${event.note.title}');
      break;
    case NoteEventType.DELETED:
      print('Note deleted: ${event.note.id}');
      break;
    default:
      print('Unknown event type');
  }
}
```

### Running the Demo Client

A complete example client is provided in `bin/streaming_client.dart`:

```bash
# Start the server
dart run bin/server.dart

# In another terminal, run the streaming client
dart run bin/streaming_client.dart
```

The demo client will:
1. Start watching for note changes
2. Create two notes
3. Update one note
4. Delete one note
5. Display all events in real-time

## Implementation Details

### Repository Layer

The repository layer implements a broadcast stream controller that emits change events:

```dart
class NoteChangeEvent {
  final NoteChangeType type;  // created, updated, deleted
  final Note note;
  final DateTime timestamp;
}

abstract class NoteRepository {
  Stream<NoteChangeEvent> get changeStream;
  // ... other methods
}
```

Both `InMemoryNoteRepository` and `PostgresNoteRepository` emit events whenever notes are modified.

### Service Layer

The `NoteServiceImpl` subscribes to the repository's change stream and converts events to protobuf messages:

```dart
@override
Stream<NoteEvent> watchNotes(ServiceCall call, WatchNotesRequest request) async* {
  await for (final change in _repository.changeStream) {
    // Filter by note ID if specified
    if (noteId != null && change.note.id != noteId) continue;
    
    // Convert and yield event
    yield NoteEvent(
      eventType: convertEventType(change.type),
      note: change.note.toProto(),
      timestamp: Int64(change.timestamp.millisecondsSinceEpoch),
    );
  }
}
```

## Best Practices

### Client-Side

1. **Handle Connection Errors**: Implement retry logic for disconnections
2. **Timeout Management**: Set appropriate deadlines for long-running streams
3. **Resource Cleanup**: Always close channels when done
4. **Backpressure**: Handle events asynchronously to avoid blocking the stream

```dart
try {
  await for (final event in stream) {
    // Process event asynchronously
    unawaited(processEvent(event));
  }
} on GrpcError catch (e) {
  if (e.code == StatusCode.unavailable) {
    // Implement reconnection logic
    await reconnect();
  }
}
```

### Server-Side

1. **Memory Management**: The broadcast stream controller handles multiple subscribers efficiently
2. **Filtering**: Apply filters early to reduce network traffic
3. **Error Handling**: Wrap stream logic in try-catch to prevent stream termination
4. **Cleanup**: Dispose of stream controllers when shutting down

## Testing

The streaming functionality includes comprehensive tests in `test/services/note_service_streaming_test.dart`:

```bash
# Run streaming tests
dart test test/services/note_service_streaming_test.dart
```

Tests cover:
- Creation events
- Update events
- Deletion events
- Note ID filtering
- Timestamp accuracy
- Multiple concurrent watchers

## Performance Considerations

- **Broadcast Streams**: Multiple clients can watch without duplicating repository operations
- **Efficient Filtering**: Note ID filtering happens at the service layer
- **Memory Usage**: Events are not buffered; clients receive only new events
- **Scalability**: The in-memory implementation is suitable for moderate loads; PostgreSQL implementation can scale further

## Troubleshooting

### Stream Not Receiving Events

1. Verify the server is running and accessible
2. Check that operations are being performed after the watch starts
3. Ensure note ID filter (if used) matches the notes being modified

### Connection Timeouts

1. Adjust channel options for longer-running streams
2. Implement keep-alive pings
3. Handle reconnection gracefully

### Memory Leaks

1. Always close channels when done
2. Cancel stream subscriptions properly
3. Dispose of repository instances on shutdown

## Future Enhancements

Potential improvements for the streaming feature:

- **Replay Support**: Allow clients to receive historical events
- **Batch Events**: Group multiple rapid changes into batches
- **Filtering Options**: Add more sophisticated filtering (by title, date range, etc.)
- **Compression**: Enable stream compression for large payloads
- **Authentication**: Add token-based authentication for streams
- **Rate Limiting**: Implement per-client rate limits

## Related Documentation

- [README.md](README.md) - Main project documentation
- [ERROR_CODES.md](ERROR_CODES.md) - Error handling reference
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Implementation details
