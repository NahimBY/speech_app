import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognizer {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> initialize() async {
    return await _speech.initialize(onStatus: (status) {}, onError: (error) {});
  }

  void startListening(Function(String?) onResult) async {
    if (await _speech.isNotListening) {
      await _speech.listen(
        onResult: (result) {
          print("Resultado bruto: $result");
          onResult(result.recognizedWords);
        },
        cancelOnError: true,
      );
    }
  }

  void stopListening() async {
    if (await _speech.isListening) {
      await _speech.stop();
    }
  }
}
