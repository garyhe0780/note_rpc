import 'package:fixnum/fixnum.dart' as fixnum;
import '../generated/note_service.pb.dart' as pb;

/// Domain model representing a note entity.
/// This is an immutable class that provides conversion methods to/from protobuf messages.
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this note with the given fields replaced with new values.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Converts this domain model to a protobuf Note message.
  pb.Note toProto() => pb.Note(
    id: id,
    title: title,
    content: content,
    createdAt: fixnum.Int64(createdAt.millisecondsSinceEpoch),
    updatedAt: fixnum.Int64(updatedAt.millisecondsSinceEpoch),
  );

  /// Creates a Note domain model from a protobuf Note message.
  factory Note.fromProto(pb.Note proto) => Note(
    id: proto.id,
    title: proto.title,
    content: proto.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(proto.createdAt.toInt()),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(proto.updatedAt.toInt()),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          other.id == id &&
          other.title == title &&
          other.content == content &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, title, content, createdAt, updatedAt);

  @override
  String toString() =>
      'Note(id: $id, title: $title, content: $content, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';
}
