import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/ai_coach_repository.dart';

// Events
abstract class AiCoachEvent extends Equatable {
  const AiCoachEvent();
  @override
  List<Object?> get props => [];
}

class FetchChatHistory extends AiCoachEvent {}

class SendMessage extends AiCoachEvent {
  final String message;
  const SendMessage(this.message);
  @override
  List<Object?> get props => [message];
}

// States
enum AiCoachStatus { initial, loading, loaded, sending, error }

class AiCoachState extends Equatable {
  final AiCoachStatus status;
  final List<Map<String, dynamic>> messages;
  final String? error;

  const AiCoachState({
    this.status = AiCoachStatus.initial,
    this.messages = const [],
    this.error,
  });

  AiCoachState copyWith({
    AiCoachStatus? status,
    List<Map<String, dynamic>>? messages,
    String? error,
  }) {
    return AiCoachState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, messages, error];
}

// BLoC
class AiCoachBloc extends Bloc<AiCoachEvent, AiCoachState> {
  final AiCoachRepository _repository;

  AiCoachBloc(this._repository) : super(const AiCoachState()) {
    on<FetchChatHistory>(_onFetchChatHistory);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onFetchChatHistory(FetchChatHistory event, Emitter<AiCoachState> emit) async {
    emit(state.copyWith(status: AiCoachStatus.loading));
    try {
      final messages = await _repository.fetchChatHistory();
      emit(state.copyWith(status: AiCoachStatus.loaded, messages: messages));
    } catch (e) {
      emit(state.copyWith(status: AiCoachStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<AiCoachState> emit) async {
    // Add user message optimistically
    final userMessage = {'role': 'user', 'content': event.message, 'timestamp': DateTime.now().toIso8601String()};
    final updatedMessages = List<Map<String, dynamic>>.from(state.messages)..add(userMessage);
    
    emit(state.copyWith(status: AiCoachStatus.sending, messages: updatedMessages));
    
    try {
      final reply = await _repository.sendMessage(event.message);
      final finalMessages = List<Map<String, dynamic>>.from(updatedMessages)..add(reply);
      emit(state.copyWith(status: AiCoachStatus.loaded, messages: finalMessages));
    } catch (e) {
      emit(state.copyWith(
        status: AiCoachStatus.loaded, 
        error: e.toString(),
        messages: updatedMessages // keep the user message even if it failed to send, maybe show error
      ));
    }
  }
}
