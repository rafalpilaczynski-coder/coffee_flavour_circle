// lib/screens/flavor_wheel_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';

// INŻYNIERIA DANYCH: Rozszerzono maszynę stanów o trzeci poziom (Tertiary)
enum WheelPhase { 
  primaryMain, primarySub, primaryTertiary, 
  secondaryMain, secondarySub, secondaryTertiary, 
  tertiaryMain, tertiarySub, tertiaryTertiary, 
  completed 
}

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

  Key _animationKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPhaseWithProvider());
  }

  // Synchronizuje interfejs z twardymi danymi w pamięci, aby uniknąć rozjazdów stanów
  void _syncPhaseWithProvider() {
    final data = ref.read(tastingProvider);
    setState(() {
      _resetTemps();
      _animationKey = UniqueKey();
      if (data.primaryFlavorMain.isEmpty) {
        _currentPhase = WheelPhase.primaryMain;
      } else if (data.secondaryFlavorMain.isEmpty) {
        _currentPhase = WheelPhase.secondaryMain;
      } else if (data.tertiaryFlavorMain.isEmpty) {
        _currentPhase = WheelPhase.tertiaryMain;
      } else {
        _currentPhase = WheelPhase.completed;
      }
    });
  }

 void _handleSegmentTap(String categoryName, int index) {
    final notifier = ref.read(tastingProvider.notifier);
    
    if (categoryName.startsWith('Overall\n')) {
      categoryName = '';
    }

    setState(() {
      _animationKey = UniqueKey();

      switch (_currentPhase) {
        // --- POZIOM 1 ---
        case WheelPhase.primaryMain:
          _tempMainSelection = categoryName;
          _tempMainIndex = index;
          _currentPhase = WheelPhase.primarySub;
          break;
        case WheelPhase.primarySub:
          if (categoryName.isEmpty || categoryName.startsWith('Overall')) {
             notifier.setPrimaryFlavor(_tempMainSelection!, '', '');
             _syncPhaseWithProvider();
          } else {
             final subMap = flavorTree[_tempMainSelection!]!['sub'] as Map<String, List<String>>;
             final tertiaryList = subMap[categoryName] ?? [];
             if (tertiaryList.isEmpty) {
                notifier.setPrimaryFlavor(_tempMainSelection!, categoryName, '');
                _syncPhaseWithProvider();
             } else {
                _tempSubSelection = categoryName;
                _tempSubIndex = index;
                _currentPhase = WheelPhase.primaryTertiary;
             }
          }
          break;
        case WheelPhase.primaryTertiary:
          notifier.setPrimaryFlavor(_tempMainSelection!, _tempSubSelection!, categoryName);
          _syncPhaseWithProvider();
          break;

        // --- POZIOM 2 ---
        case WheelPhase.secondaryMain:
          _tempMainSelection = categoryName;
          _tempMainIndex = index;
          _currentPhase = WheelPhase.secondarySub;
          break;
        case WheelPhase.secondarySub:
          if (categoryName.isEmpty || categoryName.startsWith('Overall')) {
             notifier.setSecondaryFlavor(_tempMainSelection!, '', '');
             _syncPhaseWithProvider();
          } else {
             final subMap = flavorTree[_tempMainSelection!]!['sub'] as Map<String, List<String>>;
             final tertiaryList = subMap[categoryName] ?? [];
             if (tertiaryList.isEmpty) {
                notifier.setSecondaryFlavor(_tempMainSelection!, categoryName, '');
                _syncPhaseWithProvider();
             } else {
                _tempSubSelection = categoryName;
                _tempSubIndex = index;
                _currentPhase = WheelPhase.secondaryTertiary;
             }
          }
          break;
        case WheelPhase.secondaryTertiary:
          notifier.setSecondaryFlavor(_tempMainSelection!, _tempSubSelection!, categoryName);
          _syncPhaseWithProvider();
          break;

        // --- POZIOM 3 ---
        case WheelPhase.tertiaryMain:
          _tempMainSelection = categoryName;
          _tempMainIndex = index;
          _currentPhase = WheelPhase.tertiarySub;
          break;
        case WheelPhase.tertiarySub:
          if (categoryName.isEmpty || categoryName.startsWith('Overall')) {
             notifier.setTertiaryFlavor(_tempMainSelection!, '', '');
             _syncPhaseWithProvider(); // BŁĄD BYŁ TU: Przejdzie do 'completed' w _syncPhaseWithProvider
          } else {
             final subMap = flavorTree[_tempMainSelection!]!['sub'] as Map<String, List<String>>;
             final specificList = subMap[categoryName] ?? [];
             if (specificList.isEmpty) {
                // BŁĄD BYŁ TU: Zapisanie smaku bez "specific" i wymuszenie synca
                notifier.setTertiaryFlavor(_tempMainSelection!, categoryName, '');
                _syncPhaseWithProvider(); 
             } else {
                _tempSubSelection = categoryName;
                _tempSubIndex = index;
                _currentPhase = WheelPhase.tertiaryTertiary;
             }
          }
          break;
        case WheelPhase.tertiaryTertiary:
          // BŁĄD BYŁ TU: Trzeba było podać _tempSubSelection, a nie pusty string.
          notifier.setTertiaryFlavor(_tempMainSelection!, _tempSubSelection!, categoryName);
          _syncPhaseWithProvider();
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

  // INŻYNIERIA UX: Funkcja cofa tylko obecną, niedokończoną ścieżkę.
  void _undoCurrentPath() {
    _syncPhaseWithProvider();
  }

  void _removeFlavorRecord(int index) {
    ref.read(tastingProvider.notifier).removeFlavor(index);
    _syncPhaseWithProvider();
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

        bool isMainPhase = _currentPhase == WheelPhase.primaryMain || _currentPhase == WheelPhase.secondaryMain || _currentPhase == WheelPhase.tertiaryMain;
        bool isSubPhase = _currentPhase == WheelPhase.primarySub || _currentPhase == WheelPhase.secondarySub || _currentPhase == WheelPhase.tertiarySub;
        bool isTertiaryPhase = _currentPhase == WheelPhase.primaryTertiary || _currentPhase == WheelPhase.secondaryTertiary || _currentPhase == WheelPhase.tertiaryTertiary;

        if (isMainPhase) {
          activeCategories = mainFlavorCategories; 
        } 
        else if (isSubPhase && _tempMainSelection != null && _tempMainIndex != null) {
          final treeNode = flavorTree[_tempMainSelection];
          if (treeNode == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _undoCurrentPath());
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
        else if (isTertiaryPhase && _tempMainSelection != null && _tempSubSelection != null) {
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

          totalSweepAngle = 180 * (math.pi / 180); 
          baseStartAngle = parentMiddleAngle - (totalSweepAngle / 2);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Flavor Wheel'), 
            centerTitle: true,
            // Ikona strzałki wstecz, która cofa tylko obecną ścieżkę
            actions: [
              if (!isMainPhase && _currentPhase != WheelPhase.completed)
                IconButton(
                  icon: const Icon(Icons.undo), 
                  tooltip: 'Reset current path',
                  onPressed: _undoCurrentPath,
                )
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                _currentPhase == WheelPhase.completed ? "Maximum flavors selected" :
                isTertiaryPhase ? "Select specific note" : "Follow the flavor path", 
                style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.w600, letterSpacing: 0.5)
              ),
              const SizedBox(height: 20),
              
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
                              animMultiplier: animValue, 
                              loadedIcons: loadedIcons,
                              isInnerWheel: isMainPhase
                            ),
                          );
                        },
                      ),
                    ),
              ),
              
              const Spacer(),
              
              // SEKCJA WYBRANYCH SMAKÓW (Maksymalnie 3)
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      if (tastingData.primaryFlavorMain.isNotEmpty) 
                        _buildFlavorCard('Primary Flavor', tastingData.primaryFlavorMain, tastingData.primaryFlavorSub, tastingData.primaryFlavorSpecific, Icons.star, Colors.amber, () => _removeFlavorRecord(1)),
                      if (tastingData.secondaryFlavorMain.isNotEmpty)
                        _buildFlavorCard('Secondary Flavor', tastingData.secondaryFlavorMain, tastingData.secondaryFlavorSub, tastingData.secondaryFlavorSpecific, Icons.star_half, Colors.amberAccent, () => _removeFlavorRecord(2)),
                      if (tastingData.tertiaryFlavorMain.isNotEmpty)
                        _buildFlavorCard('Tertiary Flavor', tastingData.tertiaryFlavorMain, tastingData.tertiaryFlavorSub, tastingData.tertiaryFlavorSpecific, Icons.star_border, Colors.amber.shade200, () => _removeFlavorRecord(3)),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
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

  Widget _buildFlavorCard(String title, String main, String sub, String specific, IconData icon, Color color, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        color: Colors.blueGrey.withValues(alpha: 0.2),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        child: ListTile(
          title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(
            '$main'
            '${sub.isNotEmpty ? " ➔ $sub" : ""}'
            '${specific.isNotEmpty ? " ➔ $specific" : ""}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
          ),
          leading: Icon(icon, color: color),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: onDelete,
            tooltip: 'Remove this note',
          ),
        ),
      ),
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
    
    final double sweepAngle = (totalSweepAngle / categories.length) * animMultiplier;
    double currentAngle = baseStartAngle;

    for (var cat in categories) {
      final Color baseColor = cat['color'];
      
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [baseColor.withValues(alpha: 0.7), baseColor],
      ).createShader(rect);

      final paint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(rect, currentAngle, sweepAngle, true, paint);
      
      final borderPaint = Paint()
        ..color = const Color(0xFF121212) 
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5; 
        
      canvas.drawArc(rect, currentAngle, sweepAngle, true, borderPaint);

      if (animMultiplier > 0.5) {
        final opacity = (animMultiplier - 0.5) * 2; 
        
        if (isInnerWheel && cat.containsKey('icon') && loadedIcons.containsKey(cat['icon'])) {
           _drawIconAndText(canvas, center, radius, currentAngle, sweepAngle, cat['name'], loadedIcons[cat['icon']]!, opacity);
        } else {
           _drawText(canvas, center, radius, currentAngle, sweepAngle, cat['name'], 0.65, opacity);
        }
      }

      currentAngle += sweepAngle;
    }

    canvas.drawCircle(center, radius * 0.28, Paint()..color = const Color(0xFF121212));
  }

  void _drawIconAndText(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String text, ui.Image image, double opacity) {
    final double midAngle = startAngle + (sweepAngle / 2);
    
    final double iconRadius = radius * 0.82; 
    final double imgX = center.dx + iconRadius * math.cos(midAngle);
    final double imgY = center.dy + iconRadius * math.sin(midAngle);

    canvas.save();
    canvas.translate(imgX, imgY);
    double rotation = midAngle + math.pi / 2;
    canvas.rotate(rotation);

    // INŻYNIERIA WYDAJNOŚCI I JAKOŚCI: Downsampling przez drawImageRect.
    // Zamiast rysować obraz bezpośrednio w 100% i liczyć na skalowanie matrycy, 
    // alokujemy docelowy prostokąt i wymuszamy na GPU antyaliasing interpolowany (FilterQuality.high).
    final double targetSize = radius * 0.22; // Dynamiczny rozmiar ikony zależny od ekranu
    final Rect srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dstRect = Rect.fromCenter(center: Offset.zero, width: targetSize, height: targetSize);

    final paint = Paint()
      ..filterQuality = FilterQuality.high // Wymusza ostrość pikseli
      ..colorFilter = ColorFilter.mode(Colors.white.withValues(alpha: 0.85 * opacity), BlendMode.srcIn);

    canvas.drawImageRect(image, srcRect, dstRect, paint);
    canvas.restore();

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