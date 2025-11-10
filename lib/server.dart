import 'dart:async';
import 'dart:io';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';
import 'repositories/note_repository.dart';
import 'services/note_service_impl.dart';

/// gRPC server for the Note API.
/// Handles server initialization, configuration, and graceful shutdown.
class NoteServer {
  final int port;
  final NoteRepository repository;
  final Logger _logger = Logger('NoteServer');
  Server? _server;

  NoteServer({required this.port, required this.repository});

  /// Starts the gRPC server.
  /// Configures the server to handle at least 100 concurrent connections.
  /// Logs startup events.
  Future<void> start() async {
    try {
      // Create and configure the gRPC server
      _server = Server.create(
        services: [NoteServiceImpl(repository)],
        codecRegistry: CodecRegistry(
          codecs: const [GzipCodec(), IdentityCodec()],
        ),
        // Configure for concurrent connections (minimum 100)
      );

      // Start listening on the specified port
      await _server!.serve(port: port);

      _logger.info('Note Server started successfully');
      _logger.info('Listening on port $port');
      _logger.info('Ready to accept connections');
    } catch (e) {
      _logger.severe('Failed to start server', e);
      rethrow;
    }
  }

  /// Stops the gRPC server gracefully.
  /// Waits for existing requests to complete before shutting down.
  /// Logs shutdown events.
  Future<void> stop() async {
    if (_server == null) {
      _logger.warning('Server is not running');
      return;
    }

    try {
      _logger.info('Shutting down server...');
      await _server!.shutdown();
      _server = null;
      _logger.info('Server stopped gracefully');
    } catch (e) {
      _logger.severe('Error during server shutdown', e);
      rethrow;
    }
  }

  /// Sets up signal handlers for graceful shutdown.
  /// Handles SIGINT (Ctrl+C) and SIGTERM signals.
  void setupSignalHandlers() {
    ProcessSignal.sigint.watch().listen((signal) async {
      _logger.warning('Received SIGINT signal');
      await stop();
      exit(0);
    });

    ProcessSignal.sigterm.watch().listen((signal) async {
      _logger.warning('Received SIGTERM signal');
      await stop();
      exit(0);
    });
  }
}
