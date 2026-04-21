import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/note_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final bool isGridView;
  final int index;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.onPin,
    this.onDelete,
    this.onArchive,
    this.isGridView = true,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color cardColor;
    if (note.color != null) {
      cardColor = AppTheme.getNoteColor(note.color, isDark);
    } else {
      cardColor = theme.colorScheme.surface;
    }

    final bool hasCustomColor = note.color != null;
    final textColor = hasCustomColor
        ? (cardColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : theme.colorScheme.onSurface;

    return Animate(
      effects: [
        FadeEffect(
          delay: Duration(milliseconds: index * 40),
          duration: const Duration(milliseconds: 300),
        ),
        SlideEffect(
          delay: Duration(milliseconds: index * 40),
          duration: const Duration(milliseconds: 300),
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ),
      ],
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress ?? () => _showOptions(context),
        child: AnimatedContainer(
          duration: AppConstants.animMedium,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(
              color: hasCustomColor
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pin indicator
                      if (note.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Icon(
                            Icons.push_pin,
                            size: 14,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),

                      // Title
                      if (note.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            note.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              height: 1.3,
                            ),
                            maxLines: isGridView ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Image preview
                      if (note.imagePaths.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(note.imagePaths.first),
                              height: isGridView ? 100 : 60,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                        ),

                      // Drawing preview
                      if (note.drawingData != null &&
                          note.imagePaths.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.draw,
                                    size: 16,
                                    color: textColor.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  'Drawing',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: textColor.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Content preview
                      if (note.plainText.isNotEmpty)
                        Text(
                          note.plainText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor.withOpacity(0.75),
                            height: 1.4,
                          ),
                          maxLines: isGridView ? 4 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 10),

                      // Footer: date + tags
                      Row(
                        children: [
                          Text(
                            DateFormatter.format(note.updatedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: textColor.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: note.tags
                                      .take(2)
                                      .map((tag) => Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: textColor
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                tag,
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: textColor
                                                      .withOpacity(0.7),
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                          if (note.imagePaths.length > 1) ...[
                            const Spacer(),
                            Icon(Icons.photo_library,
                                size: 12,
                                color: textColor.withOpacity(0.5)),
                            const SizedBox(width: 2),
                            Text(
                              '${note.imagePaths.length}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: textColor.withOpacity(0.5)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick action button (top right)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _QuickMenuButton(
                    note: note,
                    textColor: textColor,
                    onPin: onPin,
                    onDelete: onDelete,
                    onArchive: onArchive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NoteOptionsSheet(
        note: note,
        onPin: onPin,
        onDelete: onDelete,
        onArchive: onArchive,
      ),
    );
  }
}

class _QuickMenuButton extends StatelessWidget {
  final NoteModel note;
  final Color textColor;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;

  const _QuickMenuButton({
    required this.note,
    required this.textColor,
    this.onPin,
    this.onDelete,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'pin':
            onPin?.call();
            break;
          case 'archive':
            onArchive?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      icon: Icon(
        Icons.more_vert,
        size: 16,
        color: textColor.withOpacity(0.4),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(children: [
            Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18),
            const SizedBox(width: 8),
            Text(note.isPinned ? 'Unpin' : 'Pin'),
          ]),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(children: [
            const Icon(Icons.archive_outlined, size: 18),
            const SizedBox(width: 8),
            const Text('Archive'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline,
                size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text('Delete',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      ],
    );
  }
}

class _NoteOptionsSheet extends StatelessWidget {
  final NoteModel note;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;

  const _NoteOptionsSheet({
    required this.note,
    this.onPin,
    this.onDelete,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Icon(
              note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(note.isPinned ? 'Unpin note' : 'Pin note'),
            onTap: () {
              Navigator.pop(context);
              onPin?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(note.isArchived ? 'Unarchive' : 'Archive note'),
            onTap: () {
              Navigator.pop(context);
              onArchive?.call();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline,
                color: theme.colorScheme.error),
            title: Text('Delete note',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
