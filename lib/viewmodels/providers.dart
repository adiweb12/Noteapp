import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../services/notes_repository.dart';

// ─── SHARED PREFERENCES ──────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main()');
});

// ─── THEME ───────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  ThemeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }

  void toggle() {
    if (state == ThemeMode.light) {
      setTheme(ThemeMode.dark);
    } else {
      setTheme(ThemeMode.light);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

// ─── NOTES REPOSITORY ────────────────────────────────────────────────────────

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

// ─── VIEW MODE (grid / list) ──────────────────────────────────────────────────

class ViewModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'is_grid_view';

  ViewModeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? true);

  Future<void> toggle() async {
    state = !state;
    await _prefs.setBool(_key, state);
  }
}

final viewModeProvider = StateNotifierProvider<ViewModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ViewModeNotifier(prefs);
});

// ─── SEARCH ───────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

// ─── NOTES LIST ───────────────────────────────────────────────────────────────

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteModel>>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return NotesNotifier(repo);
});

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  final NotesRepository _repo;

  NotesNotifier(this._repo) : super(const AsyncValue.loading()) {
    _loadNotes();
  }

  void _loadNotes() {
    try {
      final notes = _repo.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<NoteModel> get allNotes {
    return state.when(
      data: (notes) => notes,
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Future<NoteModel> createNote({
    String title = '',
    String content = '[]',
    String plainText = '',
    String? color,
    List<String>? imagePaths,
    String? drawingData,
  }) async {
    final note = await _repo.createNote(
      title: title,
      content: content,
      plainText: plainText,
      color: color,
      imagePaths: imagePaths,
      drawingData: drawingData,
    );
    _loadNotes();
    return note;
  }

  Future<void> updateNote(NoteModel note) async {
    await _repo.updateNote(note);
    _loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repo.deleteNote(id);
    _loadNotes();
  }

  Future<void> togglePin(String id) async {
    await _repo.togglePin(id);
    _loadNotes();
  }

  Future<void> toggleArchive(String id) async {
    await _repo.toggleArchive(id);
    _loadNotes();
  }

  List<NoteModel> searchNotes(String query) {
    return _repo.searchNotes(query);
  }

  void refresh() => _loadNotes();
}

// ─── ARCHIVED NOTES ───────────────────────────────────────────────────────────

final archivedNotesProvider = Provider<List<NoteModel>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.getAllNotes(includeArchived: true);
});

// ─── FILTERED NOTES ───────────────────────────────────────────────────────────

final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(notesRepositoryProvider);

  return notesAsync.when(
    data: (_) {
      if (query.trim().isEmpty) {
        return repo.getAllNotes();
      }
      return repo.searchNotes(query);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
