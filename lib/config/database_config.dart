import 'dart:io';

/// Database configuration for PostgreSQL connection.
class DatabaseConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final int maxConnections;
  final bool useSSL;

  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.maxConnections = 10,
    this.useSSL = false,
  });

  /// Creates a DatabaseConfig from environment variables.
  /// Falls back to default values for local development.
  factory DatabaseConfig.fromEnvironment() => DatabaseConfig(
    host: Platform.environment['DB_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
    database: Platform.environment['DB_NAME'] ?? 'notes_db',
    username: Platform.environment['DB_USER'] ?? 'postgres',
    password: Platform.environment['DB_PASSWORD'] ?? 'postgres',
    maxConnections: int.parse(
      Platform.environment['DB_MAX_CONNECTIONS'] ?? '10',
    ),
    useSSL: Platform.environment['DB_USE_SSL']?.toLowerCase() == 'true',
  );

  /// Creates a DatabaseConfig for local development.
  factory DatabaseConfig.development() => const DatabaseConfig(
    host: 'localhost',
    port: 5432,
    database: 'notes_db',
    username: 'postgres',
    password: 'postgres',
    maxConnections: 5,
    useSSL: false,
  );

  @override
  String toString() =>
      'DatabaseConfig(host: $host, port: $port, database: $database, '
      'username: $username, maxConnections: $maxConnections, useSSL: $useSSL)';
}
