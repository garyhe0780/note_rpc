import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
import 'database_config.dart';

/// Factory for creating and managing PostgreSQL database connections.
class DatabaseConnection {
  static final _logger = Logger('DatabaseConnection');

  /// Creates a new PostgreSQL connection using the provided configuration.
  static Future<Connection> connect(DatabaseConfig config) async {
    _logger.info(
      'Connecting to PostgreSQL database at ${config.host}:${config.port}',
    );

    try {
      final endpoint = Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      );

      final connection = await Connection.open(
        endpoint,
        settings: ConnectionSettings(
          sslMode: config.useSSL ? SslMode.require : SslMode.disable,
          connectTimeout: const Duration(seconds: 10),
          queryTimeout: const Duration(seconds: 30),
        ),
      );

      _logger.info('Successfully connected to PostgreSQL database');
      return connection;
    } catch (e) {
      _logger.severe('Failed to connect to PostgreSQL database', e);
      rethrow;
    }
  }

  /// Creates a connection pool for better performance with concurrent requests.
  static Future<Pool> createPool(DatabaseConfig config) async {
    _logger.info(
      'Creating PostgreSQL connection pool (max: ${config.maxConnections})',
    );

    try {
      final endpoint = Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      );

      final pool = Pool.withEndpoints(
        [endpoint],
        settings: PoolSettings(
          maxConnectionCount: config.maxConnections,
          sslMode: config.useSSL ? SslMode.require : SslMode.disable,
          connectTimeout: const Duration(seconds: 10),
          queryTimeout: const Duration(seconds: 30),
        ),
      );

      _logger.info('Successfully created PostgreSQL connection pool');
      return pool;
    } catch (e) {
      _logger.severe('Failed to create PostgreSQL connection pool', e);
      rethrow;
    }
  }

  /// Tests the database connection.
  static Future<bool> testConnection(DatabaseConfig config) async {
    _logger.info('Testing database connection...');

    try {
      final connection = await connect(config);
      try {
        final result = await connection.execute('SELECT 1');
        _logger.info('Database connection test successful');
        return result.isNotEmpty;
      } finally {
        await connection.close();
      }
    } catch (e) {
      _logger.severe('Database connection test failed', e);
      return false;
    }
  }
}
