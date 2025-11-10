# Quick Start Guide

## 🚀 Get Started in 30 Seconds

### Option 1: In-Memory Storage (No Setup)

```bash
# Install dependencies
dart pub get

# Run server
dart run bin/server.dart

# Test with client (in another terminal)
dart run bin/client.dart
```

Done! ✅

---

### Option 2: PostgreSQL Storage

```bash
# 1. Start PostgreSQL
docker-compose up -d

# 2. Run server with PostgreSQL
STORAGE_TYPE=postgres dart run bin/server.dart

# 3. Test with client
dart run bin/client.dart
```

Done! ✅

---

## 📋 Common Commands

### Server

```bash
# In-memory storage (default)
dart run bin/server.dart

# PostgreSQL storage
STORAGE_TYPE=postgres dart run bin/server.dart

# Custom port
GRPC_PORT=50052 dart run bin/server.dart

# Custom database
STORAGE_TYPE=postgres DB_HOST=mydb.com DB_PASSWORD=secret dart run bin/server.dart
```

### Client

```bash
# Run example client
dart run bin/client.dart
```

### Testing

```bash
# Run all tests
dart test

# Run specific test
dart test test/repositories/note_repository_test.dart

# Check code quality
dart analyze

# Format code
dart format .
```

### Database

```bash
# Start PostgreSQL
docker-compose up -d

# Stop PostgreSQL
docker-compose down

# View logs
docker-compose logs -f

# Access database shell
docker-compose exec postgres psql -U postgres -d notes_db

# Backup database
docker-compose exec postgres pg_dump -U postgres notes_db > backup.sql

# Restore database
docker-compose exec -T postgres psql -U postgres notes_db < backup.sql
```

### Code Generation

```bash
# Regenerate protobuf code
protoc --dart_out=grpc:lib/generated -Iprotos protos/note_service.proto
```

---

## 🔧 Configuration

### Environment Variables

```bash
# Storage type
export STORAGE_TYPE=memory    # or 'postgres'

# Server port
export GRPC_PORT=50051

# Database (only for postgres)
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=notes_db
export DB_USER=postgres
export DB_PASSWORD=postgres
```

### Using .env File

```bash
# 1. Copy example
cp .env.example .env

# 2. Edit .env
nano .env

# 3. Load and run (requires dotenv package or manual export)
export $(cat .env | xargs) && dart run bin/server.dart
```

---

## 📚 Documentation

- **README.md** - Complete project documentation
- **POSTGRESQL_SETUP.md** - PostgreSQL setup guide
- **POSTGRESQL_IMPLEMENTATION.md** - Implementation details
- **DART_3.9_IMPROVEMENTS.md** - Modern Dart syntax used
- **LOGGING_IMPLEMENTATION.md** - Logging framework details

---

## 🐛 Troubleshooting

### Server won't start

```bash
# Check if port is in use
lsof -i :50051

# Use different port
GRPC_PORT=50052 dart run bin/server.dart
```

### Can't connect to PostgreSQL

```bash
# Check if PostgreSQL is running
docker-compose ps

# Check connection
psql -h localhost -U postgres -d notes_db

# View PostgreSQL logs
docker-compose logs postgres
```

### Tests failing

```bash
# Clean and reinstall
dart pub get
dart test
```

---

## 🎯 Next Steps

1. **Read the API docs** in README.md
2. **Try the example client** with `dart run bin/client.dart`
3. **Explore the code** starting with `lib/server.dart`
4. **Set up PostgreSQL** for persistent storage
5. **Build your own client** using the proto definitions

---

## 💡 Tips

- Use **in-memory** for development (fast, no setup)
- Use **PostgreSQL** for production (persistent, scalable)
- Check **logs** for debugging (structured logging enabled)
- Run **tests** before committing (`dart test`)
- Use **Docker** for easy PostgreSQL setup

---

## 🆘 Need Help?

1. Check the **README.md** for detailed documentation
2. Review **POSTGRESQL_SETUP.md** for database issues
3. Look at **example client** in `bin/client.dart`
4. Check **test files** for usage examples

---

## ⚡ Performance Tips

```bash
# Increase database connections for high load
DB_MAX_CONNECTIONS=20 STORAGE_TYPE=postgres dart run bin/server.dart

# Enable verbose logging for debugging
# Edit bin/server.dart: Logger.root.level = Level.ALL

# Use connection pooling (already enabled by default)
```

---

## 🔒 Security Checklist

- [ ] Use strong database password
- [ ] Enable SSL for database (`DB_USE_SSL=true`)
- [ ] Don't commit `.env` file
- [ ] Use secrets manager in production
- [ ] Restrict database network access
- [ ] Keep dependencies updated (`dart pub upgrade`)

---

## 📊 Project Structure

```
grpc_note_server/
├── bin/
│   ├── server.dart          # Server entry point
│   └── client.dart          # Example client
├── lib/
│   ├── config/              # Configuration
│   ├── models/              # Domain models
│   ├── repositories/        # Data access
│   ├── services/            # gRPC services
│   └── server.dart          # Server class
├── protos/
│   └── note_service.proto   # API definition
├── test/                    # Tests
├── migrations/              # Database migrations
└── docker-compose.yml       # PostgreSQL setup
```

---

Happy coding! 🎉
