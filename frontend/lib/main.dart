import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/constants/hive_keys.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/tracker/bloc/tracker_bloc.dart';
import 'features/topics/bloc/topic_bloc.dart';
import 'features/plan/bloc/plan_bloc.dart';
import 'features/notes/bloc/notes_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(HiveKeys.userBox);
  await Hive.openBox(HiveKeys.settingsBox);
  await Hive.openBox(HiveKeys.cacheBox);

  // Initialize service locator (GetIt)
  await setupServiceLocator();

  runApp(const UbAiApp());
}

class UbAiApp extends StatelessWidget {
  const UbAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),),
        BlocProvider<HomeBloc>(create: (_) => sl<HomeBloc>(),),
        BlocProvider<TrackerBloc>(create: (_) => sl<TrackerBloc>(),),
        BlocProvider<TopicBloc>(create: (_) => sl<TopicBloc>(),),
        BlocProvider<PlanBloc>(create: (_) => sl<PlanBloc>(),),
        BlocProvider<NotesBloc>(create: (_) => sl<NotesBloc>(),),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) => prev.settings?.darkMode != curr.settings?.darkMode,
        builder: (context, authState) {
          final isDark = authState.settings?.darkMode ?? true;
          return MaterialApp.router(
            title: 'UB AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
