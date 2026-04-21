import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note_model.dart';
import '../services/image_service.dart';
import '../viewmodels/providers.dart';
import '../widgets/color_picker.dart';
import '../utils/app_constants.dart';
import '../theme/app_theme.dart';
import 'drawing_screen.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final QuillController _quillController;
  late final TextEditingController _titleController;
  late final FocusNode _titleFocus;
  late final FocusNode _bodyFocus;
  late final ScrollController _scrollController;

  String? _noteColor;
  List<String> _imagePaths = [];
  String? _drawingData;
  bool _showToolbar = true;
  bool _isSaving = false;
  bool _colorPickerOpen = false;
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleFocus = FocusNode();
    _bodyFocus = FocusNode();
    _scrollController = ScrollController();

    final note = widget.note;
    if (note != null) {
      _titleController.text = note.title;
      _noteColor = note.color;
      _imagePaths = List.from(note.imagePaths);
      _drawingData = note.drawingData;
      _tags.addAll(note.tags);
      try {
        final decoded = jsonDecode(note.content);
        final List<dynamic> deltaList = decoded is List ? decoded : [];
        final doc = Document.fromJson(deltaList);
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _quillController = QuillController.basic();
        if (note.plainText.isNotEmpty) {
          _quillController.document.insert(0, note.plainText);
        }
      }
    } else {
      _quillController = QuillController.basic();
    }

    _quillController.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);
    _bodyFocus.addListener(() {
      if (mounted) setState(() => _showToolbar = _bodyFocus.hasFocus);
    });
  }

  void _onContentChanged() {
    if (!_isDirty && mounted) setState(() => _isDirty = true);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(AppConstants.autoSaveDebounce, _autoSave);
  }

  Future<void> _autoSave() async {
    if (!_isDirty) return;
    await _saveNote();
    if (mounted) setState(() => _isDirty = false);
  }

  Future<NoteModel?> _saveNote() async {
    if (_isSaving) return null;
    if (mounted) setState(() => _isSaving = true);
    try {
      final notifier = ref.read(notesProvider.notifier);
      final contentJson =
          jsonEncode(_quillController.document.toDelta().toJson());
      final plainText = _quillController.document.toPlainText().trim();
      final title = _titleController.text.trim();

      if (widget.note == null) {
        return await notifier.createNote(
          title: title,
          content: contentJson,
          plainText: plainText,
          color: _noteColor,
          imagePaths: _imagePaths,
          drawingData: _drawingData,
        );
      } else {
        final updated = widget.note!.copyWith(
          title: title,
          content: contentJson,
          plainText: plainText,
          color: _noteColor,
          imagePaths: _imagePaths,
          drawingData: _drawingData,
          tags: _tags,
          clearColor: _noteColor == null,
        );
        await notifier.updateNote(updated);
        return updated;
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _quillController.removeListener(_onContentChanged);
    _titleController.removeListener(_onContentChanged);
    _quillController.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = _noteColor != null
        ? AppTheme.getNoteColor(_noteColor, isDark)
        : theme.colorScheme.surface;
    final contentColor = _noteColor != null
        ? (bgColor.computeLuminance() > 0.5
            ? Colors.black87
            : Colors.white)
        : theme.colorScheme.onSurface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _autoSave();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          foregroundColor: contentColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: contentColor,
            onPressed: () async {
              await _autoSave();
              if (mounted) Navigator.pop(context);
            },
          ),
          actions: [
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: contentColor.withAlpha(153),
                  ),
                ),
              ),
            IconButton(
              icon: Icon(Icons.palette_outlined, color: contentColor),
              onPressed: () =>
                  setState(() => _colorPickerOpen = !_colorPickerOpen),
            ),
            IconButton(
              icon: Icon(Icons.image_outlined, color: contentColor),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: Icon(Icons.draw_outlined, color: contentColor),
              onPressed: _openDrawing,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: contentColor),
              onSelected: _handleMenuAction,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Row(children: [
                    Icon(
                        widget.note?.isPinned == true
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(widget.note?.isPinned == true ? 'Unpin' : 'Pin'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'tag',
                  child: Row(children: [
                    Icon(Icons.label_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Add tag'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'export_txt',
                  child: Row(children: [
                    Icon(Icons.text_snippet_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Export TXT'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Share'),
                  ]),
                ),
                if (widget.note != null)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: 10),
                      Text('Delete',
                          style:
                              TextStyle(color: theme.colorScheme.error)),
                    ]),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            AnimatedSize(
              duration: AppConstants.animMedium,
              child: _colorPickerOpen
                  ? NoteColorPicker(
                      selectedColor: _noteColor,
                      onColorSelected: (c) => setState(() {
                        _noteColor = c;
                        _isDirty = true;
                      }),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: contentColor),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: contentColor.withAlpha(77)),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        _titleFocus.unfocus();
                        _bodyFocus.requestFocus();
                      },
                    ),

                    // Updated at timestamp
                    if (widget.note != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          DateFormatter.formatFull(widget.note!.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: contentColor.withAlpha(102)),
                        ),
                      ),

                    // Tags
                    if (_tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _tags
                              .map((tag) => Chip(
                                    label: Text(tag,
                                        style: TextStyle(
                                            color: contentColor,
                                            fontSize: 12)),
                                    deleteIcon: Icon(Icons.close,
                                        size: 14, color: contentColor),
                                    onDeleted: () => setState(() {
                                      _tags.remove(tag);
                                      _isDirty = true;
                                    }),
                                    backgroundColor:
                                        contentColor.withAlpha(26),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                      ),

                    Divider(
                        color: contentColor.withAlpha(31), height: 1),
                    const SizedBox(height: 8),

                    // Quill rich text editor (no customStyles to avoid API issues)
                    QuillEditor.basic(
                      controller: _quillController,
                      config: QuillEditorConfig(
                        autoFocus: widget.note == null,
                        expands: false,
                        padding: EdgeInsets.zero,
                        placeholder: 'Start writing...',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Attached images
                    if (_imagePaths.isNotEmpty) ...[
                      Divider(
                          color: contentColor.withAlpha(31), height: 24),
                      Text(
                        'Images',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: contentColor.withAlpha(128),
                            letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      _buildImageGrid(contentColor),
                    ],

                    // Drawing badge
                    if (_drawingData != null &&
                        _drawingData!.isNotEmpty) ...[
                      Divider(
                          color: contentColor.withAlpha(31), height: 24),
                      GestureDetector(
                        onTap: _openDrawing,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: contentColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: contentColor.withAlpha(31)),
                          ),
                          child: Row(children: [
                            Icon(Icons.draw,
                                color: contentColor.withAlpha(153)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Drawing attached — tap to edit',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                        color:
                                            contentColor.withAlpha(153)),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: contentColor.withAlpha(102)),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Formatting toolbar
            AnimatedSize(
              duration: AppConstants.animFast,
              child: _showToolbar
                  ? _buildQuillToolbar(theme)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(Color contentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _imagePaths.asMap().entries.map((e) {
        return Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(e.value),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                color: contentColor.withAlpha(26),
                child: Icon(Icons.broken_image,
                    color: contentColor.withAlpha(77)),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() {
                _imagePaths.removeAt(e.key);
                _isDirty = true;
              }),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildQuillToolbar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: QuillSimpleToolbar(
          controller: _quillController,
          config: const QuillSimpleToolbarConfig(
            showAlignmentButtons: false,
            showBackgroundColorButton: false,
            showClearFormat: true,
            showColorButton: true,
            showCodeBlock: false,
            showDividers: true,
            showFontFamily: false,
            showFontSize: false,
            showHeaderStyle: true,
            showInlineCode: false,
            showIndent: false,
            showJustifyAlignment: false,
            showLeftAlignment: false,
            showCenterAlignment: false,
            showRightAlignment: false,
            showLink: false,
            showListBullets: true,
            showListCheck: true,
            showListNumbers: true,
            showQuote: false,
            showStrikeThrough: true,
            showSubscript: false,
            showSuperscript: false,
            showUnderLineButton: true,
            showBoldButton: true,
            showItalicButton: true,
            showUndo: true,
            showRedo: true,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final pickedPath = choice == 'gallery'
        ? await ImageService.pickFromGallery()
        : await ImageService.pickFromCamera();
    if (pickedPath != null && mounted) {
      setState(() {
        _imagePaths.add(pickedPath);
        _isDirty = true;
      });
    }
  }

  Future<void> _openDrawing() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => DrawingScreen(existingDrawingData: _drawingData),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _drawingData = result;
        _isDirty = true;
      });
    }
  }

  Future<void> _handleMenuAction(String action) async {
    final theme = Theme.of(context);
    switch (action) {
      case 'pin':
        if (widget.note != null) {
          ref.read(notesProvider.notifier).togglePin(widget.note!.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(widget.note!.isPinned
                  ? 'Note unpinned'
                  : 'Note pinned'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ));
          }
        }
        break;

      case 'tag':
        _showAddTagDialog();
        break;

      case 'export_txt':
        final saved = await _saveNote();
        final noteToExport = saved ?? widget.note;
        if (noteToExport != null && mounted) {
          try {
            final repo = ref.read(notesRepositoryProvider);
            final file = await repo.exportNoteToTxt(noteToExport);
            await Share.shareXFiles(
              [XFile(file.path)],
              subject: noteToExport.title,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export failed: $e')),
              );
            }
          }
        }
        break;

      case 'share':
        final plain = _quillController.document.toPlainText().trim();
        final title = _titleController.text.trim();
        await Share.share(
            title.isNotEmpty ? '$title\n\n$plain' : plain);
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete note?'),
            content: const Text('This note will be permanently deleted.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && widget.note != null && mounted) {
          ref.read(notesProvider.notifier).deleteNote(widget.note!.id);
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tag name',
            prefixIcon: Icon(Icons.label_outline),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              setState(() {
                _tags.add(val.trim());
                _isDirty = true;
              });
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _tags.add(val);
                  _isDirty = true;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
