// lib/models/tasting_state.dart

class TastingState {
  final String method;
  final String coffeeName;
  final double temperature;
  final double dose;
  final double waterVolume;
  final String grinderName;
  final String grinderSetting;
  final Set<String> dryNotes;
  final Set<String> wetNotes;
  
  final String? primaryFlavorMain;
  final String? primaryFlavorSub;
  final String? secondaryFlavorMain;
  final String? secondaryFlavorSub;

  final double sweetness;
  final double acidity;
  final double bitterness;
  final double enjoyment;

  const TastingState({
    this.method = 'V60',
    this.coffeeName = '',
    this.temperature = 93.0,
    this.dose = 15.0,
    this.waterVolume = 250.0,
    this.grinderName = '',
    this.grinderSetting = '',
    this.dryNotes = const {},
    this.wetNotes = const {},
    this.primaryFlavorMain,
    this.primaryFlavorSub,
    this.secondaryFlavorMain,
    this.secondaryFlavorSub,
    this.sweetness = 5.0,
    this.acidity = 5.0,
    this.bitterness = 5.0,
    this.enjoyment = 3.0,
  });

  TastingState copyWith({
    String? method,
    String? coffeeName,
    double? temperature,
    double? dose,
    double? waterVolume,
    String? grinderName,
    String? grinderSetting,
    Set<String>? dryNotes,
    Set<String>? wetNotes,
    String? primaryFlavorMain,
    String? primaryFlavorSub,
    String? secondaryFlavorMain,
    String? secondaryFlavorSub,
    double? sweetness,
    double? acidity,
    double? bitterness,
    double? enjoyment,
    bool clearSecondary = false,
  }) {
    return TastingState(
      method: method ?? this.method,
      coffeeName: coffeeName ?? this.coffeeName,
      temperature: temperature ?? this.temperature,
      dose: dose ?? this.dose,
      waterVolume: waterVolume ?? this.waterVolume,
      grinderName: grinderName ?? this.grinderName,
      grinderSetting: grinderSetting ?? this.grinderSetting,
      dryNotes: dryNotes ?? this.dryNotes,
      wetNotes: wetNotes ?? this.wetNotes,
      primaryFlavorMain: primaryFlavorMain ?? this.primaryFlavorMain,
      primaryFlavorSub: primaryFlavorSub ?? this.primaryFlavorSub,
      secondaryFlavorMain: clearSecondary ? null : (secondaryFlavorMain ?? this.secondaryFlavorMain),
      secondaryFlavorSub: clearSecondary ? null : (secondaryFlavorSub ?? this.secondaryFlavorSub),
      sweetness: sweetness ?? this.sweetness,
      acidity: acidity ?? this.acidity,
      bitterness: bitterness ?? this.bitterness,
      enjoyment: enjoyment ?? this.enjoyment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'method': method,
      'coffeeName': coffeeName,
      'temperature': temperature,
      'dose': dose,
      'waterVolume': waterVolume,
      'grinderName': grinderName,
      'grinderSetting': grinderSetting,
      'dryNotes': dryNotes.toList(),
      'wetNotes': wetNotes.toList(),
      'primaryFlavorMain': primaryFlavorMain,
      'primaryFlavorSub': primaryFlavorSub,
      'secondaryFlavorMain': secondaryFlavorMain,
      'secondaryFlavorSub': secondaryFlavorSub,
      'sweetness': sweetness,
      'acidity': acidity,
      'bitterness': bitterness,
      'enjoyment': enjoyment,
    };
  }
}