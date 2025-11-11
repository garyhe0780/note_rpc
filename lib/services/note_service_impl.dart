import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import '../generated/note_service.pbgrpc.dart';
import '../repositories/note_repository.dart';
import '../validation/note_validators.dart';

/// Implementation of the NoteService gRPC service.
/// Handles all RPC methods for note CRUD operations with proper error handling
/// and validation.
class NoteServiceImpl extends NoteServiceBase {
  final NoteRepository _repository;

  NoteServiceImpl(this._repository);

  @override
  Future<CreateNoteResponse> createNote(
    ServiceCall call,
    CreateNoteRequest request,
  ) async {
    try {
      // Validate input using Zod-like validator
      final validationResult = NoteValidators.validateCreate(
        title: request.title,
        content: request.content,
      );

      if (!validationResult.isValid) {
        final errorMessage = validationResult.errors
            .map((e) => '[${e.code.name}] ${e.field}: ${e.message}')
            .join('; ');
        throw GrpcError.invalidArgument(errorMessage);
      }

      final input = validationResult.value;

      // Create note through repository
      final note = await _repository.create(input.title, input.content);

      // Convert domain model to protobuf and return
      return CreateNoteResponse(note: note.toProto());
    } catch (e) {
      if (e is GrpcError) rethrow;
      throw GrpcError.internal('Failed to create note: ${e.toString()}');
    }
  }

  @override
  Future<GetNoteResponse> getNote(
    ServiceCall call,
    GetNoteRequest request,
  ) async {
    try {
      // Retrieve note by ID and return based on result
      return switch (await _repository.getById(request.id)) {
        null => throw GrpcError.notFound(
          'Note with id ${request.id} not found',
        ),
        final note => GetNoteResponse(note: note.toProto()),
      };
    } catch (e) {
      if (e is GrpcError) rethrow;
      throw GrpcError.internal('Failed to get note: ${e.toString()}');
    }
  }

  @override
  Future<ListNotesResponse> listNotes(
    ServiceCall call,
    ListNotesRequest request,
  ) async {
    try {
      // Retrieve all notes
      final notes = await _repository.getAll();

      // Convert all domain models to protobuf messages
      final protoNotes = notes.map((note) => note.toProto()).toList();

      return ListNotesResponse(notes: protoNotes);
    } catch (e) {
      if (e is GrpcError) rethrow;
      throw GrpcError.internal('Failed to list notes: ${e.toString()}');
    }
  }

  @override
  Future<UpdateNoteResponse> updateNote(
    ServiceCall call,
    UpdateNoteRequest request,
  ) async {
    try {
      // Validate input using Zod-like validator
      final validationResult = NoteValidators.validateUpdate(
        id: request.id,
        title: request.title,
        content: request.content,
      );

      if (!validationResult.isValid) {
        final errorMessage = validationResult.errors
            .map((e) => '[${e.code.name}] ${e.field}: ${e.message}')
            .join('; ');
        throw GrpcError.invalidArgument(errorMessage);
      }

      final input = validationResult.value;

      // Update note through repository and return based on result
      return switch (await _repository.update(
        input.id,
        input.title,
        input.content,
      )) {
        null => throw GrpcError.notFound('Note with id ${input.id} not found'),
        final note => UpdateNoteResponse(note: note.toProto()),
      };
    } catch (e) {
      if (e is GrpcError) rethrow;
      throw GrpcError.internal('Failed to update note: ${e.toString()}');
    }
  }

  @override
  Future<DeleteNoteResponse> deleteNote(
    ServiceCall call,
    DeleteNoteRequest request,
  ) async {
    try {
      // Delete note through repository
      final deleted = await _repository.delete(request.id);

      // Return NOT_FOUND if note doesn't exist
      if (!deleted) {
        throw GrpcError.notFound('Note with id ${request.id} not found');
      }

      // Return success response
      return DeleteNoteResponse(success: true);
    } catch (e) {
      if (e is GrpcError) rethrow;
      throw GrpcError.internal('Failed to delete note: ${e.toString()}');
    }
  }

  @override
  Stream<NoteEvent> watchNotes(
    ServiceCall call,
    WatchNotesRequest request,
  ) async* {
    try {
      final noteId = request.noteId.isEmpty ? null : request.noteId;

      // Listen to repository change stream
      await for (final change in _repository.changeStream) {
        // Filter by note ID if specified
        if (noteId != null && change.note.id != noteId) {
          continue;
        }

        // Convert change type to proto event type
        final eventType = switch (change.type) {
          NoteChangeType.created => NoteEventType.CREATED,
          NoteChangeType.updated => NoteEventType.UPDATED,
          NoteChangeType.deleted => NoteEventType.DELETED,
        };

        // Emit the event
        yield NoteEvent(
          eventType: eventType,
          note: change.note.toProto(),
          timestamp: Int64(change.timestamp.millisecondsSinceEpoch),
        );
      }
    } catch (e) {
      if (e is GrpcError) rethrow;
      throw GrpcError.internal('Failed to watch notes: ${e.toString()}');
    }
  }
}
