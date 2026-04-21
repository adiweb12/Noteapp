import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/drawing_viewmodel.dart';
import '../widgets/drawing_canvas.dart';
import '../utils/app_constants.dart';

class DrawingScreen extends StatefulWidget {
  final String? existingDrawingData;

  const DrawingScreen({super.key, this.existingDrawingData});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final DrawingViewModel _viewModel;
  Color _canvasBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _viewModel = DrawingViewModel();
    if (widget.existingDrawingData != null) {
      _viewModel.loadFromJson(widget.existingDrawingData);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _canvasBackground,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Drawing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Background color toggle
          IconButton(
            icon: const Icon(Icons.invert_colors_outlined),
            tooltip: 'Toggle background',
            onPressed: () {
              setState(() {
                _canvasBackground = _canvasBackground == Colors.white
                    ? Colors.black
                    : Colors.white;
              });
            },
          ),
          // Done
          FilledButton(
            onPressed: _viewModel.isEmpty
                ? null
                : () {
                    Navigator.pop(context, _viewModel.toJson());
                  },
            child: const Text('Done'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: DrawingCanvas(
                viewModel: _viewModel,
                backgroundColor: _canvasBackground,
              ),
            ).animate().fade(duration: 200.ms),
          ),
          DrawingToolbar(viewModel: _viewModel),
        ],
      ),
    );
  }
}
