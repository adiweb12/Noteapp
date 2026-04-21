import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/drawing_model.dart';

class DrawingViewModel extends ChangeNotifier {
  final List<DrawingStroke> _strokes = [];
  final List<List<DrawingStroke>> _undoStack = [];

  Color _currentColor = Colors.black;
  double _strokeWidth = 4.0;
  bool _isEraser = false;
  List<Offset> _currentPoints = [];

  // ─── Getters ────────────────────────────────────────────────────────────

  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  bool get isEraser => _isEraser;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _undoStack.isNotEmpty;

  // ─── Drawing Actions ─────────────────────────────────────────────────────

  void startStroke(Offset point) {
    _currentPoints = [point];
    notifyListeners();
  }

  void addPoint(Offset point) {
    _currentPoints.add(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentPoints.isNotEmpty) {
      _strokes.add(DrawingStroke(
        points: List.from(_currentPoints),
        color: _isEraser ? Colors.white : _currentColor,
        strokeWidth: _isEraser ? _strokeWidth * 3 : _strokeWidth,
        isEraser: _isEraser,
      ));
      _undoStack.clear(); // New stroke clears redo stack
      _currentPoints = [];
      notifyListeners();
    }
  }

  List<Offset> get currentPoints => List.unmodifiable(_currentPoints);

  // ─── Tool Controls ────────────────────────────────────────────────────────

  void setColor(Color color) {
    _currentColor = color;
    _isEraser = false;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void toggleEraser() {
    _isEraser = !_isEraser;
    notifyListeners();
  }

  void setPen() {
    _isEraser = false;
    notifyListeners();
  }

  // ─── Undo / Redo ──────────────────────────────────────────────────────────

  void undo() {
    if (_strokes.isNotEmpty) {
      final last = _strokes.removeLast();
      _undoStack.add([last]);
      notifyListeners();
    }
  }

  void redo() {
    if (_undoStack.isNotEmpty) {
      final restored = _undoStack.removeLast();
      _strokes.addAll(restored);
      notifyListeners();
    }
  }

  void clearAll() {
    if (_strokes.isNotEmpty) {
      _undoStack.add(List.from(_strokes));
      _strokes.clear();
      notifyListeners();
    }
  }

  // ─── Serialization ────────────────────────────────────────────────────────

  void loadFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return;
    try {
      final data = DrawingData.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);
      _strokes.clear();
      _strokes.addAll(data.strokes);
      _undoStack.clear();
      notifyListeners();
    } catch (_) {}
  }

  String toJson() {
    final data = DrawingData(strokes: _strokes);
    return jsonEncode(data.toJson());
  }

  bool get isEmpty => _strokes.isEmpty && _currentPoints.isEmpty;
}
