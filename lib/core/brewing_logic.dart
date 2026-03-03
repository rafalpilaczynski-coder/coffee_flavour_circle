class BrewingAssistant {
  static String getAdvice({
    required double sweetness,
    required double acidity,
    required double bitterness,
    required double enjoyment,
  }) {
    // Profil optymalny
    if (enjoyment >= 4.0 && sweetness >= 7.0) {
      return "Optimal profile. Brewing parameters are well balanced.";
    }

    // Dominacja kwasowości (Under-extraction)
    if (acidity > sweetness + 2.0) {
      return "TOO ACIDIC: Probable under-extraction. Suggestion: Grind FINER or increase water temperature.";
    }

    // Dominacja goryczy (Over-extraction)
    if (bitterness > sweetness + 2.0) {
      return "TOO BITTER: Probable over-extraction. Suggestion: Grind COARSER or decrease water temperature.";
    }

    // Brak balansu / Płaski smak
    if (sweetness < 4.0 && enjoyment < 3.5) {
      return "FLAT PROFILE: Lacking sweetness. Try increasing the dose (Ratio) or extending the brew time.";
    }

    return "Experiment with contact time or ratio to enhance sweetness and balance.";
  }
}