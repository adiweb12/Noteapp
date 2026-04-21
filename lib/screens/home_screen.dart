import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note_model.dart';
import '../viewmodels/providers.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state.dart';
import '../utils/app_constants.dart';
import 'note_editor_screen.dart';
import 'archive_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: AppConstants.animMedium,
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGrid = ref.watch(viewModeProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final otherNotes = filteredNotes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.colorScheme.surface,
            expandedHeight: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: theme.colorScheme.surface),
            ),
            title: AnimatedSwitcher(
              duration: AppConstants.animMedium,
              child: _isSearching
                  ? NoteSearchBar(
                      key: const ValueKey('search'),
                      initialValue: searchQuery,
                      onChanged: (q) {
                        ref.read(searchQueryProvider.notifier).state = q;
                      },
                    )
                  : Text(
                      'NoteCraft',
                      key: const ValueKey('title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: AppConstants.animFast,
                  child: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    key: ValueKey(_isSearching),
                  ),
                ),
                onPressed: () {
                  setState(() => _isSearching = !_isSearching);
                  if (!_isSearching) {
                    ref.read(searchQueryProvider.notifier).state = '';
                  }
                },
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: AppConstants.animFast,
                  child: Icon(
                    isGrid ? Icons.view_list_outlined : Icons.grid_view,
                    key: ValueKey(isGrid),
                  ),
                ),
                onPressed: () => ref.read(viewModeProvider.notifier).toggle(),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'archive') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ArchiveScreen()),
                    );
                  } else if (val == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(children: [
                      Icon(Icons.archive_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Archive'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(children: [
                      Icon(Icons.settings_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Settings'),
                    ]),
                  ),
                ],
              ),
            ],
          ),

          // Content
          if (filteredNotes.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                icon: _isSearching
                    ? Icons.search_off
                    : Icons.note_add_outlined,
                title: _isSearching
                    ? 'No notes found'
                    : 'No notes yet',
                subtitle: _isSearching
                    ? 'Try a different search term'
                    : 'Tap + to create your first note',
              ),
            )
          else ...[
            // Pinned section
            if (pinnedNotes.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'PINNED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _buildNoteGrid(
                  pinnedNotes, isGrid, startIndex: 0),
              if (otherNotes.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'OTHERS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
            // Other notes
            if (otherNotes.isNotEmpty)
              _buildNoteGrid(
                otherNotes,
                isGrid,
                startIndex: pinnedNotes.length,
              ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, null),
          icon: const Icon(Icons.add),
          label: const Text('New Note'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildNoteGrid(
    List<NoteModel> notes,
    bool isGrid, {
    int startIndex = 0,
  }) {
    if (isGrid) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childCount: notes.length,
          itemBuilder: (context, index) => NoteCard(
            note: notes[index],
            isGridView: true,
            index: startIndex + index,
            onTap: () => _openEditor(context, notes[index]),
            onPin: () => ref
                .read(notesProvider.notifier)
                .togglePin(notes[index].id),
            onDelete: () => _confirmDelete(context, notes[index]),
            onArchive: () => ref
                .read(notesProvider.notifier)
                .toggleArchive(notes[index].id),
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NoteCard(
                note: notes[index],
                isGridView: false,
                index: startIndex + index,
                onTap: () => _openEditor(context, notes[index]),
                onPin: () => ref
                    .read(notesProvider.notifier)
                    .togglePin(notes[index].id),
                onDelete: () => _confirmDelete(context, notes[index]),
                onArchive: () => ref
                    .read(notesProvider.notifier)
                    .toggleArchive(notes[index].id),
              ),
            ),
            childCount: notes.length,
          ),
        ),
      );
    }
  }

  Future<void> _openEditor(BuildContext context, NoteModel? note) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => NoteEditorScreen(note: note),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: AppConstants.animMedium,
      ),
    );
    ref.read(notesProvider.notifier).refresh();
  }

  Future<void> _confirmDelete(BuildContext context, NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text(
          note.title.isNotEmpty
              ? 'Delete "${note.title}"?'
              : 'This note will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(notesProvider.notifier).deleteNote(note.id);
    }
  }
}
