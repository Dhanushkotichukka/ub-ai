import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/analytics_repository.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class FetchAnalyticsData extends AnalyticsEvent {}
class GenerateWeeklyReport extends AnalyticsEvent {}

// States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsGeneratingReport extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> reports;

  const AnalyticsLoaded({required this.overview, required this.reports});

  @override
  List<Object?> get props => [overview, reports];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsBloc(this._repository) : super(AnalyticsInitial()) {
    on<FetchAnalyticsData>(_onFetchAnalyticsData);
    on<GenerateWeeklyReport>(_onGenerateWeeklyReport);
  }

  Future<void> _onFetchAnalyticsData(FetchAnalyticsData event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    try {
      final results = await Future.wait([
        _repository.fetchOverview(),
        _repository.fetchReports(),
      ]);
      emit(AnalyticsLoaded(
        overview: results[0] as Map<String, dynamic>,
        reports: results[1] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onGenerateWeeklyReport(GenerateWeeklyReport event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoaded) {
      final currentState = state as AnalyticsLoaded;
      emit(AnalyticsGeneratingReport());
      try {
        await _repository.generateReport();
        add(FetchAnalyticsData());
      } catch (e) {
        emit(AnalyticsError(e.toString()));
        emit(currentState);
      }
    }
  }
}
