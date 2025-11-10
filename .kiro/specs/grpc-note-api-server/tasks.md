# Implementation Plan

- [x] 1. Set up project structure and dependencies
  - Create Dart project with proper directory structure
  - Configure pubspec.yaml with grpc, protobuf, uuid dependencies
  - Add dev dependencies for grpc_tools and test packages
  - Create directory structure: protos/, lib/models/, lib/repositories/, lib/services/, bin/
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 2. Define Protocol Buffer schema
  - Create protos/note_service.proto file
  - Define Note message with id, title, content, createdAt, updatedAt fields
  - Define request/response messages for CreateNote, GetNote, ListNotes, UpdateNote, DeleteNote operations
  - Define NoteService with all RPC method signatures
  - Add documentation comments to all messages and service methods
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 3. Generate Dart code from Protocol Buffers
  - Install protoc compiler and Dart plugin
  - Run protoc to generate Dart code from note_service.proto
  - Verify generated files in lib/generated/ directory
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 4. Implement Note domain model
  - Create lib/models/note.dart with Note class
  - Implement constructor with all required fields
  - Add copyWith method for immutable updates
  - Implement toProto method to convert Note to protobuf Note message
  - Implement fromProto factory method to create Note from protobuf message
  - _Requirements: 1.2, 2.5, 3.2_

- [x] 5. Implement Note repository
  - Create lib/repositories/note_repository.dart with abstract interface
  - Implement InMemoryNoteRepository class
  - Add Map<String, Note> for in-memory storage
  - Implement create method with UUID generation and timestamp handling
  - Implement getById method with null return for non-existent notes
  - Implement getAll method returning list of all notes
  - Implement update method with timestamp update and null return for non-existent notes
  - Implement delete method with boolean return indicating success
  - Add proper synchronization for thread-safe concurrent access
  - _Requirements: 1.1, 1.2, 1.5, 2.1, 2.2, 2.3, 2.4, 3.1, 3.5, 4.1, 4.3, 5.1, 5.2_

- [x] 5.1 Write unit tests for repository operations
  - Test create operation with valid data
  - Test getById with existing and non-existent IDs
  - Test getAll with empty and populated storage
  - Test update operation with valid and invalid IDs
  - Test delete operation with valid and invalid IDs
  - Test concurrent access scenarios
  - _Requirements: 1.1, 1.2, 1.5, 2.1, 2.2, 3.1, 3.5, 4.1, 5.1, 5.2_

- [x] 6. Implement gRPC service
  - Create lib/services/note_service_impl.dart extending NoteServiceBase
  - Inject NoteRepository dependency
  - Implement createNote RPC method with input validation
  - Implement getNote RPC method with NOT_FOUND error handling
  - Implement listNotes RPC method
  - Implement updateNote RPC method with validation and error handling
  - Implement deleteNote RPC method with error handling
  - Add proper gRPC status code mapping for all error scenarios
  - Convert between domain models and protobuf messages in all methods
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 5.4_

- [x] 6.1 Write unit tests for gRPC service
  - Test createNote with valid and invalid inputs
  - Test getNote with existing and non-existent IDs
  - Test listNotes with empty and populated data
  - Test updateNote with valid and invalid scenarios
  - Test deleteNote with valid and invalid IDs
  - Verify proper gRPC status codes for all error cases
  - _Requirements: 1.3, 1.4, 2.1, 2.2, 3.3, 3.4, 4.2, 4.3, 5.4_

- [x] 7. Implement server setup and configuration
  - Create lib/server.dart with server initialization logic
  - Configure server to listen on port 50051
  - Register NoteServiceImpl with the server
  - Configure server options for concurrent connections (minimum 100)
  - Implement graceful shutdown handling
  - Create bin/server.dart as entry point
  - Add logging for server startup and shutdown events
  - _Requirements: 5.3, 5.4_

- [x] 8. Create example client for testing
  - Create bin/client.dart with gRPC client setup
  - Implement example calls to all RPC methods (create, get, list, update, delete)
  - Add error handling and response logging
  - Demonstrate complete CRUD workflow
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.3, 3.1, 3.3, 4.1_

- [x] 9. Write integration tests
  - Create test/integration_test.dart
  - Start server in test setup
  - Test complete CRUD workflow using real gRPC client
  - Test concurrent operations from multiple clients
  - Test error scenarios end-to-end
  - Verify proper cleanup in test teardown
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1, 3.3, 3.4, 4.1, 4.2, 5.1, 5.2, 5.3_

- [x] 10. Add documentation and README
  - Create README.md with project overview
  - Document setup instructions including protoc installation
  - Document how to generate code from proto files
  - Document how to run the server
  - Document how to run the example client
  - Add API documentation with example requests/responses
  - Document configuration options
  - _Requirements: 6.5_
