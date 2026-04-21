import 'package:flutter/material.dart';
import '../models/drawing_model.dart';
import '../viewmodels/drawing_viewmodel.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingViewModel viewModel;
  final Color backgroundColor;

  const DrawingCanvas({
    super.key,
    required this.viewModel,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) =>
          viewModel.startStroke(details.localPosition),
      onPanUpdate: (details) =>
          viewModel.addPoint(details.localPosition),
      onPanEnd: (_) => viewModel.endStroke(),
      child: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          return CustomPaint(
            painter: _CanvasPainter(
              strokes: viewModel.strokes,
              currentPoints: viewModel.currentPoints,
              currentColor:
                  viewModel.isEraser ? Colors.white : viewModel.currentColor,
              currentStrokeWidth: viewModel.isEraser
                  ? viewModel.strokeWidth * 3
                  : viewModel.strokeWidth,
              isEraser: viewModel.isEraser,
              backgroundColor: backgroundColor,
            ),
            child: Container(color: backgroundColor),
          );
        },
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isEraser;
  final Color backgroundColor;

  _CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.isEraser,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth,
          stroke.isEraser);
    }

    // Draw current stroke
    if (currentPoints.isNotEmpty) {
      _drawStroke(
          canvas, currentPoints, currentColor, currentStrokeWidth, isEraser);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color,
      double strokeWidth, bool eraser) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = eraser ? backgroundColor : color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(points.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      final midY = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(
          points[i].dx, points[i].dy, midX, midY);
    }
    path.lineTo(points.last.dx, points.last.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.strokes != strokes ||
      old.currentPoints != currentPoints ||
      old.currentColor != currentColor ||
      old.currentStrokeWidth != currentStrokeWidth;
}

// ─── Drawing Toolbar ─────────────────────────────────────────────────────────

class DrawingToolbar extends StatelessWidget {
  final DrawingViewModel viewModel;

  const DrawingToolbar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.cyan,
    ];

    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color row
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == colors.length) {
                          // White
                          return _ColorCircle(
                            color: Colors.white,
                            isSelected: viewModel.currentColor == Colors.white &&
                                !viewModel.isEraser,
                            onTap: () => viewModel.setColor(Colors.white),
                            hasBorder: true,
                          );
                        }
                        return _ColorCircle(
                          color: colors[index],
                          isSelected: viewModel.currentColor == colors[index] &&
                              !viewModel.isEraser,
                          onTap: () => viewModel.setColor(colors[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stroke size + tools row
                  Row(
                    children: [
                      // Stroke width
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.line_weight,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 18),
                            Expanded(
                              child: Slider(
                                value: viewModel.strokeWidth,
                                min: 1,
                                max: 20,
                                onChanged: viewModel.setStrokeWidth,
                                divisions: 19,
                              ),
                            ),
                            Text(
                              viewModel.strokeWidth.toStringAsFixed(0),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Eraser
                      _ToolButton(
                        icon: Icons.auto_fix_normal,
                        label: 'Eraser',
                        isActive: viewModel.isEraser,
                        onTap: viewModel.toggleEraser,
                      ),
                      const SizedBox(width: 4),
                      // Undo
                      _ToolButton(
                        icon: Icons.undo,
                        label: 'Undo',
                        isActive: false,
                        onTap: viewModel.canUndo ? viewModel.undo : null,
                      ),
                      const SizedBox(width: 4),
                      // Redo
                      _ToolButton(
                        icon: Icons.redo,
                        label: 'Redo',
                        isActive: false,
                        onTap: viewModel.canRedo ? viewModel.redo : null,
                      ),
                      const SizedBox(width: 4),
                      // Clear
                      _ToolButton(
                        icon: Icons.delete_outline,
                        label: 'Clear',
                        isActive: false,
                        onTap: viewModel.canUndo ? viewModel.clearAll : null,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasBorder;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : hasBorder
                    ? Colors.grey.shade400
                    : Colors.transparent,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: !enabled
                ? theme.colorScheme.outline.withOpacity(0.3)
                : isDestructive
                    ? theme.colorScheme.error
                    : isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
