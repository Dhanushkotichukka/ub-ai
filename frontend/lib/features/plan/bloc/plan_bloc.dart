import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/plan_repository.dart';
import '../../../shared/models/models.dart';

abstract class PlanEvent extends Equatable { const PlanEvent(); @override List<Object?> get props => []; }
class PlanLoadRequested extends PlanEvent { final String? date; const PlanLoadRequested({this.date}); @override List<Object?> get props => [date]; }
class PlanTaskToggled extends PlanEvent { final String taskId; final bool isCompleted; const PlanTaskToggled(this.taskId, this.isCompleted); @override List<Object?> get props => [taskId, isCompleted]; }
class PlanTaskAdded extends PlanEvent { final Map<String, dynamic> task; const PlanTaskAdded(this.task); @override List<Object?> get props => [task]; }
class PlanTaskDeleted extends PlanEvent { final String taskId; const PlanTaskDeleted(this.taskId); @override List<Object?> get props => [taskId]; }
class PlanAutoGenerateRequested extends PlanEvent {}

enum PlanStatus { initial, loading, loaded, error }

class PlanState extends Equatable {
  final PlanStatus status;
  final TodoPlanModel? plan;
  final String? error;
  const PlanState({this.status = PlanStatus.initial, this.plan, this.error});
  PlanState copyWith({PlanStatus? status, TodoPlanModel? plan, String? error}) => PlanState(status: status ?? this.status, plan: plan ?? this.plan, error: error);
  @override List<Object?> get props => [status, plan, error];
}

class PlanBloc extends Bloc<PlanEvent, PlanState> {
  final PlanRepository _repo;
  String? _currentDate;

  PlanBloc(this._repo) : super(const PlanState()) {
    on<PlanLoadRequested>(_onLoad);
    on<PlanTaskToggled>(_onToggle);
    on<PlanTaskAdded>(_onAdd);
    on<PlanTaskDeleted>(_onDelete);
    on<PlanAutoGenerateRequested>(_onAutoGenerate);
  }

  Future<void> _onLoad(PlanLoadRequested event, Emitter<PlanState> emit) async {
    _currentDate = event.date;
    emit(state.copyWith(status: PlanStatus.loading));
    try { final plan = await _repo.getPlan(date: event.date); emit(state.copyWith(status: PlanStatus.loaded, plan: plan)); }
    catch (e) { emit(state.copyWith(status: PlanStatus.error, error: e.toString())); }
  }

  Future<void> _onToggle(PlanTaskToggled event, Emitter<PlanState> emit) async {
    try { final plan = await _repo.updateTask(event.taskId, isCompleted: event.isCompleted, date: _currentDate); emit(state.copyWith(plan: plan)); }
    catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onAdd(PlanTaskAdded event, Emitter<PlanState> emit) async {
    try { final plan = await _repo.addTask(event.task, date: _currentDate); emit(state.copyWith(plan: plan)); }
    catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onDelete(PlanTaskDeleted event, Emitter<PlanState> emit) async {
    try { final plan = await _repo.deleteTask(event.taskId, date: _currentDate); emit(state.copyWith(plan: plan)); }
    catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onAutoGenerate(PlanAutoGenerateRequested event, Emitter<PlanState> emit) async {
    emit(state.copyWith(status: PlanStatus.loading));
    try { final plan = await _repo.autoGenerate(date: _currentDate); emit(state.copyWith(status: PlanStatus.loaded, plan: plan)); }
    catch (e) { emit(state.copyWith(status: PlanStatus.error, error: e.toString())); }
  }
}
