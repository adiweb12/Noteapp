import 'dart:ui';

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List)
        .map((p) => Offset(
              (p['dx'] as num).toDouble(),
              (p['dy'] as num).toDouble(),
            ))
        .toList();
    return DrawingStroke(
      points: pointsList,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
    );
  }
}

class DrawingData {
  final List<DrawingStroke> strokes;
  final String backgroundColor;

  DrawingData({
    required this.strokes,
    this.backgroundColor = '#FFFFFF',
  });

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'backgroundColor': backgroundColor,
    };
  }

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    return DrawingData(
      strokes: (json['strokes'] as List)
          .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
    );
  }
}
