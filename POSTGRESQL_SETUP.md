# PostgreSQL Setup Guide

Complete guide for setting up and using PostgreSQL with the gRPC Note Server.

## Quick Start

### Option 1: Docker (Recommended)

1. **Start PostgreSQL:**
```bash
docker-compose up -d
```

2. **Run the server:**
```bash
STORAGE_TYPE=postgres dart run bin/server.dart
```

That's it! The server will automatically create the schema on first run.

### Option 2: Local PostgreSQL Installation

1. **Install PostgreSQL** (version 12 or higher)
   - macOS: `brew install postgresql@16`
   - Ubuntu: `sudo apt-get install postgresql-16`
   - Windows: Download from https://www.postgresql.org/download/

2. **Start PostgreSQL service:**
```bash
# macOS
brew services start postgresql@16

# Ubuntu
sudo systemctl start postgresql

# Windows
# Use Services app or pg_ctl
```

3. **Create database:**
```bash
createdb notes_db
```

4. **Run migration:**
```bash
psql -d notes_db -f migrations/001_create_notes_table.sql
```

5. **Run the server:**
```bash
STORAGE_TYPE=postgres dart run bin/server.dart
```

## Configuration

### Environment Variables

Create a `.env` file (copy from `.env.example`):

```bash
# Server Configuration
GRPC_PORT=50051
STORAGE_TYPE=postgres

# PostgreSQL Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=notes_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_MAX_CONNECTIONS=10
DB_USE_SSL=false
```

### Production Configuration

For production environments:

```bash
# Use strong password
DB_PASSWORD=your_secure_password_here

# Enable SSL
DB_USE_SSL=true

# Increase connection pool
DB_MAX_CONNECTIONS=20

# Use remote host
DB_HOST=your-postgres-server.com
```

## Database Schema

The notes table structure:

```sql
CREATE TABLE notes (
    id VARCHAR(36) PRIMARY KEY,           -- UUID v4
    title TEXT NOT NULL,                  -- Note title
    content TEXT NOT NULL,                -- Note content
    created_at TIMESTAMP NOT NULL,        -- Creation timestamp
    updated_at TIMESTAMP NOT NULL         -- Last update timestamp
);

-- Indexes for performance
CREATE INDEX idx_notes_created_at ON notes(created_at DESC);
CREATE INDEX idx_notes_search ON notes USING gin(to_tsvector('english', title || ' ' || content));
```

### Indexes

1. **idx_notes_created_at**: Speeds up listing notes by creation date
2. **idx_notes_search**: Enables full-text search on title and content

## Features

### 1. Automatic Schema Creation

The server automatically creates the schema on startup:

```dart
await (repository as PostgresNoteRepository).initialize();
```

### 2. Connection Testing

The server tests the database connection before starting:

```dart
final connectionOk = await DatabaseConnection.testConnection(dbConfig);
```

### 3. Full-Text Search Support

The schema includes a GIN index for full-text search:

```sql
CREATE INDEX idx_notes_search 
ON notes USING gin(to_tsvector('english', title || ' ' || content));
```

Future enhancement: Add search RPC method to leverage this index.

### 4. Connection Pooling

The implementation supports connection pooling for better performance:

```dart
final pool = await DatabaseConnection.createPool(config);
```

## Performance Tuning

### Connection Pool Size

Adjust based on your workload:

```bash
# Light load (< 50 concurrent users)
DB_MAX_CONNECTIONS=5

# Medium load (50-200 concurrent users)
DB_MAX_CONNECTIONS=10

# Heavy load (200+ concurrent users)
DB_MAX_CONNECTIONS=20
```

### PostgreSQL Configuration

Edit `postgresql.conf` for production:

```conf
# Increase max connections
max_connections = 100

# Tune memory
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB

# Enable query logging (for debugging)
log_statement = 'all'
log_duration = on
```

### Monitoring

Monitor database performance:

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('notes'));

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE tablename = 'notes';

-- Slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## Backup and Restore

### Backup

```bash
# Backup entire database
pg_dump notes_db > backup.sql

# Backup with compression
pg_dump notes_db | gzip > backup.sql.gz

# Backup only data
pg_dump --data-only notes_db > data_backup.sql
```

### Restore

```bash
# Restore from backup
psql notes_db < backup.sql

# Restore from compressed backup
gunzip -c backup.sql.gz | psql notes_db
```

### Automated Backups

Add to crontab:

```bash
# Daily backup at 2 AM
0 2 * * * pg_dump notes_db | gzip > /backups/notes_$(date +\%Y\%m\%d).sql.gz
```

## Migration Management

### Current Migration

- `001_create_notes_table.sql`: Initial schema

### Adding New Migrations

1. Create new migration file:
```bash
touch migrations/002_add_tags_column.sql
```

2. Write migration:
```sql
-- Migration: Add tags support
ALTER TABLE notes ADD COLUMN tags TEXT[];
CREATE INDEX idx_notes_tags ON notes USING gin(tags);
```

3. Apply migration:
```bash
psql -d notes_db -f migrations/002_add_tags_column.sql
```

## Docker Management

### Useful Commands

```bash
# Start PostgreSQL
docker-compose up -d

# Stop PostgreSQL
docker-compose down

# View logs
docker-compose logs -f postgres

# Access PostgreSQL shell
docker-compose exec postgres psql -U postgres -d notes_db

# Restart PostgreSQL
docker-compose restart postgres

# Remove all data (WARNING: destructive)
docker-compose down -v
```

### Docker Compose Configuration

The `docker-compose.yml` includes:
- PostgreSQL 16 Alpine (lightweight)
- Persistent volume for data
- Health checks
- Auto-initialization from migrations folder

## Security Best Practices

### 1. Use Strong Passwords

```bash
# Generate secure password
openssl rand -base64 32
```

### 2. Enable SSL/TLS

```bash
DB_USE_SSL=true
```

### 3. Restrict Network Access

In `postgresql.conf`:
```conf
listen_addresses = 'localhost'  # Only local connections
```

Or use firewall rules:
```bash
# Allow only specific IP
sudo ufw allow from 192.168.1.100 to any port 5432
```

### 4. Use Read-Only Users

For reporting/analytics:
```sql
CREATE USER readonly WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE notes_db TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
```

## Troubleshooting

### Connection Refused

```bash
# Check if PostgreSQL is running
pg_isready -h localhost -p 5432

# Check PostgreSQL logs
docker-compose logs postgres
# or
tail -f /var/log/postgresql/postgresql-16-main.log
```

### Authentication Failed

```bash
# Check pg_hba.conf
cat /etc/postgresql/16/main/pg_hba.conf

# Should have:
# local   all   postgres   trust
# host    all   all        127.0.0.1/32   md5
```

### Out of Connections

```sql
-- Check current connections
SELECT count(*) FROM pg_stat_activity;

-- Kill idle connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
AND state_change < now() - interval '5 minutes';
```

### Slow Queries

```sql
-- Enable slow query logging
ALTER DATABASE notes_db SET log_min_duration_statement = 1000; -- 1 second

-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM notes WHERE title LIKE '%search%';
```

## Testing

### Test Database Connection

```bash
# From command line
psql -h localhost -U postgres -d notes_db -c "SELECT 1"

# From Dart
STORAGE_TYPE=postgres dart run bin/server.dart
```

### Load Testing

```bash
# Install ghz (gRPC load testing tool)
brew install ghz

# Run load test
ghz --insecure \
  --proto protos/note_service.proto \
  --call note.NoteService/CreateNote \
  -d '{"title":"Test","content":"Content"}' \
  -n 1000 \
  -c 10 \
  localhost:50051
```

## Production Deployment

### Recommended Setup

1. **Use managed PostgreSQL** (AWS RDS, Google Cloud SQL, Azure Database)
2. **Enable SSL/TLS** for all connections
3. **Set up automated backups** (daily minimum)
4. **Monitor performance** (CloudWatch, Datadog, etc.)
5. **Use connection pooling** (PgBouncer for very high loads)
6. **Implement read replicas** for read-heavy workloads

### Example Production Configuration

```bash
# Production environment variables
STORAGE_TYPE=postgres
DB_HOST=prod-postgres.abc123.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=notes_production
DB_USER=notes_app
DB_PASSWORD=<secure-password-from-secrets-manager>
DB_MAX_CONNECTIONS=20
DB_USE_SSL=true
```

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [postgres Dart Package](https://pub.dev/packages/postgres)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Docker PostgreSQL](https://hub.docker.com/_/postgres)

