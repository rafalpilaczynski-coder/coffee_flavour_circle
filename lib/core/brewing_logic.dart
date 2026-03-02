// lib/core/brewing_logic.dart

class BrewingAssistant {
  static String getSuggestion({
    required double sweetness,
    required double acidity,
    required double bitterness,
    required double enjoyment,
  }) {
    // Jeśli ocena jest wysoka (4.0+), nie sugerujemy zmian – profil jest poprawny
    if (enjoyment >= 4.0) return "Profil optymalny. Zachowaj parametry.";

    // Analiza nadekstrakcji (Gorycz dominuje nad balansem)
    if (bitterness > sweetness + 2 && bitterness > acidity) {
      return "NADEKSTRAKCJA: Kawa zbyt gorzka/cierpka. \nSugestia: Zmiel kawę grubiej lub obniż temperaturę wody o 2-3°C.";
    }

    // Analiza podstrakcji (Kwasowość dominuje, brak słodyczy)
    if (acidity > sweetness + 2 && acidity > bitterness) {
      return "PODEKSTRAKCJA: Kawa zbyt kwaśna/słona. \nSugestia: Zmiel kawę drobniej lub użyj cieplejszej wody (+2°C).";
    }

    // Brak balansu (Płaski smak)
    if (enjoyment < 3.0 && sweetness < 4.0) {
      return "BRAK BALANSU: Smak płaski lub wodnisty. \nSugestia: Zwiększ dozę kawy lub wydłuż czas parzenia (drobniejszy przemiał).";
    }

    return "Eksperymentuj z czasem parzenia, aby zwiększyć słodycz.";
  }
}