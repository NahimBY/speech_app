import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Tokenizer {
  late Map<String, int> wordIndex;
  late int numWords; // max_palabras
  late int maxLength; // max_longitud
  late String oovToken;

  Tokenizer({this.oovToken = '<OOV>'});

  Future<void> loadFromAsset(String assetPath, int maxPalabras, int maxLongitud) async {
    final jsonString = await rootBundle.loadString(assetPath);
    wordIndex = Map<String, int>.from(jsonDecode(jsonString));
    numWords = maxPalabras;
    maxLength = maxLongitud;
  }

  List<int> textToSequence(String text) {
    final words = text.split(' ');
    final sequence = <int>[];

    for (var word in words) {
      if (sequence.length >= maxLength) break;

      final wordLower = word.trim().toLowerCase();
      final index = wordIndex[wordLower] ?? wordIndex[oovToken];

      if (index != null && index <= numWords) {
        sequence.add(index);
      } else {
        sequence.add(0); // O fuera de rango si no hay OOV
      }
    }

    // Padding
    while (sequence.length < maxLength) {
      sequence.add(0);
    }

    return sequence.sublist(0, maxLength);
  }

  List<List<int>> textsToSequences(List<String> texts) {
    return texts.map(textToSequence).toList();
  }
}