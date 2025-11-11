import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

/// Event types for note changes
enum NoteChangeType { created, updated, deleted }

/// Represents a change event for a note
class NoteChangeEvent {
  final NoteChangeType type;
  final Note note;
  final DateTime timestamp;

  NoteChangeEvent({
    required this.type,
    required this.note,
    required this.timestamp,
  });
}

/// Abstract interface for note data access operations.
/// Implementations should provide thread-safe CRUD operations for notes.
abstract class NoteRepository {
  /// Stream of note change events for real-time updates
  Stream<NoteChangeEvent> get changeStream;

  /// Creates a new note with the given title and content.
  /// Generates a unique ID and timestamps automatically.
  /// Returns the created note.
  Future<Note> create(String title, String content);

  /// Retrieves a note by its unique identifier.
  /// Returns the note if found, null otherwise.
  Future<Note?> getById(String id);

  /// Retrieves all notes from storage.
  /// Returns a list of all notes, or an empty list if none exist.
  Future<List<Note>> getAll();

  /// Updates an existing note with new title and content.
  /// Updates the last modified timestamp automatically.
  /// Returns the updated note if found, null otherwise.
  Future<Note?> update(String id, String title, String content);

  /// Deletes a note by its unique identifier.
  /// Returns true if the note was deleted, false if it didn't exist.
  Future<bool> delete(String id);
}

/// In-memory implementation of NoteRepository.
/// Uses a Map for storage with proper synchronization for thread-safe concurrent access.
class InMemoryNoteRepository implements NoteRepository {
  final Map<String, Note> _storage = {};
  final _uuid = const Uuid();

  // Completer-based lock for synchronization
  Completer<void>? _lock;

  // Stream controller for broadcasting note changes
  final _changeController = StreamController<NoteChangeEvent>.broadcast();

  @override
  Stream<NoteChangeEvent> get changeStream => _changeController.stream;

  /// Emits a change event to all listeners
  void _emitChange(NoteChangeType type, Note note) {
    _changeController.add(
      NoteChangeEvent(type: type, note: note, timestamp: DateTime.now()),
    );
  }

  /// Acquires a lock for thread-safe operations.
  Future<void> _acquireLock() async {
    while (_lock != null) {
      await _lock!.future;
    }
    _lock = Completer<void>();
  }

  /// Releases the lock after operation completion.
  void _releaseLock() {
    final lock = _lock;
    _lock = null;
    lock?.complete();
  }

  @override
  Future<Note> create(String title, String content) async {
    await _acquireLock();
    try {
      final now = DateTime.now();
      final note = Note(
        id: _uuid.v4(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      _storage[note.id] = note;
      _emitChange(NoteChangeType.created, note);
      return note;
    } finally {
      _releaseLock();
    }
  }

  @override
  Future<Note?> getById(String id) async {
    await _acquireLock();
    try {
      return _storage[id];
    } finally {
      _releaseLock();
    }
  }

  @override
  Future<List<Note>> getAll() async {
    await _acquireLock();
    try {
      return [..._storage.values];
    } finally {
      _releaseLock();
    }
  }

  @override
  Future<Note?> update(String id, String title, String content) async {
    await _acquireLock();
    try {
      final existingNote = _storage[id];
      if (existingNote == null) return null;

      final updatedNote = existingNote.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      _storage[id] = updatedNote;
      _emitChange(NoteChangeType.updated, updatedNote);
      return updatedNote;
    } finally {
      _releaseLock();
    }
  }

  @override
  Future<bool> delete(String id) async {
    await _acquireLock();
    try {
      final note = _storage.remove(id);
      if (note != null) {
        _emitChange(NoteChangeType.deleted, note);
        return true;
      }
      return false;
    } finally {
      _releaseLock();
    }
  }

  /// Closes the stream controller
  void dispose() {
    _changeController.close();
  }
}

/// PostgreSQL implementation of NoteRepository.
/// Uses PostgreSQL database for persistent storage with connection pooling.
class PostgresNoteRepository implements NoteRepository {
  final Connection _connection;
  final _uuid = const Uuid();

  // Stream controller for broadcasting note changes
  final _changeController = StreamController<NoteChangeEvent>.broadcast();

  @override
  Stream<NoteChangeEvent> get changeStream => _changeController.stream;

  /// Emits a change event to all listeners
  void _emitChange(NoteChangeType type, Note note) {
    _changeController.add(
      NoteChangeEvent(type: type, note: note, timestamp: DateTime.now()),
    );
  }

  PostgresNoteRepository(this._connection);

  /// Initializes the database schema.
  /// Creates the notes table if it doesn't exist.
  Future<void> initialize() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id VARCHAR(36) PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC)
    ''');

    // Create full-text search index for title and content
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_search 
      ON notes USING gin(to_tsvector('english', title || ' ' || content))
    ''');
  }

  @override
  Future<Note> create(String title, String content) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _connection.execute(
      Sql.named('''
        INSERT INTO notes (id, title, content, created_at, updated_at)
        VALUES (@id, @title, @content, @created_at, @updated_at)
      '''),
      parameters: {
        'id': id,
        'title': title,
        'content': content,
        'created_at': now,
        'updated_at': now,
      },
    );

    final note = Note(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    _emitChange(NoteChangeType.created, note);
    return note;
  }

  @override
  Future<Note?> getById(String id) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM notes WHERE id = @id'),
      parameters: {'id': id},
    );

    return switch (result) {
      [] => null,
      [final row] => _rowToNote(row),
      _ => throw StateError('Multiple notes found with same ID'),
    };
  }

  @override
  Future<List<Note>> getAll() async {
    final result = await _connection.execute(
      'SELECT * FROM notes ORDER BY created_at DESC',
    );

    return result.map(_rowToNote).toList();
  }

  @override
  Future<Note?> update(String id, String title, String content) async {
    final now = DateTime.now();

    final result = await _connection.execute(
      Sql.named('''
        UPDATE notes 
        SET title = @title, content = @content, updated_at = @updated_at
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'title': title,
        'content': content,
        'updated_at': now,
      },
    );

    final note = switch (result) {
      [] => null,
      [final row] => _rowToNote(row),
      _ => throw StateError('Multiple notes updated'),
    };

    if (note != null) {
      _emitChange(NoteChangeType.updated, note);
    }

    return note;
  }

  @override
  Future<bool> delete(String id) async {
    // Get the note before deleting to emit the event
    final note = await getById(id);

    final result = await _connection.execute(
      Sql.named('DELETE FROM notes WHERE id = @id'),
      parameters: {'id': id},
    );

    final deleted = result.affectedRows > 0;
    if (deleted && note != null) {
      _emitChange(NoteChangeType.deleted, note);
    }

    return deleted;
  }

  /// Converts a database row to a Note object.
  Note _rowToNote(ResultRow row) => Note(
    id: row[0] as String,
    title: row[1] as String,
    content: row[2] as String,
    createdAt: row[3] as DateTime,
    updatedAt: row[4] as DateTime,
  );

  /// Closes the database connection and stream controller.
  Future<void> close() async {
    await _changeController.close();
    await _connection.close();
  }
}
