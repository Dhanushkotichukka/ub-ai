import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/placement_repository.dart';

// Events
abstract class PlacementEvent extends Equatable {
  const PlacementEvent();

  @override
  List<Object?> get props => [];
}

class LoadCompanies extends PlacementEvent {}

class SelectCompany extends PlacementEvent {
  final String companyName;
  const SelectCompany(this.companyName);

  @override
  List<Object?> get props => [companyName];
}

class AnalyzeResume extends PlacementEvent {
  final String resumeText;
  const AnalyzeResume(this.resumeText);

  @override
  List<Object?> get props => [resumeText];
}

// States
enum PlacementStatus { initial, loading, loaded, error }

class PlacementState extends Equatable {
  final PlacementStatus status;
  final List<dynamic> companies;
  final String? selectedCompany;
  final List<dynamic> companyQuestions;
  final bool companyLoading;
  final String? error;

  // ATS States
  final bool atsLoading;
  final Map<String, dynamic>? atsResult;
  final String? atsError;

  const PlacementState({
    this.status = PlacementStatus.initial,
    this.companies = const [],
    this.selectedCompany,
    this.companyQuestions = const [],
    this.companyLoading = false,
    this.error,
    this.atsLoading = false,
    this.atsResult,
    this.atsError,
  });

  PlacementState copyWith({
    PlacementStatus? status,
    List<dynamic>? companies,
    String? selectedCompany,
    List<dynamic>? companyQuestions,
    bool? companyLoading,
    String? error,
    bool? atsLoading,
    Map<String, dynamic>? atsResult,
    String? atsError,
  }) {
    return PlacementState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      companyQuestions: companyQuestions ?? this.companyQuestions,
      companyLoading: companyLoading ?? this.companyLoading,
      error: error,
      atsLoading: atsLoading ?? this.atsLoading,
      atsResult: atsResult ?? this.atsResult,
      atsError: atsError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        companies,
        selectedCompany,
        companyQuestions,
        companyLoading,
        error,
        atsLoading,
        atsResult,
        atsError,
      ];
}

// BLoC
class PlacementBloc extends Bloc<PlacementEvent, PlacementState> {
  final PlacementRepository _repository;

  PlacementBloc(this._repository) : super(const PlacementState()) {
    on<LoadCompanies>(_onLoadCompanies);
    on<SelectCompany>(_onSelectCompany);
    on<AnalyzeResume>(_onAnalyzeResume);
  }

  Future<void> _onLoadCompanies(LoadCompanies event, Emitter<PlacementState> emit) async {
    emit(state.copyWith(status: PlacementStatus.loading, error: null));
    try {
      final companies = await _repository.getCompanies();
      emit(state.copyWith(status: PlacementStatus.loaded, companies: companies));
    } catch (e) {
      emit(state.copyWith(status: PlacementStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSelectCompany(SelectCompany event, Emitter<PlacementState> emit) async {
    emit(state.copyWith(selectedCompany: event.companyName, companyLoading: true));
    try {
      final questions = await _repository.getCompanyQuestions(event.companyName);
      emit(state.copyWith(companyQuestions: questions, companyLoading: false));
    } catch (e) {
      // Keep loading false on error, could emit a side-effect error here but state handles UI
      emit(state.copyWith(companyLoading: false));
    }
  }

  Future<void> _onAnalyzeResume(AnalyzeResume event, Emitter<PlacementState> emit) async {
    if (event.resumeText.trim().isEmpty) return;

    emit(state.copyWith(atsLoading: true, atsError: null));
    try {
      final result = await _repository.analyzeResume(event.resumeText);
      emit(state.copyWith(atsLoading: false, atsResult: result));
    } catch (e) {
      emit(state.copyWith(atsLoading: false, atsError: e.toString()));
    }
  }
}
