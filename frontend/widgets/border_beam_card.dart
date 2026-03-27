import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';

/// BorderBeamCard — Hiệu ứng viền gradient chạy vòng quanh card
/// Tương đương BorderBeam từ MagicUI nhưng thuần Flutter.
///
/// Cách dùng:
/// ```dart
/// BorderBeamCard(
///   child: Column(...),
/// )
/// ```
class BorderBeamCard extends StatefulWidget {
  /// Nội dung bên trong card
  final Widget child;

  /// Bo góc của card
  final double borderRadius;

  /// Padding bên trong card
  final EdgeInsetsGeometry padding;

  /// Màu nền của card
  final Color? color;

  /// Thời gian hoàn thành một vòng (giây)
  final double duration;

  /// Chiều rộng của tia sáng chạy (logical pixels — kích thước arc)
  final double beamSize;

  /// Màu gradient của tia sáng (từ → qua → hết)
  final List<Color> beamColors;

  /// Độ dày viền
  final double borderWidth;

  /// Màu viền nền (phần không có tia sáng)
  final Color borderBaseColor;

  const BorderBeamCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(24),
    this.color,
    this.duration = 4,
    this.beamSize = 0.35,
    this.beamColors = const [
      Colors.transparent,
      Color(0xFF60A5FA), // accentBlue
      Color(0xFFA78BFA), // accentPurple
      Colors.transparent,
    ],
    this.borderWidth = 1.5,
    this.borderBaseColor = const Color(0xFFE2E8F0),
  });

  @override
  State<BorderBeamCard> createState() => _BorderBeamCardState();
}

class _BorderBeamCardState extends State<BorderBeamCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (widget.duration * 1000).toInt(),
      ),
    )..repeat(); // Loop vĩnh viễn
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? Theme.of(context).cardColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BorderBeamPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            beamColors: widget.beamColors,
            beamSize: widget.beamSize,
            borderWidth: widget.borderWidth,
            borderBaseColor: widget.borderBaseColor,
          ),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        // Margin nhỏ để lộ viền beam bên ngoài
        margin: EdgeInsets.all(widget.borderWidth),
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}

/// Painter vẽ viền gradient chạy vòng quanh
class _BorderBeamPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final List<Color> beamColors;
  final double beamSize;
  final double borderWidth;
  final Color borderBaseColor;

  _BorderBeamPainter({
    required this.progress,
    required this.borderRadius,
    required this.beamColors,
    required this.beamSize,
    required this.borderWidth,
    required this.borderBaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // ── 1. Vẽ viền nền (mờ nhạt) ────────────────────────────
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderBaseColor;
    canvas.drawRRect(rrect, basePaint);

    // ── 2. Tính chu vi và vị trí tia sáng ───────────────────
    final perimeter = _calcPerimeter(size, borderRadius);
    final beamLength = perimeter * beamSize;

    // Vị trí điểm đầu của tia sáng theo tiến trình
    final startDist = progress * perimeter;
    final endDist = startDist + beamLength;

    // ── 3. Vẽ tia sáng theo path ─────────────────────────────
    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Lấy đường path bao quanh card
    final path = _buildPerimeterPath(size, borderRadius);

    // Vẽ các đoạn path với PathMetrics
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;
    final metric = pathMetrics.first;

    // Tạo gradient sweep theo vị trí hiện tại
    final sweepAngle = 2 * math.pi * beamSize;
    final startAngle = progress * 2 * math.pi - math.pi / 2;

    // Sử dụng SweepGradient để vẽ tia sáng
    final gradient = SweepGradient(
      colors: beamColors,
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
    );

    final center = Offset(size.width / 2, size.height / 2);
    beamPaint.shader = gradient.createShader(
      Rect.fromCenter(
        center: center,
        width: size.width,
        height: size.height,
      ),
    );

    // Vẽ phần path từ startDist đến endDist (với wrap-around)
    _drawBeamOnPath(canvas, metric, startDist, endDist, perimeter, beamPaint);

    // ── 4. Glow effect (vệt sáng mờ bên ngoài) ─────────────
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    glowPaint.shader = SweepGradient(
      colors: [
        Colors.transparent,
        beamColors[1].withOpacity(0.15),
        beamColors[2].withOpacity(0.25),
        beamColors[1].withOpacity(0.15),
        Colors.transparent,
      ],
      startAngle: startAngle - 0.2,
      endAngle: startAngle + sweepAngle + 0.2,
    ).createShader(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
    );

    _drawBeamOnPath(
        canvas, metric, startDist - 20, endDist + 20, perimeter, glowPaint);
  }

  /// Vẽ một đoạn của path, có wrap-around khi vượt quá perimeter
  void _drawBeamOnPath(
    Canvas canvas,
    PathMetric metric,
    double start,
    double end,
    double perimeter,
    Paint paint,
  ) {
    // Chuẩn hóa về [0, perimeter)
    final s = start % perimeter;
    final e = end % perimeter;

    if (s < e) {
      // Đoạn bình thường
      final extracted = metric.extractPath(s, e);
      canvas.drawPath(extracted, paint);
    } else {
      // Wrap-around: vẽ từ s → cuối, rồi từ đầu → e
      final part1 = metric.extractPath(s, perimeter);
      final part2 = metric.extractPath(0, e);
      canvas.drawPath(part1, paint);
      canvas.drawPath(part2, paint);
    }
  }

  /// Xây dựng path đi theo viền ngoài của rounded rect
  Path _buildPerimeterPath(Size size, double r) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Bắt đầu từ góc trên-trái (sau cung tròn)
    path.moveTo(r, 0);
    // Cạnh trên
    path.lineTo(w - r, 0);
    // Góc trên-phải
    path.arcToPoint(Offset(w, r),
        radius: Radius.circular(r), clockwise: true);
    // Cạnh phải
    path.lineTo(w, h - r);
    // Góc dưới-phải
    path.arcToPoint(Offset(w - r, h),
        radius: Radius.circular(r), clockwise: true);
    // Cạnh dưới
    path.lineTo(r, h);
    // Góc dưới-trái
    path.arcToPoint(Offset(0, h - r),
        radius: Radius.circular(r), clockwise: true);
    // Cạnh trái
    path.lineTo(0, r);
    // Góc trên-trái
    path.arcToPoint(Offset(r, 0),
        radius: Radius.circular(r), clockwise: true);
    path.close();
    return path;
  }

  /// Tính chu vi xấp xỉ của rounded rect
  double _calcPerimeter(Size size, double r) {
    final w = size.width;
    final h = size.height;
    // 2*(w+h) - 8r + 2*pi*r
    return 2 * (w + h) - 8 * r + 2 * math.pi * r;
  }

  @override
  bool shouldRepaint(_BorderBeamPainter old) =>
      old.progress != progress ||
      old.borderRadius != borderRadius;
}
