import 'speech_cubit.dart';
import 'package:equatable/equatable.dart';


abstract class SpeechState extends Equatable {
  const SpeechState();
  @override
  List<Object?> get props => [];
}

class SpeechInitial extends SpeechState {}

class SpeechListening extends SpeechState {}

class SpeechRecognized extends SpeechState {
  final String text;
  final Map<String, dynamic> intention;

  const SpeechRecognized({required this.text, required this.intention});

  @override
  List<Object?> get props => [text, intention];
}

class SpeechStopped extends SpeechState {}