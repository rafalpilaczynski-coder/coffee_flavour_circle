import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';

enum WheelPhase { primaryMain, primarySub, secondaryMain, secondarySub, completed }

class FlavorWheelScreen extends ConsumerStatefulWidget {
  const FlavorWheelScreen({super.key});

  @override
  ConsumerState<FlavorWheelScreen> createState() => _FlavorWheelScreenState();
}

class _FlavorWheelScreenState extends ConsumerState<FlavorWheelScreen> {
  WheelPhase _currentPhase = WheelPhase.primaryMain;
  String? _tempMainSelection;
  int? _tempMainIndex;

  void _handleSegmentTap(String categoryName, int index) {
    final notifier = ref.read(tastingProvider.notifier);

    setState(() {
      switch (_currentPhase) {
        case WheelPhase.primaryMain:
          _tempMainSelection = categoryName;
          _tempMainIndex = index;
          _currentPhase = WheelPhase.primarySub;
          break;
        case WheelPhase.primarySub:
          notifier.setPrimaryFlavor(_tempMainSelection!, categoryName);
          _tempMainSelection = null;
          _tempMainIndex = null;
          _currentPhase = WheelPhase.secondaryMain;
          break;
        case WheelPhase.secondaryMain:
          _tempMainSelection = categoryName;
          _tempMainIndex = index;
          _currentPhase = WheelPhase.secondarySub;
          break;
        case WheelPhase.secondarySub:
          notifier.setSecondaryFlavor(_tempMainSelection!, categoryName);
          _tempMainSelection = null;
          _tempMainIndex = null;
          _currentPhase = WheelPhase.completed;
          break;
        case WheelPhase.completed:
          break;
      }
    });
  }

  void _resetWheel() {
    ref.read(tastingProvider.notifier).clearAllFlavors();
    setState(() {
      _currentPhase = WheelPhase.primaryMain;
      _tempMainSelection = null;
      _tempMainIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tastingData = ref.watch(tastingProvider);
    
    List<Map<String, dynamic>> activeCategories = [];
    double baseStartAngle = -math.pi / 2;
    double totalSweepAngle = 2 * math.pi;

    if (_currentPhase == WheelPhase.primaryMain || _currentPhase == WheelPhase.secondaryMain) {
      activeCategories = mainFlavorCategories; 
    } else if (_tempMainSelection != null && _tempMainIndex != null) {
      final parentColor = flavorTree[_tempMainSelection]!['color'] as Color;
      final subList = List<String>.from(flavorTree[_tempMainSelection]!['sub']);
      
      subList.insert(0, 'Overall\n$_tempMainSelection'); 

      activeCategories = subList.map((subName) => {'name': subName, 'color': parentColor}).toList();
      totalSweepAngle = (2 * math.pi) / mainFlavorCategories.length;
      baseStartAngle = -math.pi / 2 + (_tempMainIndex! * totalSweepAngle);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flavor Wheel'), 
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _resetWheel)],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("Follow the flavor path", style: TextStyle(fontSize: 16, color: Colors.amber)),
          const SizedBox(height: 30),
          
          Center(
            child: _currentPhase == WheelPhase.completed 
              ? const SizedBox(
                  height: 300, 
                  child: Center(child: Icon(Icons.check_circle, size: 100, color: Colors.green))
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                        alignment: Alignment.center,
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    key: ValueKey('$_currentPhase-$_tempMainSelection'), 
                    onTapUp: (details) {
                      const double centerOffset = 150.0;
                      double dx = details.localPosition.dx - centerOffset;
                      double dy = details.localPosition.dy - centerOffset;

                      if (math.sqrt(dx * dx + dy * dy) < centerOffset * 0.3) return; 

                      double touchAngle = math.atan2(dy, dx);
                      double relativeAngle = (touchAngle - baseStartAngle) % (2 * math.pi);
                      if (relativeAngle < 0) relativeAngle += 2 * math.pi;

                      if (relativeAngle <= totalSweepAngle) {
                        int index = (relativeAngle / totalSweepAngle * activeCategories.length).floor();
                        if (index == activeCategories.length) index--; 
                        _handleSegmentTap(activeCategories[index]['name'], index);
                      }
                    },
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: WheelPainter(
                        categories: activeCategories,
                        baseStartAngle: baseStartAngle,
                        totalSweepAngle: totalSweepAngle,
                      ),
                    ),
                  ),
                ),
          ),
          
          const Spacer(),
          if (tastingData.primaryFlavorMain != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.blueGrey.withValues(alpha: 0.3),
                child: ListTile(
                  title: const Text('Primary Flavor'),
                  subtitle: Text('${tastingData.primaryFlavorMain} ➔ ${tastingData.primaryFlavorSub ?? '...'}'),
                  leading: const Icon(Icons.star, color: Colors.amber),
                ),
              ),
            ),
          if (tastingData.secondaryFlavorMain != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: Colors.blueGrey.withValues(alpha: 0.3),
                child: ListTile(
                  title: const Text('Secondary Flavor'),
                  subtitle: Text('${tastingData.secondaryFlavorMain} ➔ ${tastingData.secondaryFlavorSub ?? '...'}'),
                  leading: const Icon(Icons.star_half, color: Colors.amberAccent),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PrimaryActionButton(
              label: 'NEXT: FINAL EVALUATION',
              onPressed: () => context.go('/evaluation'),
            ),
          ),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double baseStartAngle;
  final double totalSweepAngle;

  WheelPainter({required this.categories, required this.baseStartAngle, required this.totalSweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final double sweepAngle = totalSweepAngle / categories.length;
    double currentAngle = baseStartAngle;

    for (var cat in categories) {
      final paint = Paint()
        ..color = cat['color']
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, currentAngle, sweepAngle, true, paint);
      
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, currentAngle, sweepAngle, true, borderPaint);

      _drawText(canvas, center, radius, currentAngle, sweepAngle, cat['name']);
      currentAngle += sweepAngle;
    }

    canvas.drawCircle(center, radius * 0.3, Paint()..color = const Color(0xFF121212));
  }

  void _drawText(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String text) {
    final double textAngle = startAngle + (sweepAngle / 2);
    final double textRadius = radius * 0.65; 
    
    final double textX = center.dx + textRadius * math.cos(textAngle);
    final double textY = center.dy + textRadius * math.sin(textAngle);

    canvas.save();
    canvas.translate(textX, textY);
    
    double rotation = textAngle;
    if (rotation > math.pi / 2 && rotation < 3 * math.pi / 2) {
      rotation += math.pi;
    }
    canvas.rotate(rotation);

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
      ),
    );
    final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout(maxWidth: radius * 0.5); 
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.baseStartAngle != baseStartAngle;
  }
}