# gRPC Note API Server

A high-performance gRPC-based note management API server implemented in Dart. This server provides remote procedure call interfaces for creating, reading, updating, and deleting notes with support for concurrent operations.

## Features

- **Full CRUD Operations**: Create, read, update, and delete notes via gRPC
- **Protocol Buffers**: Strongly-typed API definitions using Protocol Buffers
- **Concurrent Access**: Thread-safe operations supporting 100+ concurrent connections
- **In-Memory Storage**: Fast in-memory data storage with UUID-based identifiers
- **Error Handling**: Comprehensive error handling with proper gRPC status codes
- **Example Client**: Fully functional example client demonstrating all operations

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Generating Code from Proto Files](#generating-code-from-proto-files)
- [Running the Server](#running-the-server)
- [Running the Example Client](#running-the-example-client)
- [API Documentation](#api-documentation)
- [Configuration Options](#configuration-options)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Development](#development)

## Prerequisites

Before you begin, ensure you have the following installed:

- **Dart SDK**: Version 3.9.0 or higher
  - Install from: https://dart.dev/get-dart
  - Verify installation: `dart --version`

- **Protocol Buffer Compiler (protoc)**: Required for generating Dart code from `.proto` files
  - **macOS**: `brew install protobuf`
  - **Linux**: `sudo apt-get install protobuf-compiler`
  - **Windows**: Download from https://github.com/protocolbuffers/protobuf/releases
  - Verify installation: `protoc --version`

- **Dart Protocol Buffer Plugin**: Install globally
  ```bash
  dart pub global activate protoc_plugin
  ```
  - Add to PATH: `export PATH="$PATH:$HOME/.pub-cache/bin"`

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd grpc_note_server
   ```

2. Install dependencies:
   ```bash
   dart pub get
   ```

3. Generate Dart code from Protocol Buffers (see next section)

## Generating Code from Proto Files

The project uses Protocol Buffers to define the gRPC service interface. Whenever you modify the `.proto` files, you need to regenerate the Dart code.

### Generate Command

```bash
protoc --dart_out=grpc:lib/generated -Iprotos protos/note_service.proto
```

### What This Does

- `--dart_out=grpc:lib/generated`: Generates Dart code with gRPC support in the `lib/generated` directory
- `-Iprotos`: Specifies the import path for proto files
- `protos/note_service.proto`: The proto file to compile

### Generated Files

The command generates the following files in `lib/generated/`:
- `note_service.pb.dart`: Protocol Buffer message classes
- `note_service.pbgrpc.dart`: gRPC service stubs and client
- `note_service.pbenum.dart`: Enum definitions (if any)
- `note_service.pbjson.dart`: JSON encoding support

## Running the Server

### Start the Server

**With In-Memory Storage (Default):**
```bash
dart run bin/server.dart
```

**With PostgreSQL Storage:**
```bash
# Set environment variable
export STORAGE_TYPE=postgres

# Or inline
STORAGE_TYPE=postgres dart run bin/server.dart
```

### Expected Output

```
INFO: 2025-11-09 11:51:07.060: Note Server started successfully
INFO: 2025-11-09 11:51:07.061: Listening on port 50051
INFO: 2025-11-09 11:51:07.061: Ready to accept connections
INFO: 2025-11-09 11:51:07.061: Server is running with memory storage. Press Ctrl+C to stop.
```

### Server Configuration

The server runs with the following default configuration:
- **Port**: 50051 (configurable via `GRPC_PORT`)
- **Host**: 0.0.0.0 (all interfaces)
- **Concurrent Connections**: 100+
- **Storage**: In-memory or PostgreSQL (configurable via `STORAGE_TYPE`)

### Stopping the Server

Press `Ctrl+C` to gracefully shutdown the server. The server handles SIGINT and SIGTERM signals for clean shutdown.

## Running the Example Client

The project includes a fully functional example client that demonstrates all CRUD operations.

### Start the Client

Make sure the server is running first, then:

```bash
dart run bin/client.dart
```

### What the Client Does

The example client demonstrates:
1. Creating notes with valid data
2. Creating notes with invalid data (error handling)
3. Listing all notes
4. Retrieving specific notes by ID
5. Retrieving non-existent notes (error handling)
6. Updating existing notes
7. Updating non-existent notes (error handling)
8. Deleting notes
9. Deleting non-existent notes (error handling)

### Example Output

```
=== gRPC Note API Client Example ===

1. Creating first note...
   ✓ Note created successfully!
   ID: 550e8400-e29b-41d4-a716-446655440000
   Title: My First Note
   Content: This is the content of my first note.
   Created: 2024-01-15 10:30:45.123

2. Creating second note...
   ✓ Note created successfully!
   ID: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
   Title: Shopping List

...
```

## API Documentation

### Service Definition

The `NoteService` provides the following RPC methods:

#### 1. CreateNote

Creates a new note with the provided title and content.

**Request:**
```protobuf
message CreateNoteRequest {
  string title = 1;    // Note title
  string content = 2;  // Note content
}
```

**Response:**
```protobuf
message CreateNoteResponse {
  Note note = 1;  // Created note with ID and timestamps
}
```

**Example (Dart):**
```dart
final request = CreateNoteRequest()
  ..title = 'My Note'
  ..content = 'Note content here';

final response = await client.createNote(request);
print('Created note ID: ${response.note.id}');
```

**Error Cases:**
- `INVALID_ARGUMENT`: Empty title and empty content

---

#### 2. GetNote

Retrieves a note by its unique identifier.

**Request:**
```protobuf
message GetNoteRequest {
  string id = 1;  // Note ID (UUID format)
}
```

**Response:**
```protobuf
message GetNoteResponse {
  Note note = 1;  // The requested note
}
```

**Example (Dart):**
```dart
final request = GetNoteRequest()..id = 'note-uuid-here';
final response = await client.getNote(request);
print('Title: ${response.note.title}');
```

**Error Cases:**
- `NOT_FOUND`: Note with specified ID does not exist

---

#### 3. ListNotes

Retrieves all notes stored in the system.

**Request:**
```protobuf
message ListNotesRequest {
  // No parameters
}
```

**Response:**
```protobuf
message ListNotesResponse {
  repeated Note notes = 1;  // List of all notes
}
```

**Example (Dart):**
```dart
final request = ListNotesRequest();
final response = await client.listNotes(request);
for (var note in response.notes) {
  print('${note.title}: ${note.content}');
}
```

---

#### 4. UpdateNote

Updates an existing note's title and content.

**Request:**
```protobuf
message UpdateNoteRequest {
  string id = 1;       // Note ID to update
  string title = 2;    // New title
  string content = 3;  // New content
}
```

**Response:**
```protobuf
message UpdateNoteResponse {
  Note note = 1;  // Updated note with new timestamp
}
```

**Example (Dart):**
```dart
final request = UpdateNoteRequest()
  ..id = 'note-uuid-here'
  ..title = 'Updated Title'
  ..content = 'Updated content';

final response = await client.updateNote(request);
print('Updated at: ${response.note.updatedAt}');
```

**Error Cases:**
- `NOT_FOUND`: Note with specified ID does not exist
- `INVALID_ARGUMENT`: Empty title and empty content

---

#### 5. DeleteNote

Removes a note from the system.

**Request:**
```protobuf
message DeleteNoteRequest {
  string id = 1;  // Note ID to delete
}
```

**Response:**
```protobuf
message DeleteNoteResponse {
  bool success = 1;  // True if deleted successfully
}
```

**Example (Dart):**
```dart
final request = DeleteNoteRequest()..id = 'note-uuid-here';
final response = await client.deleteNote(request);
print('Deleted: ${response.success}');
```

**Error Cases:**
- `NOT_FOUND`: Note with specified ID does not exist

---

### Note Message

All operations work with the `Note` message:

```protobuf
message Note {
  string id = 1;          // UUID v4 identifier
  string title = 2;       // Note title (max 200 chars)
  string content = 3;     // Note content (max 10000 chars)
  int64 created_at = 4;   // Creation timestamp (milliseconds)
  int64 updated_at = 5;   // Last update timestamp (milliseconds)
}
```

### gRPC Status Codes

| Status Code | Description | When It Occurs |
|-------------|-------------|----------------|
| `OK` | Success | Operation completed successfully |
| `INVALID_ARGUMENT` | Invalid input | Empty title and content, or malformed data |
| `NOT_FOUND` | Resource not found | Note ID does not exist |
| `INTERNAL` | Server error | Unexpected server-side error |

## Configuration Options

### Server Configuration

The server can be configured by modifying `bin/server.dart`:

```dart
// Change the port
const port = 50051;  // Default: 50051

// The server automatically configures:
// - Concurrent connections: 100+
// - Graceful shutdown handling
// - Signal handlers (SIGINT, SIGTERM)
```

### Storage Options

The server supports two storage backends:

#### 1. In-Memory Storage (Default)
- Fast and simple
- No setup required
- Data is lost on server restart
- Perfect for development and testing

```bash
dart run bin/server.dart
# or explicitly
STORAGE_TYPE=memory dart run bin/server.dart
```

#### 2. PostgreSQL Storage
- Persistent storage
- Production-ready
- Full-text search support
- Requires PostgreSQL database

```bash
STORAGE_TYPE=postgres dart run bin/server.dart
```

### PostgreSQL Setup

#### Using Docker (Recommended)

1. Start PostgreSQL with Docker Compose:
```bash
docker-compose up -d
```

2. Verify PostgreSQL is running:
```bash
docker-compose ps
```

3. Run the server with PostgreSQL:
```bash
STORAGE_TYPE=postgres dart run bin/server.dart
```

#### Manual PostgreSQL Setup

1. Install PostgreSQL (version 12+)
2. Create database:
```sql
CREATE DATABASE notes_db;
```

3. Run migration:
```bash
psql -U postgres -d notes_db -f migrations/001_create_notes_table.sql
```

4. Configure environment variables (see `.env.example`)

### Logging Configuration

The server uses the `logging` package for structured logging. You can configure the log level in `bin/server.dart`:

```dart
// Set log level (ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT, OFF)
Logger.root.level = Level.INFO;  // Change to Level.ALL for verbose logging
```

Log levels:
- `Level.INFO`: Standard operational messages (default)
- `Level.WARNING`: Warning messages and signal handling
- `Level.SEVERE`: Error messages
- `Level.ALL`: All messages including debug info

### Environment Variables

The server supports the following environment variables:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `STORAGE_TYPE` | Storage backend ('memory' or 'postgres') | `memory` | No |
| `GRPC_PORT` | gRPC server port | `50051` | No |
| `DB_HOST` | PostgreSQL host | `localhost` | Only for postgres |
| `DB_PORT` | PostgreSQL port | `5432` | Only for postgres |
| `DB_NAME` | Database name | `notes_db` | Only for postgres |
| `DB_USER` | Database user | `postgres` | Only for postgres |
| `DB_PASSWORD` | Database password | `postgres` | Only for postgres |
| `DB_MAX_CONNECTIONS` | Max connection pool size | `10` | No |
| `DB_USE_SSL` | Enable SSL for database | `false` | No |

**Example:**
```bash
export STORAGE_TYPE=postgres
export DB_HOST=localhost
export DB_PASSWORD=mysecretpassword
dart run bin/server.dart
```

### Client Configuration

To connect to a different server, modify `bin/client.dart`:

```dart
final channel = ClientChannel(
  'localhost',  // Change to your server host
  port: 50051,  // Change to your server port
  options: const ChannelOptions(
    credentials: ChannelCredentials.insecure(),  // Use .secure() for TLS
  ),
);
```

## Project Structure

```
grpc_note_server/
├── protos/
│   └── note_service.proto          # Protocol Buffer definitions
├── lib/
│   ├── generated/                  # Generated gRPC/protobuf code
│   │   ├── note_service.pb.dart
│   │   ├── note_service.pbgrpc.dart
│   │   ├── note_service.pbenum.dart
│   │   └── note_service.pbjson.dart
│   ├── models/
│   │   └── note.dart              # Note domain model
│   ├── repositories/
│   │   └── note_repository.dart   # Data access layer
│   ├── services/
│   │   └── note_service_impl.dart # gRPC service implementation
│   └── server.dart                # Server setup and configuration
├── bin/
│   ├── server.dart                # Server entry point
│   └── client.dart                # Example client
├── test/
│   ├── repositories/
│   │   └── note_repository_test.dart
│   ├── services/
│   │   └── note_service_impl_test.dart
│   └── integration_test.dart
├── pubspec.yaml                   # Dart dependencies
└── README.md                      # This file
```

## Testing

### Run All Tests

```bash
dart test
```

### Run Specific Test Files

```bash
# Repository tests
dart test test/repositories/note_repository_test.dart

# Service tests
dart test test/services/note_service_impl_test.dart

# Integration tests
dart test test/integration_test.dart
```

### Test Coverage

The project includes:
- **Unit Tests**: Repository and service layer tests
- **Integration Tests**: End-to-end tests with real gRPC client/server
- **Concurrent Tests**: Tests for thread-safe operations

## Development

### Adding New RPC Methods

1. Update `protos/note_service.proto` with new message types and RPC method
2. Regenerate Dart code: `protoc --dart_out=grpc:lib/generated -Iprotos protos/note_service.proto`
3. Implement the method in `lib/services/note_service_impl.dart`
4. Add repository methods if needed in `lib/repositories/note_repository.dart`
5. Write tests for the new functionality
6. Update this README with API documentation

### Code Style

The project follows Dart's official style guide:
- Run linter: `dart analyze`
- Format code: `dart format .`

### Dependencies

Key dependencies (see `pubspec.yaml` for versions):
- `grpc`: gRPC framework for Dart
- `protobuf`: Protocol Buffer runtime
- `postgres`: PostgreSQL database driver
- `uuid`: UUID generation
- `fixnum`: Fixed-width integer types for protobuf
- `logging`: Structured logging framework

## Troubleshooting

### "protoc: command not found"

Install the Protocol Buffer compiler:
- macOS: `brew install protobuf`
- Linux: `sudo apt-get install protobuf-compiler`

### "protoc-gen-dart: program not found"

Install and activate the Dart protoc plugin:
```bash
dart pub global activate protoc_plugin
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### "Failed to connect to server"

Ensure the server is running:
```bash
dart run bin/server.dart
```

Check that the port (50051) is not blocked by firewall.

### "Port already in use"

Another process is using port 50051. Either:
- Stop the other process
- Change the port: `GRPC_PORT=50052 dart run bin/server.dart`

### "Failed to connect to PostgreSQL"

Ensure PostgreSQL is running:
```bash
# Check if PostgreSQL is running
docker-compose ps

# Or check manually
psql -U postgres -h localhost -c "SELECT 1"
```

If using Docker, start it:
```bash
docker-compose up -d
```

### "Database connection test failed"

Check your database credentials:
```bash
# Test connection manually
psql -U postgres -h localhost -d notes_db

# Check environment variables
echo $DB_HOST $DB_PORT $DB_NAME $DB_USER
```

### PostgreSQL Performance Issues

For production, tune these settings:
- Increase `DB_MAX_CONNECTIONS` for high concurrency
- Enable connection pooling
- Add database indexes (already included in migration)
- Use `DB_USE_SSL=true` for secure connections

## License

This project is provided as-is for educational and development purposes.

## Contributing

Contributions are welcome! Please ensure:
- All tests pass: `dart test`
- Code is formatted: `dart format .`
- No lint errors: `dart analyze`
- New features include tests and documentation

