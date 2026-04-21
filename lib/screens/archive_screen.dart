import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note_model.dart';
import '../viewmodels/providers.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';
import 'note_editor_screen.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(notesRepositoryProvider);
    final archivedNotes = repo.getAllNotes(includeArchived: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        centerTitle: false,
      ),
      body: archivedNotes.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.archive_outlined,
              title: 'Archive is empty',
              subtitle: 'Archived notes will appear here',
            )
          : MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: const EdgeInsets.all(12),
              itemCount: archivedNotes.length,
              itemBuilder: (context, index) {
                final note = archivedNotes[index];
                return NoteCard(
                  note: note,
                  index: index,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NoteEditorScreen(note: note)),
                    );
                    ref.read(notesProvider.notifier).refresh();
                  },
                  onArchive: () {
                    ref.read(notesProvider.notifier).toggleArchive(note.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Note unarchived'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onDelete: () {
                    ref.read(notesProvider.notifier).deleteNote(note.id);
                  },
                );
              },
            ),
    );
  }
}
