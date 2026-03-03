import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';

class FragranceNotesScreen extends ConsumerStatefulWidget {
  const FragranceNotesScreen({super.key});

  @override
  ConsumerState<FragranceNotesScreen> createState() => _FragranceNotesScreenState();
}

class _FragranceNotesScreenState extends ConsumerState<FragranceNotesScreen> {
  bool _isDryAroma = true;

  @override
  Widget build(BuildContext context) {
    final tastingData = ref.watch(tastingProvider);
    final notifier = ref.read(tastingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Fragrance Notes'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Dry Aroma'), icon: Icon(Icons.grain)),
                ButtonSegment(value: false, label: Text('Wet Aroma'), icon: Icon(Icons.water_drop)),
              ],
              selected: {_isDryAroma},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() => _isDryAroma = newSelection.first);
              },
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: aromaCategories.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: entry.value.map((note) {
                        final bool isSelected = _isDryAroma 
                            ? tastingData.dryNotes.contains(note) 
                            : tastingData.wetNotes.contains(note);
                        
                        return FilterChip(
                          label: Text(note),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (_isDryAroma) {
                              notifier.toggleDryNote(note);
                            } else {
                              notifier.toggleWetNote(note);
                            }
                          },
                          selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                          checkmarkColor: Colors.blueAccent,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PrimaryActionButton(
              label: 'NEXT: FLAVOR WHEEL',
              onPressed: () => context.push('/wheel'),
            ),
          ),
        ],
      ),
    );
  }
}