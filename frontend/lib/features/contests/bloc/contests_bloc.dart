import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/contests_repository.dart';
import '../../../shared/models/models.dart';

// Events
abstract class ContestsEvent extends Equatable {
  const ContestsEvent();

  @override
  List<Object?> get props => [];
}

class FetchContests extends ContestsEvent {}

class FilterContests extends ContestsEvent {
  final String platform;

  const FilterContests(this.platform);

  @override
  List<Object?> get props => [platform];
}

// States
enum ContestsStatus { initial, loading, loaded, error }

class ContestsState extends Equatable {
  final ContestsStatus status;
  final List<ContestModel> allContests;
  final String selectedPlatform;
  final String? error;

  const ContestsState({
    this.status = ContestsStatus.initial,
    this.allContests = const [],
    this.selectedPlatform = 'All',
    this.error,
  });

  List<ContestModel> get filteredContests {
    if (selectedPlatform == 'All') return allContests;
    return allContests
        .where((c) => c.platform.toLowerCase() == selectedPlatform.toLowerCase())
        .toList();
  }

  ContestsState copyWith({
    ContestsStatus? status,
    List<ContestModel>? allContests,
    String? selectedPlatform,
    String? error,
  }) {
    return ContestsState(
      status: status ?? this.status,
      allContests: allContests ?? this.allContests,
      selectedPlatform: selectedPlatform ?? this.selectedPlatform,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, allContests, selectedPlatform, error];
}

// BLoC
class ContestsBloc extends Bloc<ContestsEvent, ContestsState> {
  final ContestsRepository _repository;

  ContestsBloc(this._repository) : super(const ContestsState()) {
    on<FetchContests>(_onFetchContests);
    on<FilterContests>(_onFilterContests);
  }

  Future<void> _onFetchContests(FetchContests event, Emitter<ContestsState> emit) async {
    emit(state.copyWith(status: ContestsStatus.loading, error: null));
    try {
      final contests = await _repository.getUpcomingContests();
      emit(state.copyWith(status: ContestsStatus.loaded, allContests: contests));
    } catch (e) {
      emit(state.copyWith(status: ContestsStatus.error, error: e.toString()));
    }
  }

  void _onFilterContests(FilterContests event, Emitter<ContestsState> emit) {
    emit(state.copyWith(selectedPlatform: event.platform));
  }
}
