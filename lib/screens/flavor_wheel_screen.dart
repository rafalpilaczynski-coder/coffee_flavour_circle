// lib/screens/flavor_wheel_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';

enum WheelPhase { primaryMain, primarySub, primaryTertiary, secondaryMain, secondarySub, secondaryTertiary, completed }

class FlavorWheelScreen extends ConsumerStatefulWidget {
  const FlavorWheelScreen({super.key});

  @override
  ConsumerState<FlavorWheelScreen> createState() => _FlavorWheelScreenState();
}

class _FlavorWheelScreenState extends ConsumerState<FlavorWheelScreen> {
  WheelPhase _currentPhase = WheelPhase.primaryMain;
  
  String? _tempMainSelection;
  int? _tempMainIndex;
  
  String? _tempSubSelection;
  int? _tempSubIndex;

  // Flaga do ponownego odpalania animacji wachlarza
  Key _animationKey = UniqueKey();

  void _handleSegmentTap(String categoryName, int index) {
    final notifier = ref.read(tastingProvider.notifier);
    
    if (categoryName.startsWith('Overall\n')) {
      categoryName = '';
    }

    setState(() {
      // Zmiana klucza wymusza restart TweenAnimationBuilder
      _animationKey = UniqueKey();

      switch (_currentPhase) {
        case WheelPhase.primaryMain:
          _tempMainSelection = categoryName;
          _tempMainIndex = index;
          _currentPhase = WheelPhase.primarySub;
          break;
          
        case WheelPhase.primarySub:
          if (categoryName.isEmpty || categoryName.startsWith('Overall')) {
             notifier.setPrimaryFlavor(_tempMainSelection!, '', '');
             _resetTemps();
             _currentPhase = WheelPhase.secondaryMain;
          } else {
             final Map<String, List<String>> subMap = flavorTree[_tempMainSelection!]!['sub'];
             final List<String> tertiaryList = subMap[categoryName] ?? [];
             
             if (tertiaryList.isEmpty) {
                notifier.setPrimaryFlavor(_tempMainSelection!, categoryName, '');
                _resetTemps();
                _currentPhase = WheelPhase.secondaryMain;
             } else {
                _tempSubSelection = categoryName;
                _tempSubIndex = index;
                _currentPhase = WheelPhase.primaryTertiary;
             }
          }
          break;
          
        case WheelPhase.primaryTertiary:
          notifier.setPrimaryFlavor(_tempMainSelection!, _tempSubSelection!, categoryName);
          _resetTemps();
          _currentPhase = WheelPhase.secondaryMain;
          break;

        case WheelPhase.secondaryMain:
          _tempMainSelection = categoryName;
          _tempMainIndex = index;
          _currentPhase = WheelPhase.secondarySub;
          break;
          
        case WheelPhase.secondarySub:
          if (categoryName.isEmpty || categoryName.startsWith('Overall')) {
             notifier.setSecondaryFlavor(_tempMainSelection!, '', '');
             _resetTemps();
             _currentPhase = WheelPhase.completed;
          } else {
             final Map<String, List<String>> subMap = flavorTree[_tempMainSelection!]!['sub'];
             final List<String> tertiaryList = subMap[categoryName] ?? [];
             
             if (tertiaryList.isEmpty) {
                notifier.setSecondaryFlavor(_tempMainSelection!, categoryName, '');
                _resetTemps();
                _currentPhase = WheelPhase.completed;
             } else {
                _tempSubSelection = categoryName;
                _tempSubIndex = index;
                _currentPhase = WheelPhase.secondaryTertiary;
             }
          }
          break;
          
        case WheelPhase.secondaryTertiary:
          notifier.setSecondaryFlavor(_tempMainSelection!, _tempSubSelection!, categoryName);
          _resetTemps();
          _currentPhase = WheelPhase.completed;
          break;
          
        case WheelPhase.completed:
          break;
      }
    });
  }

  void _resetTemps() {
    _tempMainSelection = null;
    _tempMainIndex = null;
    _tempSubSelection = null;
    _tempSubIndex = null;
  }

  void _resetWheel() {
    ref.read(tastingProvider.notifier).clearAllFlavors();
    setState(() {
      _currentPhase = WheelPhase.primaryMain;
      _resetTemps();
      _animationKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tastingData = ref.watch(tastingProvider);
    final asyncCache = ref.watch(iconCacheProvider);

    return asyncCache.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Cache Error: $err'))),
      data: (loadedIcons) {
        
        List<Map<String, dynamic>> activeCategories = [];
        double baseStartAngle = -math.pi / 2;
        double totalSweepAngle = 2 * math.pi;

        if (_currentPhase == WheelPhase.primaryMain || _currentPhase == WheelPhase.secondaryMain) {
          activeCategories = mainFlavorCategories; 
        } 
        else if ((_currentPhase == WheelPhase.primarySub || _currentPhase == WheelPhase.secondarySub) && _tempMainSelection != null && _tempMainIndex != null) {
          final treeNode = flavorTree[_tempMainSelection];
          if (treeNode == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _resetWheel());
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final parentColor = treeNode['color'] as Color;
          final subMap = treeNode['sub'] as Map<String, List<String>>;
          final subList = subMap.keys.toList();
          
          subList.insert(0, 'Overall\n$_tempMainSelection'); 

          activeCategories = subList.map((subName) => {'name': subName, 'color': parentColor}).toList();
          
          double parentSweepAngle = (2 * math.pi) / mainFlavorCategories.length;
          double parentMiddleAngle = -math.pi / 2 + (_tempMainIndex! * parentSweepAngle) + (parentSweepAngle / 2);

          totalSweepAngle = 160 * (math.pi / 180);
          baseStartAngle = parentMiddleAngle - (totalSweepAngle / 2);
        }
        else if ((_currentPhase == WheelPhase.primaryTertiary || _currentPhase == WheelPhase.secondaryTertiary) && _tempMainSelection != null && _tempSubSelection != null) {
          final parentColor = flavorTree[_tempMainSelection!]!['color'] as Color;
          final Map<String, List<String>> subMap = flavorTree[_tempMainSelection!]!['sub'];
          final List<String> specificList = List.from(subMap[_tempSubSelection] ?? []);
          
          specificList.insert(0, 'Overall\n$_tempSubSelection'); 

          activeCategories = specificList.map((specName) => {'name': specName, 'color': parentColor}).toList();
          
          double grandParentSweep = (2 * math.pi) / mainFlavorCategories.length;
          double grandParentMiddle = -math.pi / 2 + (_tempMainIndex! * grandParentSweep) + (grandParentSweep / 2);
          double prevTotalSweep = 160 * (math.pi / 180);
          double prevBaseStart = grandParentMiddle - (prevTotalSweep / 2);
          
          int oldSubListLength = subMap.keys.length + 1; 
          double parentSweepAngle = prevTotalSweep / oldSubListLength;
          double parentMiddleAngle = prevBaseStart + (_tempSubIndex! * parentSweepAngle) + (parentSweepAngle / 2);

          // Półkole dla 3 poziomu (180 stopni)
          totalSweepAngle = 180 * (math.pi / 180); 
          baseStartAngle = parentMiddleAngle - (totalSweepAngle / 2);
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
              Text(
                _currentPhase.name.contains('Tertiary') ? "Select specific note" : "Follow the flavor path", 
                style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.w600, letterSpacing: 0.5)
              ),
              const SizedBox(height: 30),
              
              Center(
                child: _currentPhase == WheelPhase.completed 
                  ? const SizedBox(
                      height: 300, 
                      child: Center(child: Icon(Icons.check_circle, size: 100, color: Colors.green))
                    )
                  : GestureDetector(
                      onTapUp: (details) {
                        const double centerOffset = 150.0;
                        double dx = details.localPosition.dx - centerOffset;
                        double dy = details.localPosition.dy - centerOffset;

                        // Większy martwy punkt w środku koła, by uniknąć przypadkowych kliknięć
                        if (math.sqrt(dx * dx + dy * dy) < centerOffset * 0.35) return; 

                        double touchAngle = math.atan2(dy, dx);
                        double relativeAngle = (touchAngle - baseStartAngle) % (2 * math.pi);
                        if (relativeAngle < 0) relativeAngle += 2 * math.pi;

                        if (relativeAngle <= totalSweepAngle) {
                          int index = (relativeAngle / totalSweepAngle * activeCategories.length).floor();
                          if (index == activeCategories.length) index--; 
                          _handleSegmentTap(activeCategories[index]['name'], index);
                        }
                      },
                      // INŻYNIERIA PŁYNNOŚCI: Płynne, fizyczne "rozwijanie" wachlarza
                      child: TweenAnimationBuilder<double>(
                        key: _animationKey,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutQuart,
                        builder: (context, animValue, child) {
                          return CustomPaint(
                            size: const Size(300, 300),
                            painter: WheelPainter(
                              categories: activeCategories,
                              baseStartAngle: baseStartAngle,
                              totalSweepAngle: totalSweepAngle,
                              animMultiplier: animValue, // Przekazanie stanu animacji do silnika
                              loadedIcons: loadedIcons,
                              isInnerWheel: (_currentPhase == WheelPhase.primaryMain || _currentPhase == WheelPhase.secondaryMain)
                            ),
                          );
                        },
                      ),
                    ),
              ),
              
              const Spacer(),
              
              if (tastingData.primaryFlavorMain.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: Colors.blueGrey.withValues(alpha: 0.2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    child: ListTile(
                      title: const Text('Primary Flavor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        '${tastingData.primaryFlavorMain}'
                        '${tastingData.primaryFlavorSub.isNotEmpty ? " ➔ ${tastingData.primaryFlavorSub}" : ""}'
                        '${tastingData.primaryFlavorSpecific.isNotEmpty ? " ➔ ${tastingData.primaryFlavorSpecific}" : ""}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      leading: const Icon(Icons.star, color: Colors.amber),
                    ),
                  ),
                ),
              
              if (tastingData.secondaryFlavorMain.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    color: Colors.blueGrey.withValues(alpha: 0.2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    child: ListTile(
                      title: const Text('Secondary Flavor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        '${tastingData.secondaryFlavorMain}'
                        '${tastingData.secondaryFlavorSub.isNotEmpty ? " ➔ ${tastingData.secondaryFlavorSub}" : ""}'
                        '${tastingData.secondaryFlavorSpecific.isNotEmpty ? " ➔ ${tastingData.secondaryFlavorSpecific}" : ""}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      leading: const Icon(Icons.star_half, color: Colors.amberAccent),
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: PrimaryActionButton(
                  label: 'NEXT: FINAL EVALUATION',
                  onPressed: () => context.push('/evaluation'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double baseStartAngle;
  final double totalSweepAngle;
  final double animMultiplier;
  final Map<String, ui.Image> loadedIcons;
  final bool isInnerWheel;

  WheelPainter({
    required this.categories, 
    required this.baseStartAngle, 
    required this.totalSweepAngle,
    required this.animMultiplier,
    required this.loadedIcons,
    required this.isInnerWheel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Używamy z mnożnikiem animacji
    final double sweepAngle = (totalSweepAngle / categories.length) * animMultiplier;
    double currentAngle = baseStartAngle;

    for (var cat in categories) {
      final Color baseColor = cat['color'];
      
      // INŻYNIERIA ESTETYKI 1: Miękki RadialGradient zamiast płaskiego koloru
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          baseColor.withValues(alpha: 0.7), // Jaśniejszy środek
          baseColor, // Głęboki kolor na krawędziach
        ],
      ).createShader(rect);

      final paint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(rect, currentAngle, sweepAngle, true, paint);
      
      // INŻYNIERIA ESTETYKI 2: Przestrzeń negatywowa (grube linie w kolorze tła zamiast czarnych ramek)
      final borderPaint = Paint()
        ..color = const Color(0xFF121212) // Kolor tła aplikacji (Twój Scaffold background)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5; 
        
      canvas.drawArc(rect, currentAngle, sweepAngle, true, borderPaint);

      // Renderowanie zawartości wycinka z efektem Fade-In powiązanym z animacją
      if (animMultiplier > 0.5) {
        final opacity = (animMultiplier - 0.5) * 2; // Od 0 do 1 w drugiej połowie animacji
        
        if (isInnerWheel && cat.containsKey('icon') && loadedIcons.containsKey(cat['icon'])) {
           _drawIconAndText(canvas, center, radius, currentAngle, sweepAngle, cat['name'], loadedIcons[cat['icon']]!, opacity);
        } else {
           _drawText(canvas, center, radius, currentAngle, sweepAngle, cat['name'], 0.65, opacity);
        }
      }

      currentAngle += sweepAngle;
    }

    // Środek koła wycięty przestrzenią negatywową
    canvas.drawCircle(center, radius * 0.28, Paint()..color = const Color(0xFF121212));
  }

  void _drawIconAndText(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String text, ui.Image image, double opacity) {
    final double midAngle = startAngle + (sweepAngle / 2);
    
    // Rysowanie Ikony
    final double iconRadius = radius * 0.82; 
    final double imgX = center.dx + iconRadius * math.cos(midAngle);
    final double imgY = center.dy + iconRadius * math.sin(midAngle);

    canvas.save();
    canvas.translate(imgX, imgY);
    double rotation = midAngle + math.pi / 2;
    canvas.rotate(rotation);

    // INŻYNIERIA ESTETYKI 3: Białe ikony z lekką przezroczystością
    final paint = Paint()
      ..colorFilter = ColorFilter.mode(Colors.white.withValues(alpha: 0.85 * opacity), BlendMode.srcIn);

    canvas.drawImage(image, Offset(-image.width / 2, -image.height / 2), paint);
    canvas.restore();

    // Rysowanie Tekstu niżej
    _drawText(canvas, center, radius, startAngle, sweepAngle, text, 0.52, opacity);
  }

  void _drawText(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String text, double radiusMultiplier, double opacity) {
    final double textAngle = startAngle + (sweepAngle / 2);
    final double textRadius = radius * radiusMultiplier; 
    
    final double textX = center.dx + textRadius * math.cos(textAngle);
    final double textY = center.dy + textRadius * math.sin(textAngle);

    canvas.save();
    canvas.translate(textX, textY);
    
    double rotation = textAngle;
    if (rotation > math.pi / 2 && rotation < 3 * math.pi / 2) {
      rotation += math.pi;
    }
    canvas.rotate(rotation);

    final formattedText = text.replaceFirst('/', '/\n');
    final textSpan = TextSpan(
      text: formattedText,
      style: TextStyle(
        color: Colors.white.withValues(alpha: opacity), 
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.1,
        // INŻYNIERIA ESTETYKI 4: Miękki, rozproszony cień ułatwiający czytanie
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.8 * opacity), blurRadius: 4, offset: const Offset(0, 1.5)),
        ],
      ),
    );
    
    final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout(maxWidth: radius * 0.6); 
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    return oldDelegate.categories != categories || 
           oldDelegate.baseStartAngle != baseStartAngle ||
           oldDelegate.animMultiplier != animMultiplier ||
           oldDelegate.loadedIcons.length != loadedIcons.length;
  }
}