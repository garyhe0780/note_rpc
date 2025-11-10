import 'package:grpc/grpc.dart';
import 'package:grpc_note_server/generated/note_service.pbgrpc.dart';

/// Example client demonstrating all gRPC note operations
Future<void> main() async {
  // Create gRPC channel to connect to the server
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
    ),
  );

  // Create the note service client
  final client = NoteServiceClient(channel);

  print('=== gRPC Note API Client Example ===\n');

  try {
    // Demonstrate complete CRUD workflow
    await demonstrateCRUDWorkflow(client);
  } catch (e) {
    print('Unexpected error: $e');
  } finally {
    // Clean up and close the channel
    await channel.shutdown();
    print('\n=== Client shutdown complete ===');
  }
}

/// Demonstrates the complete CRUD workflow with all RPC methods
Future<void> demonstrateCRUDWorkflow(NoteServiceClient client) async {
  String? noteId1;
  String? noteId2;

  // 1. CREATE - Create first note
  print('1. Creating first note...');
  try {
    final createRequest1 = CreateNoteRequest()
      ..title = 'My First Note'
      ..content = 'This is the content of my first note.';

    final createResponse1 = await client.createNote(createRequest1);
    noteId1 = createResponse1.note.id;

    print('   ✓ Note created successfully!');
    print('   ID: ${createResponse1.note.id}');
    print('   Title: ${createResponse1.note.title}');
    print('   Content: ${createResponse1.note.content}');
    print(
        '   Created: ${DateTime.fromMillisecondsSinceEpoch(createResponse1.note.createdAt.toInt())}');
    print('');
  } on GrpcError catch (e) {
    print('   ✗ Error creating note: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  // 2. CREATE - Create second note
  print('2. Creating second note...');
  try {
    final createRequest2 = CreateNoteRequest()
      ..title = 'Shopping List'
      ..content = 'Milk, Eggs, Bread, Coffee';

    final createResponse2 = await client.createNote(createRequest2);
    noteId2 = createResponse2.note.id;

    print('   ✓ Note created successfully!');
    print('   ID: ${createResponse2.note.id}');
    print('   Title: ${createResponse2.note.title}');
    print('');
  } on GrpcError catch (e) {
    print('   ✗ Error creating note: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  // 3. CREATE - Test invalid input (empty title and content)
  print('3. Testing invalid input (empty title and content)...');
  try {
    final invalidRequest = CreateNoteRequest()
      ..title = ''
      ..content = '';

    await client.createNote(invalidRequest);
    print('   ✗ Should have failed but succeeded!');
    print('');
  } on GrpcError catch (e) {
    print('   ✓ Correctly rejected invalid input');
    print('   Error: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  // 4. LIST - List all notes
  print('4. Listing all notes...');
  try {
    final listRequest = ListNotesRequest();
    final listResponse = await client.listNotes(listRequest);

    print('   ✓ Found ${listResponse.notes.length} note(s)');
    for (var note in listResponse.notes) {
      print('   - ${note.title} (ID: ${note.id})');
    }
    print('');
  } on GrpcError catch (e) {
    print('   ✗ Error listing notes: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  // 5. GET - Retrieve specific note
  if (noteId1 != null) {
    print('5. Getting note by ID...');
    try {
      final getRequest = GetNoteRequest()..id = noteId1;
      final getResponse = await client.getNote(getRequest);

      print('   ✓ Note retrieved successfully!');
      print('   ID: ${getResponse.note.id}');
      print('   Title: ${getResponse.note.title}');
      print('   Content: ${getResponse.note.content}');
      print('');
    } on GrpcError catch (e) {
      print('   ✗ Error getting note: ${e.message}');
      print('   Status: ${e.code}');
      print('');
    }
  }

  // 6. GET - Test non-existent note
  print('6. Testing retrieval of non-existent note...');
  try {
    final getRequest = GetNoteRequest()..id = 'non-existent-id';
    await client.getNote(getRequest);
    print('   ✗ Should have failed but succeeded!');
    print('');
  } on GrpcError catch (e) {
    print('   ✓ Correctly returned NOT_FOUND error');
    print('   Error: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  // 7. UPDATE - Update existing note
  if (noteId1 != null) {
    print('7. Updating note...');
    try {
      final updateRequest = UpdateNoteRequest()
        ..id = noteId1
        ..title = 'My Updated First Note'
        ..content = 'This content has been updated with new information.';

      final updateResponse = await client.updateNote(updateRequest);

      print('   ✓ Note updated successfully!');
      print('   ID: ${updateResponse.note.id}');
      print('   Title: ${updateResponse.note.title}');
      print('   Content: ${updateResponse.note.content}');
      print(
          '   Updated: ${DateTime.fromMillisecondsSinceEpoch(updateResponse.note.updatedAt.toInt())}');
      print('');
    } on GrpcError catch (e) {
      print('   ✗ Error updating note: ${e.message}');
      print('   Status: ${e.code}');
      print('');
    }
  }

  // 8. UPDATE - Test updating non-existent note
  print('8. Testing update of non-existent note...');
  try {
    final updateRequest = UpdateNoteRequest()
      ..id = 'non-existent-id'
      ..title = 'Updated Title'
      ..content = 'Updated Content';

    await client.updateNote(updateRequest);
    print('   ✗ Should have failed but succeeded!');
    print('');
  } on GrpcError catch (e) {
    print('   ✓ Correctly returned NOT_FOUND error');
    print('   Error: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  // 9. DELETE - Delete a note
  if (noteId2 != null) {
    print('9. Deleting note...');
    try {
      final deleteRequest = DeleteNoteRequest()..id = noteId2;
      final deleteResponse = await client.deleteNote(deleteRequest);

      print('   ✓ Note deleted successfully!');
      print('   Success: ${deleteResponse.success}');
      print('');
    } on GrpcError catch (e) {
      print('   ✗ Error deleting note: ${e.message}');
      print('   Status: ${e.code}');
      print('');
    }
  }

  // 10. DELETE - Test deleting non-existent note
  print('10. Testing deletion of non-existent note...');
  try {
    final deleteRequest = DeleteNoteRequest()..id = 'non-existent-id';
    await client.deleteNote(deleteRequest);
    print('   ✗ Should have failed but succeeded!');
    print('');
  } on GrpcError catch (e) {
    print('   ✓ Correctly returned NOT_FOUND error');
    print('   Error: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  // 11. LIST - Verify final state
  print('11. Final list of notes...');
  try {
    final listRequest = ListNotesRequest();
    final listResponse = await client.listNotes(listRequest);

    print('   ✓ Found ${listResponse.notes.length} note(s) remaining');
    for (var note in listResponse.notes) {
      print('   - ${note.title} (ID: ${note.id})');
    }
    print('');
  } on GrpcError catch (e) {
    print('   ✗ Error listing notes: ${e.message}');
    print('   Status: ${e.code}');
    print('');
  }

  print('=== CRUD workflow demonstration complete ===');
}
