import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/home_repository.dart';
import '../../../shared/models/models.dart';

// Events
abstract class HomeEvent extends Equatable { const HomeEvent(); @override List<Object?> get props => []; }
class HomeLoadRequested extends HomeEvent {}
class HomeSyncRequested extends HomeEvent {}
class HomeRefreshRequested extends HomeEvent {}

// State
enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<PlatformStatsModel> platformStats;
  final Map<String, PotdModel?> potd;
  final List<ContestModel> contests;
  final Map<String, dynamic> analyticsOverview;
  final List<Map<String, dynamic>> heatmap;
  final String? error;

  const HomeState({
    this.status = HomeStatus.initial,
    this.platformStats = const [],
    this.potd = const {},
    this.contests = const [],
    this.analyticsOverview = const {},
    this.heatmap = const [],
    this.error,
  });

  HomeState copyWith({HomeStatus? status, List<PlatformStatsModel>? platformStats,
    Map<String, PotdModel?>? potd, List<ContestModel>? contests,
    Map<String, dynamic>? analyticsOverview, List<Map<String, dynamic>>? heatmap, String? error}) =>
    HomeState(
      status: status ?? this.status,
      platformStats: platformStats ?? this.platformStats,
      potd: potd ?? this.potd,
      contests: contests ?? this.contests,
      analyticsOverview: analyticsOverview ?? this.analyticsOverview,
      heatmap: heatmap ?? this.heatmap,
      error: error,
    );

  @override List<Object?> get props => [status, platformStats, potd, contests, analyticsOverview, heatmap, error];
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repo;
  HomeBloc(this._repo) : super(const HomeState()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeSyncRequested>(_onSync);
    on<HomeRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final results = await Future.wait([
        _repo.getPlatformStats(),
        _repo.getPOTD(),
        _repo.getUpcomingContests(),
        _repo.getAnalyticsOverview(),
        _repo.getHeatmap(),
      ]);
      emit(state.copyWith(
        status: HomeStatus.loaded,
        platformStats: results[0] as List<PlatformStatsModel>,
        potd: results[1] as Map<String, PotdModel?>,
        contests: results[2] as List<ContestModel>,
        analyticsOverview: results[3] as Map<String, dynamic>,
        heatmap: results[4] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSync(HomeSyncRequested event, Emitter<HomeState> emit) async {
    try {
      final stats = await _repo.syncPlatforms();
      emit(state.copyWith(platformStats: stats));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRefresh(HomeRefreshRequested event, Emitter<HomeState> emit) async {
    add(HomeLoadRequested());
  }
}
