# Validation Error Codes

Complete reference for validation error codes in the gRPC Note API Server.

## Overview

All validation errors now include structured error codes for better error handling and internationalization support.

### Error Response Format

```
[errorCode] field: message
```

**Example:**
```
[tooLong] title: String must be at most 200 characters
```

## Error Codes

### `invalidType`
**Description:** Value has wrong type (e.g., expected string, got number)

**Examples:**
```dart
// Expected string, got number
Z.string().validate(123)
// Error: [invalidType] value: Expected string, got int

// Expected integer, got double
Z.number().int().validate(42.5)
// Error: [invalidType] value: Expected integer, got double
```

**gRPC Response:**
```
code: INVALID_ARGUMENT
message: "[invalidType] value: Expected string, got int"
```

---

### `tooShort`
**Description:** String or array is shorter than minimum length

**Examples:**
```dart
// String too short
Z.string().min(5).validate('hi')
// Error: [tooShort] value: String must be at least 5 characters

// Note title too short (if we had min length)
NoteValidators.title.validate('')
// Would trigger tooShort if min length was set
```

**gRPC Response:**
```
code: INVALID_ARGUMENT
message: "[tooShort] title: String must be at least 5 characters"
```

---

### `tooLong`
**Description:** String or array exceeds maximum length

**Examples:**
```dart
// String too long
Z.string().max(10).validate('hello world!')
// Error: [tooLong] value: String must be at most 10 characters

// Note title too long
NoteValidators.title.validate('a' * 201)
// Error: [tooLong] title: String must be at most 200 characters

// Note content too long
NoteValidators.content.validate('a' * 10001)
// Error: [tooLong] content: String must be at most 10000 characters
```

**gRPC Response:**
```
code: INVALID_ARGUMENT
message: "[tooLong] title: String must be at most 200 characters"
```

---

### `tooSmall`
**Description:** Number is less than minimum value

**Examples:**
```dart
// Number too small
Z.number().minimum(0).validate(-5)
// Error: [tooSmall] value: Number must be at least 0

// Age too small
Z.number().minimum(18).validate(15)
// Error: [tooSmall] age: Number must be at least 18
```

**gRPC Response:**
```
code: INVALID_ARGUMENT
message: "[tooSmall] age: Number must be at least 18"
```

---

### `tooLarge`
**Description:** Number exceeds maximum value

**Examples:**
```dart
// Number too large
Z.number().maximum(100).validate(150)
// Error: [tooLarge] value: Number must be at most 100

// Age too large
Z.number().maximum(150).validate(200)
// Error: [tooLarge] age: Number must be at most 150
```

**gRPC Response:**
```
code: INVALID_ARGUMENT
message: "[tooLarge] age: Number must be at most 150"
```

---

### `invalidFormat`
**Description:** Value doesn't match required pattern (regex)

**Examples:**
```dart
// Invalid email format