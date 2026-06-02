export '../../../shared/services/repositories.dart' show TrackerRepository;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/tracker_repository.dart';
import '../../../shared/models/models.dart';

// Events
abstract class TrackerEvent extends Equatable { const TrackerEvent(); @override List<Object?> get props => []; }
class TrackerLoadRequested extends TrackerEvent { final String? date; const TrackerLoadRequested({this.date}); @override List<Object?> get props => [date]; }
class TrackerAddLogRequested extends TrackerEvent { final Map<String, dynamic> data; const TrackerAddLogRequested(this.data); @override List<Object?> get props => [data]; }
class TrackerDeleteLogRequested extends TrackerEvent { final String id; const TrackerDeleteLogRequested(this.id); @override List<Object?> get props => [id]; }
class TrackerUpdateLogRequested extends TrackerEvent { final String id; final Map<String, dynamic> data; const TrackerUpdateLogRequested(this.id, this.data); @override List<Object?> get props => [id, data]; }

// State
enum TrackerStatus { initial, loading, loaded, adding, error }

class TrackerState extends Equatable {
  final TrackerStatus status;
  final List<DailyLogModel> logs;
  final Map<String, dynamic> todaySummary;
  final String? error;
  final Map<String, dynamic>? lastXpResult;

  const TrackerState({this.status = TrackerStatus.initial, this.logs = const [], this.todaySummary = const {}, this.error, this.lastXpResult});

  TrackerState copyWith({TrackerStatus? status, List<DailyLogModel>? logs, Map<String, dynamic>? todaySummary, String? error, Map<String, dynamic>? lastXpResult}) =>
    TrackerState(status: status ?? this.status, logs: logs ?? this.logs, todaySummary: todaySummary ?? this.todaySummary, error: error, lastXpResult: lastXpResult);

  @override List<Object?> get props => [status, logs, todaySummary, error, lastXpResult];
}

// BLoC
class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  final TrackerRepository _repo;

  TrackerBloc(this._repo) : super(const TrackerState()) {
    on<TrackerLoadRequested>(_onLoad);
    on<TrackerAddLogRequested>(_onAdd);
    on<TrackerDeleteLogRequested>(_onDelete);
    on<TrackerUpdateLogRequested>(_onUpdate);
  }

  Future<void> _onLoad(TrackerLoadRequested event, Emitter<TrackerState> emit) async {
    emit(state.copyWith(status: TrackerStatus.loading));
    try {
      final logs = await _repo.getLogs(date: event.date);
      emit(state.copyWith(status: TrackerStatus.loaded, logs: logs));
    } catch (e) { emit(state.copyWith(status: TrackerStatus.error, error: e.toString())); }
  }

  Future<void> _onAdd(TrackerAddLogRequested event, Emitter<TrackerState> emit) async {
    emit(state.copyWith(status: TrackerStatus.adding));
    try {
      final log = await _repo.addLog(event.data);
      emit(state.copyWith(status: TrackerStatus.loaded, logs: [log, ...state.logs]));
    } catch (e) { emit(state.copyWith(status: TrackerStatus.error, error: e.toString())); }
  }

  Future<void> _onDelete(TrackerDeleteLogRequested event, Emitter<TrackerState> emit) async {
    try {
      await _repo.deleteLog(event.id);
      emit(state.copyWith(logs: state.logs.where((l) => l.id != event.id).toList()));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onUpdate(TrackerUpdateLogRequested event, Emitter<TrackerState> emit) async {
    try {
      final updated = await _repo.updateLog(event.id, event.data);
      emit(state.copyWith(logs: state.logs.map((l) => l.id == event.id ? updated : l).toList()));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }
}
