import 'dart:io';
import 'package:grpc_note_server/config/database_config.dart';
import 'package:grpc_note_server/config/database_connection.dart';
import 'package:grpc_note_server/repositories/note_repository.dart';
import 'package:grpc_note_server/server.dart';
import 'package:logging/logging.dart';

/// Entry point for the gRPC Note Server.
/// Initializes the server with default configuration and starts listening.
///
/// Environment Variables:
/// - STORAGE_TYPE: 'memory' or 'postgres' (default: memory)
/// - GRPC_PORT: Server port (default: 50051)
/// - DB_HOST: PostgreSQL host (default: localhost)
/// - DB_PORT: PostgreSQL port (default: 5432)
/// - DB_NAME: Database name (default: notes_db)
/// - DB_USER: Database user (default: postgres)
/// - DB_PASSWORD: Database password (default: postgres)
Future<void> main() async {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });

  final logger = Logger('main');

  // Get configuration from environment
  final storageType = Platform.environment['STORAGE_TYPE'] ?? 'memory';
  final port = int.parse(Platform.environment['GRPC_PORT'] ?? '50051');

  // Initialize repository based on storage type
  final repository = await switch (storageType.toLowerCase()) {
    'postgres' => _initializePostgresRepository(logger),
    _ => _initializeInMemoryRepository(logger),
  };

  // Create and configure server
  final server = NoteServer(port: port, repository: repository);

  // Setup graceful shutdown handlers
  server.setupSignalHandlers();

  // Start the server
  await server.start();

  // Keep the server running
  logger.info(
    'Server is running with $storageType storage. Press Ctrl+C to stop.',
  );
}

/// Initializes PostgreSQL repository with connection testing and schema setup.
Future<NoteRepository> _initializePostgresRepository(Logger logger) async {
  logger.info('Initializing PostgreSQL repository...');
  final dbConfig = DatabaseConfig.fromEnvironment();
  logger.info('Database config: $dbConfig');

  // Test connection first
  final connectionOk = await DatabaseConnection.testConnection(dbConfig);
  if (!connectionOk) {
    logger.severe('Failed to connect to PostgreSQL. Exiting.');
    exit(1);
  }

  // Create connection
  final connection = await DatabaseConnection.connect(dbConfig);
  final repository = PostgresNoteRepository(connection);

  // Initialize database schema
  await repository.initialize();
  logger.info('PostgreSQL repository initialized successfully');

  return repository;
}

/// Initializes in-memory repository for development and testing.
Future<NoteRepository> _initializeInMemoryRepository(Logger logger) async {
  logger.info('Using in-memory repository');
  return InMemoryNoteRepository();
}
