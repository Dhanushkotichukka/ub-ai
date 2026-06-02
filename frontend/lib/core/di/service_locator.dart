import 'package:get_it/get_it.dart';
import '../../shared/services/api_service.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/home/bloc/home_bloc.dart';
import '../../features/tracker/bloc/tracker_bloc.dart';
import '../../features/topics/data/topic_repository.dart';
import '../../features/topics/bloc/topic_bloc.dart';
import '../../features/plan/data/plan_repository.dart';
import '../../features/plan/bloc/plan_bloc.dart';
import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/bloc/notes_bloc.dart';
import '../../features/analytics/data/analytics_repository.dart';
import '../../features/analytics/bloc/analytics_bloc.dart';
import '../../features/contests/data/contests_repository.dart';
import '../../features/contests/bloc/contests_bloc.dart';
import '../../features/placement/data/placement_repository.dart';
import '../../features/placement/bloc/placement_bloc.dart';
import '../../features/revision/data/revision_repository.dart';
import '../../features/revision/bloc/revision_bloc.dart';
import '../../features/ai_coach/data/ai_coach_repository.dart';
import '../../features/ai_coach/bloc/ai_coach_bloc.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ─── Core Services ─────────────────────────────────────────────
  sl.registerLazySingleton<ApiService>(() => ApiService());

  // ─── Repositories ──────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl()));
  sl.registerLazySingleton<HomeRepository>(() => HomeRepository(sl()));
  sl.registerLazySingleton<TrackerRepository>(() => TrackerRepository(sl()));
  sl.registerLazySingleton<TopicRepository>(() => TopicRepository(sl()));
  sl.registerLazySingleton<PlanRepository>(() => PlanRepository(sl()));
  sl.registerLazySingleton<NotesRepository>(() => NotesRepository(sl()));
  sl.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepository(sl()));
  sl.registerLazySingleton<ContestsRepository>(() => ContestsRepository(sl()));
  sl.registerLazySingleton<PlacementRepository>(() => PlacementRepository(sl()));
  sl.registerLazySingleton<RevisionRepository>(() => RevisionRepository(sl()));
  sl.registerLazySingleton<AiCoachRepository>(() => AiCoachRepository(sl()));

  // ─── BLoCs ─────────────────────────────────────────────────────
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<HomeBloc>(() => HomeBloc(sl()));
  sl.registerFactory<TrackerBloc>(() => TrackerBloc(sl()));
  sl.registerFactory<TopicBloc>(() => TopicBloc(sl()));
  sl.registerFactory<PlanBloc>(() => PlanBloc(sl()));
  sl.registerFactory<NotesBloc>(() => NotesBloc(sl()));
  sl.registerFactory<AnalyticsBloc>(() => AnalyticsBloc(sl()));
  sl.registerFactory<ContestsBloc>(() => ContestsBloc(sl()));
  sl.registerFactory<PlacementBloc>(() => PlacementBloc(sl()));
  sl.registerFactory<RevisionBloc>(() => RevisionBloc(sl()));
  sl.registerFactory<AiCoachBloc>(() => AiCoachBloc(sl()));
}
