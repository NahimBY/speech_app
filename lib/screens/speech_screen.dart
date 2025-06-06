import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_app/cubits/speech_state.dart';
import 'package:speech_app/services/speech_recognizer.dart';
import 'package:speech_app/services/tflite_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../cubits/speech_cubit.dart';

class SpeechScreen extends StatelessWidget {
  final TfliteService tfliteService;

  const SpeechScreen({super.key, required this.tfliteService});

  @override
  Widget build(BuildContext context) {
    final speechRecognizer = SpeechRecognizer();
    final cubit = SpeechCubit();

    return BlocProvider<SpeechCubit>(
      create: (_) => cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text("DataSoccer")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlocBuilder<SpeechCubit, SpeechState>(
                builder: (context, state) {
                  Color buttonColor = Colors.blue;
                  String displayText = "Presiona y mantén para hablar...";

                  if (state is SpeechListening) {
                    buttonColor = Colors.red;
                    displayText = "Escuchando...";
                  } else if (state is SpeechRecognized) {
                    displayText =
                        "Texto: ${state.text}\n"
                        "Acción: ${state.intention['intencion']}\n"
                        "Confianza: ${state.intention['confianza'].toStringAsFixed(3)}\n"
                        "Entidades: ${state.intention['entidades']}";
                  }

                  return GestureDetector(
                    onLongPress: () async {
                      bool available = await speechRecognizer.initialize();
                      if (available) {
                        cubit.startListening();
                        speechRecognizer.startListening((result) {
                          if (result != null && result.isNotEmpty) {
                            tfliteService.processText(result).then((
                              intentResult,
                            ) {
                              // cubit.updateRecognizedText(result, intentResult);
                              cubit.updateRecognizedText(result);
                            });
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("STT no disponible")),
                        );
                      }
                    },
                    onLongPressEnd: (_) {
                      speechRecognizer.stopListening();
                      cubit.stopListening();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: buttonColor, width: 3),
                      ),
                      child: IconButton(
                        iconSize: 140,
                        color: buttonColor,
                        onPressed: null,
                        icon: const Icon(Icons.mic_none_rounded),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              BlocBuilder<SpeechCubit, SpeechState>(
                builder: (context, state) {
                  String displayText = "Presiona y mantén para hablar...";

                  if (state is SpeechListening) {
                    displayText = "Escuchando...";
                  } else if (state is SpeechRecognized) {
                    displayText =
                        "Texto: ${state.text}\n"
                        "Acción: ${state.intention['intencion']}\n"
                        "Entidades: ${state.intention['entidades']} \n"
                        "Confianza: ${state.intention['confianza'].toStringAsFixed(3)}";
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      displayText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}