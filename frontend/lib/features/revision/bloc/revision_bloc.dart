import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/revision_repository.dart';

// Events
abstract class RevisionEvent extends Equatable {
  const RevisionEvent();
  @override
  List<Object?> get props => [];
}

class LoadDueRevisions extends RevisionEvent {}

class MarkRevisionComplete extends RevisionEvent {
  final String revisionId;
  final int confidence;

  const MarkRevisionComplete(this.revisionId, this.confidence);

  @override
  List<Object?> get props => [revisionId, confidence];
}

// States
enum RevisionStatus { initial, loading, loaded, error }

class RevisionState extends Equatable {
  final RevisionStatus status;
  final List<Map<String, dynamic>> dueRevisions;
  final String? error;

  const RevisionState({
    this.status = RevisionStatus.initial,
    this.dueRevisions = const [],
    this.error,
  });

  RevisionState copyWith({
    RevisionStatus? status,
    List<Map<String, dynamic>>? dueRevisions,
    String? error,
  }) {
    return RevisionState(
      status: status ?? this.status,
      dueRevisions: dueRevisions ?? this.dueRevisions,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, dueRevisions, error];
}

// BLoC
class RevisionBloc extends Bloc<RevisionEvent, RevisionState> {
  final RevisionRepository _repository;

  RevisionBloc(this._repository) : super(const RevisionState()) {
    on<LoadDueRevisions>(_onLoadDueRevisions);
    on<MarkRevisionComplete>(_onMarkRevisionComplete);
  }

  Future<void> _onLoadDueRevisions(LoadDueRevisions event, Emitter<RevisionState> emit) async {
    emit(state.copyWith(status: RevisionStatus.loading));
    try {
      final revisions = await _repository.getDueRevisions();
      emit(state.copyWith(status: RevisionStatus.loaded, dueRevisions: revisions));
    } catch (e) {
      emit(state.copyWith(status: RevisionStatus.error, error: e.toString()));
    }
  }

  Future<void> _onMarkRevisionComplete(MarkRevisionComplete event, Emitter<RevisionState> emit) async {
    try {
      await _repository.markRevised(event.revisionId, event.confidence);
      
      // Remove the completed revision from the state
      final updatedRevisions = state.dueRevisions.where((r) => r['_id'] != event.revisionId).toList();
      emit(state.copyWith(dueRevisions: updatedRevisions));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
