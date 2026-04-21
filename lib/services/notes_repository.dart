import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import 'hive_service.dart';

class NotesRepository {
  final Box<NoteModel> _box = HiveService.notesBox;
  final _uuid = const Uuid();

  // ─── CRUD ────────────────────────────────────────────────────────────────

  List<NoteModel> getAllNotes({bool includeArchived = false}) {
    final notes = _box.values.toList();
    if (!includeArchived) {
      return notes.where((n) => !n.isArchived).toList()
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    }
    return notes
        .where((n) => n.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  NoteModel? getNoteById(String id) {
    try {
      return _box.values.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<NoteModel> createNote({
    String title = '',
    String content = '[]',
    String plainText = '',
    String? color,
    List<String>? imagePaths,
    String? drawingData,
  }) async {
    final now = DateTime.now();
    final note = NoteModel(
      id: _uuid.v4(),
      title: title,
      content: content,
      plainText: plainText,
      createdAt: now,
      updatedAt: now,
      color: color,
      imagePaths: imagePaths ?? [],
      drawingData: drawingData,
    );
    await _box.put(note.id, note);
    return note;
  }

  Future<void> updateNote(NoteModel note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _box.put(updated.id, updated);
  }

  Future<void> deleteNote(String id) async {
    final note = getNoteById(id);
    if (note != null) {
      // Delete associated images
      for (final path in note.imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _box.delete(id);
    }
  }

  Future<void> togglePin(String id) async {
    final note = getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(isPinned: !note.isPinned));
    }
  }

  Future<void> toggleArchive(String id) async {
    final note = getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(
        isArchived: !note.isArchived,
        isPinned: false,
      ));
    }
  }

  // ─── SEARCH ──────────────────────────────────────────────────────────────

  List<NoteModel> searchNotes(String query) {
    if (query.trim().isEmpty) return getAllNotes();
    final q = query.toLowerCase();
    return getAllNotes(includeArchived: false).where((note) {
      return note.title.toLowerCase().contains(q) ||
          note.plainText.toLowerCase().contains(q) ||
          note.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  // ─── EXPORT / IMPORT ─────────────────────────────────────────────────────

  Future<File> exportNotesToJson() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/notecraft_export_${DateTime.now().millisecondsSinceEpoch}.json');
    final notes = getAllNotes(includeArchived: true);
    final json = jsonEncode(notes.map((n) => n.toJson()).toList());
    await file.writeAsString(json);
    return file;
  }

  Future<File> exportNoteToTxt(NoteModel note) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeTitle = note.title.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final file = File('${dir.path}/${safeTitle}_${note.id.substring(0, 8)}.txt');
    final buffer = StringBuffer();
    buffer.writeln('Title: ${note.title}');
    buffer.writeln('Created: ${note.createdAt.toLocal()}');
    buffer.writeln('Updated: ${note.updatedAt.toLocal()}');
    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.join(', ')}');
    }
    buffer.writeln('─' * 40);
    buffer.writeln(note.plainText);
    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<int> importNotesFromJson(String jsonString) async {
    int imported = 0;
    try {
      final list = jsonDecode(jsonString) as List;
      for (final item in list) {
        final note = NoteModel.fromJson(item as Map<String, dynamic>);
        // Avoid duplicate IDs
        if (_box.containsKey(note.id)) {
          note.id; // read-only, skip
          continue;
        }
        await _box.put(note.id, note);
        imported++;
      }
    } catch (e) {
      rethrow;
    }
    return imported;
  }

  // ─── STATS ───────────────────────────────────────────────────────────────

  int get totalNotes => _box.values.where((n) => !n.isArchived).length;
  int get archivedNotes => _box.values.where((n) => n.isArchived).length;
  int get pinnedNotes =>
      _box.values.where((n) => n.isPinned && !n.isArchived).length;
}
