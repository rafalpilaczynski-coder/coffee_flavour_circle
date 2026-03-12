// lib/screens/coffee_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/coffee_library_provider.dart';
import '../providers/tasting_provider.dart'; // Wymagane do pobrania historii i bazy palarni
//import '../core/constants.dart';

class CoffeeLibraryScreen extends ConsumerWidget {
  const CoffeeLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(coffeeLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Library'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1E1A18),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => const _AddCoffeeModalContent(),
          );
        },
      ),
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (coffees) {
          if (coffees.isEmpty) {
            return const Center(
              child: Text('Your library is empty.\nTap + to add your first bag of beans.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: coffees.length,
            itemBuilder: (context, index) {
              final bean = coffees[index];
              return Dismissible(
                key: Key(bean.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ref.read(coffeeLibraryProvider.notifier).deleteCoffee(bean.id),
                child: _CoffeeBagCard(bean: bean),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// INŻYNIERIA UI: KARTA POJEDYNCZEJ PACZKI KAWY
// ==========================================
class _CoffeeBagCard extends ConsumerStatefulWidget {
  final CoffeeBean bean;

  const _CoffeeBagCard({required this.bean});

  @override
  ConsumerState<_CoffeeBagCard> createState() => _CoffeeBagCardState();
}

class _CoffeeBagCardState extends ConsumerState<_CoffeeBagCard> {
  late TextEditingController _priceController;
  bool _isEditingPrice = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.bean.price > 0 ? widget.bean.price.toStringAsFixed(2) : '');
  }

  @override
  void didUpdateWidget(covariant _CoffeeBagCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bean.price != widget.bean.price && !_isEditingPrice) {
      _priceController.text = widget.bean.price > 0 ? widget.bean.price.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _savePrice() {
    final newPrice = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
    ref.read(coffeeLibraryProvider.notifier).updateCoffeePrice(widget.bean.id, newPrice);
    setState(() {
      _isEditingPrice = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Wyciąganie i filtrowanie historii dla tej konkretnej paczki
    final historyAsync = ref.watch(historyProvider);
    final history = historyAsync.value ?? [];
    
    final beanBrews = history.where((h) => h['libraryId'] == widget.bean.id).toList();
    final last5Brews = beanBrews.take(5).toList(); // Zakładamy, że najnowsze są na początku listy
    
    // 2. Obliczanie średniej oceny
    double avgEnjoyment = 0.0;
    if (beanBrews.isNotEmpty) {
      final total = beanBrews.fold(0.0, (sum, brew) => sum + ((brew['enjoyment'] as num?)?.toDouble() ?? 0.0));
      avgEnjoyment = total / beanBrews.length;
    }

    // 3. Status zużycia
    final percentLeft = (widget.bean.remainingWeight / widget.bean.initialWeight).clamp(0.0, 1.0);
    final isAlmostEmpty = percentLeft < 0.15;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: isAlmostEmpty ? Colors.red.withValues(alpha: 0.3) : Colors.white10)
      ),
      color: const Color(0xFF1E1A18),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: Colors.amber,
        collapsedIconColor: Colors.grey,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        
        // ZAWARTOSĆ PRZED ROZWINIĘCIEM
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.bean.roaster.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                if (beanBrews.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text(avgEnjoyment.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                  )
                else
                  const Text('No brews yet', style: TextStyle(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic)),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.bean.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentLeft,
                    minHeight: 6,
                    backgroundColor: Colors.black45,
                    valueColor: AlwaysStoppedAnimation<Color>(isAlmostEmpty ? Colors.redAccent : Colors.amber),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text('${widget.bean.remainingWeight.toInt()}g', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isAlmostEmpty ? Colors.redAccent : Colors.white70), textAlign: TextAlign.right),
              ),
            ],
          ),
        ),

        // ZAWARTOSĆ PO ROZWINIĘCIU
        children: [
          Container(
            color: Colors.black12,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // POLE 1: KOSZT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bag Cost:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    _isEditingPrice 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                autofocus: true,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14, color: Colors.amber, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  suffixText: 'PLN',
                                  suffixStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                                onSubmitted: (_) => _savePrice(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green, size: 20),
                              onPressed: _savePrice,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: () => setState(() => _isEditingPrice = true),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.bean.price > 0 ? '${widget.bean.price.toStringAsFixed(2)} PLN' : 'Tap to add price', 
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.bean.price > 0 ? Colors.white : Colors.white38)
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: Colors.white10, height: 1),
                ),

                // POLE 2: HISTORIA OSTATNICH 5 PARZEŃ
                const Text('Last 5 Brews Enjoyment:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                if (last5Brews.isEmpty)
                  const Text('You haven\'t logged any brews with these beans yet.', style: TextStyle(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic))
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: last5Brews.map((brew) {
                      final val = (brew['enjoyment'] as num?)?.toDouble() ?? 0.0;
                      // Dynamiczny kolor na podstawie oceny
                      Color badgeColor = Colors.grey;
                      if (val >= 4.0) {badgeColor = Colors.green;}
                      else if (val >= 3.0) {badgeColor = Colors.amber;}
                      else if (val > 0) {badgeColor = Colors.orange;}

                      return Container(
                        margin: const EdgeInsets.only(right: 8.0),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Center(
                          child: Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor)),
                        ),
                      );
                    }).toList(),
                  ),
                  
                if (widget.bean.openDate != null) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Opened on: ${DateFormat('dd MMM yyyy').format(widget.bean.openDate!)}',
                      style: const TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// WYDZIELONY MODAL DODAWANIA KAWY
// ==========================================
class _AddCoffeeModalContent extends ConsumerStatefulWidget {
  const _AddCoffeeModalContent();

  @override
  ConsumerState<_AddCoffeeModalContent> createState() => _AddCoffeeModalContentState();
}

class _AddCoffeeModalContentState extends ConsumerState<_AddCoffeeModalContent> {
  final roasterCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final weightCtrl = TextEditingController(text: '250');
  final priceCtrl = TextEditingController();

  @override
  void dispose() {
    roasterCtrl.dispose();
    nameCtrl.dispose();
    weightCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roasteriesAsync = ref.watch(combinedRoasteriesProvider);
    final roasteriesList = roasteriesAsync.value ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add New Coffee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 16),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return roasteriesList.where((String option) => 
                  option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              roasterCtrl.text = selection;
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              controller.addListener(() {
                if (roasterCtrl.text != controller.text) {
                  roasterCtrl.text = controller.text;
                }
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Roaster (np. Friedhats)', isDense: true),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2C2520),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32,
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(option, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Bean Name / Origin', isDense: true)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight (g)', suffixText: 'g', isDense: true))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price', suffixText: 'PLN', isDense: true))),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              if (roasterCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              
              final initialWeight = double.tryParse(weightCtrl.text.replaceAll(',', '.')) ?? 250.0;
              final newBean = CoffeeBean(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                roaster: roasterCtrl.text,
                name: nameCtrl.text,
                initialWeight: initialWeight,
                remainingWeight: initialWeight,
                price: double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
                openDate: DateTime.now(),
              );
              
              ref.read(coffeeLibraryProvider.notifier).addCoffee(newBean);
              Navigator.pop(context);
            },
            child: const Text('SAVE TO LIBRARY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}