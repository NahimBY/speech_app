import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_app/services/tflite_service.dart';
import 'speech_state.dart';

class SpeechCubit extends Cubit<SpeechState> {
  final TfliteService _iaService = TfliteService();

  SpeechCubit() : super(SpeechInitial());

  void startListening() => emit(SpeechListening());

  void updateRecognizedText(String text) async {
    final result = await _iaService.processText(text);
    emit(SpeechRecognized(text: text, intention: result));
  }

  void stopListening() => emit(SpeechStopped());
}