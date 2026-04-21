import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';

class HiveService {
  static const String _notesBoxName = 'notes';
  static Box<NoteModel>? _notesBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteModelAdapter());
    _notesBox = await Hive.openBox<NoteModel>(_notesBoxName);
  }

  static Box<NoteModel> get notesBox {
    if (_notesBox == null || !_notesBox!.isOpen) {
      throw StateError('HiveService not initialized. Call init() first.');
    }
    return _notesBox!;
  }

  static Future<void> close() async {
    await _notesBox?.close();
  }
}
