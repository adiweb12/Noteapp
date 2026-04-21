import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content; // JSON string for Quill delta

  @HiveField(3)
  String plainText; // Plain text for search

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String? color; // Hex color string

  @HiveField(7)
  List<String> imagePaths; // Local image paths

  @HiveField(8)
  bool isPinned;

  @HiveField(9)
  bool isArchived;

  @HiveField(10)
  List<String> tags;

  @HiveField(11)
  String? drawingData; // JSON string for drawing strokes

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.plainText,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    List<String>? imagePaths,
    this.isPinned = false,
    this.isArchived = false,
    List<String>? tags,
    this.drawingData,
  })  : imagePaths = imagePaths ?? [],
        tags = tags ?? [];

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? plainText,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    List<String>? imagePaths,
    bool? isPinned,
    bool? isArchived,
    List<String>? tags,
    String? drawingData,
    bool clearColor = false,
    bool clearDrawing = false,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: clearColor ? null : (color ?? this.color),
      imagePaths: imagePaths ?? this.imagePaths,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      drawingData: clearDrawing ? null : (drawingData ?? this.drawingData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'plainText': plainText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
      'imagePaths': imagePaths,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'tags': tags,
      'drawingData': drawingData,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      plainText: json['plainText'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      color: json['color'] as String?,
      imagePaths: List<String>.from(json['imagePaths'] as List? ?? []),
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
      drawingData: json['drawingData'] as String?,
    );
  }

  @override
  String toString() =>
      'NoteModel(id: $id, title: $title, updatedAt: $updatedAt)';
}
