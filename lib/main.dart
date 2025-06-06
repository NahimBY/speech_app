import 'package:flutter/material.dart';
import 'package:speech_app/screens/speech_screen.dart';
import 'package:speech_app/services/tflite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tfliteService = TfliteService();
  await tfliteService.loadModel(); // Carga completa antes de iniciar

  runApp(MyApp(tfliteService: tfliteService));
}

class MyApp extends StatelessWidget {
  final TfliteService tfliteService;

  const MyApp({super.key, required this.tfliteService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DataSoccer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SpeechScreen(tfliteService: tfliteService),
    );
  }
}
