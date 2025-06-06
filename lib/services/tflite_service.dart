import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'tokenizer.dart';

class TfliteService {
  late Interpreter interpreter;
  late Tokenizer tokenizer;
  late Map<String, dynamic> mapeoIntenciones;
  late Map<String, int> intencionAMapa;
  late Map<int, String> indiceAIntencion;
  late int maxLongitud;
  late int vocabSize;
  late List<String> nombresCompletos;

  Future<void> loadModel() async {
    final modelPath = 'assets/models/soccer_events_model_mejorado.tflite';
    interpreter = await Interpreter.fromAsset(modelPath);

    // Cargar mapeo de intenciones
    final mappingJson = jsonDecode(
      await rootBundle.loadString(
        'assets/models/intencion_mapeo_mejorado.json',
      ),
    );
    intencionAMapa = Map<String, int>.from(mappingJson['intencion_a_indice']);
    indiceAIntencion = {};
    for (var entry in intencionAMapa.entries) {
      indiceAIntencion[entry.value] = entry.key;
    }
    maxLongitud = mappingJson['max_longitud'];
    vocabSize = mappingJson['vocab_size'];

    // Cargar tokenizador
    tokenizer = Tokenizer();
    await tokenizer.loadFromAsset(
      'assets/models/word_index.json',
      vocabSize,
      maxLongitud,
    );

    // Cargar nombres completos
    final namesJson = jsonDecode(
      await rootBundle.loadString('assets/models/names.json'),
    );
    final lastNamesJson = jsonDecode(
      await rootBundle.loadString('assets/models/last_names.json'),
    );

    final List<String> nombres = List<String>.from(namesJson['nombres']);
    final List<String> apellidos = List<String>.from(
      lastNamesJson['apellidos'],
    );

    nombresCompletos = [];
    for (var nombre in nombres) {
      for (var apellido in apellidos) {
        nombresCompletos.add("$nombre $apellido");
      }
    }
  }

  Future<Map<String, dynamic>> processText(String texto) async {
    // Limpiar texto
    String textoLimpio = limpiarTexto(texto);

    // Tokenizar
    List<int> input = tokenizer.textToSequence(textoLimpio);

    // Entrada para TFLite
    final inputTyped = [input]; // Agregar dimensión batch
    final outputTyped = List<double>.filled(intencionAMapa.length, 0.0);

    // Ejecutar modelo
    interpreter.run(inputTyped, outputTyped);

    // Procesar salida
    final probs = outputTyped;
    final indexedProbs = probs.asMap();
    MapEntry<int, double>? maxEntry;

    indexedProbs.forEach((key, value) {
      if (maxEntry == null || value > maxEntry!.value) {
        maxEntry = MapEntry(key, value);
      }
    });

    final intencionIdx =
        maxEntry?.key ?? 0; // Valor por defecto si no hay máximos

    final intencion = indiceAIntencion[intencionIdx];
    final confianza = probs[intencionIdx];

    // Extraer entidades
    final entidades = extraerEntidades(texto, intencion!);

    return {
      "intencion": intencion,
      "confianza": confianza,
      "entidades": entidades,
      "top_3_predicciones": getTopK(probs, 3),
    };
  }

  String limpiarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<List<dynamic>> getTopK(List<double> probs, int k) {
    var indexedProbs =
        probs.asMap().entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return indexedProbs
        .take(k)
        .map((e) => [indiceAIntencion[e.key], e.value])
        .toList();
  }

  Map<String, dynamic> extraerEntidades(String texto, String intencion) {
    final textoMin = texto.toLowerCase();
    final entidades = <String, dynamic>{};

    // Buscar nombres exactos o similares
    for (var nombre in nombresCompletos) {
      if (textoMin.contains(nombre.toLowerCase())) {
        entidades["jugador_nombre"] = nombre;
        return entidades;
      }
    }

    // Si no encontró nombre, buscar número
    final match = RegExp(
      r'(?:el\s+)?(?:número|#|jugador)\s+(\d+)',
    ).firstMatch(textoMin);
    if (match != null) {
      entidades["jugador_num"] = int.parse(match.group(1)!);
    }

    // Detectar equipos
    if (["gol", "penal", "corner"].contains(intencion)) {
      if (textoMin.contains("rojo")) {
        entidades["equipo"] = "rojo";
      } else if (textoMin.contains("azul")) {
        entidades["equipo"] = "azul";
      }
    }

    return entidades;
  }
}
