import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../bloc/home_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../shared/widgets/owl_button.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/link_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../revision/bloc/revision_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final greeting = _getGreeting();

        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            return RefreshIndicator(
              onRefresh: () async => context.read<HomeBloc>().add(HomeRefreshRequested()),
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // ─── App Bar ──────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: true,
                    snap: true,
                    backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                    titleSpacing: 16,
                    title: Row(children: [
                      if (user?.profilePic.isNotEmpty == true)
                        CircleAvatar(radius: 18, backgroundImage: NetworkImage(user!.profilePic))
                      else
                        CircleAvatar(radius: 18, backgroundColor: AppColors.primary,
                          child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(user?.name ?? 'Student', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (user?.rollNumber.isNotEmpty == true)
                          Text(user!.rollNumber, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
                      ])),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.sync_rounded), onPressed: () => context.read<HomeBloc>().add(HomeSyncRequested()), tooltip: 'Sync Stats'),
                        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.go('/settings')),
                      ]),
                    ]),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // ─── Welcome Card ──────────────────────────
                        _WelcomeCard(
                          greeting: greeting,
                          name: user?.name.split(' ').first ?? 'Coder',
                          streak: user?.streak ?? 0,
                          xp: user?.xp ?? 0,
                          level: user?.level ?? 1,
                        ).animate().fadeIn().slideY(begin: 0.2),

                        const SizedBox(height: 20),

                        // ─── Platform Stats ────────────────────────
                        _SectionTitle('Platform Stats', onAction: () {}, actionLabel: '↻ Sync'),

                        if (homeState.status == HomeStatus.loading)
                          ..._buildShimmerCards()
                        else if (homeState.platformStats.isEmpty)
                          _EmptyPlatformCard(onConnect: () => context.go('/settings'))
                        else
                          ...homeState.platformStats.map((s) => _buildPlatformCard(s)),

                        const SizedBox(height: 20),

                        // ─── Spaced Repetition Widget ──────────────
                        _SectionTitle('Spaced Repetition', onAction: () => context.go('/revision'), actionLabel: 'Review Due'),
                        _DueRevisionWidget(),

                        const SizedBox(height: 20),

                        // ─── POTD ──────────────────────────────────
                        const _SectionTitle('Problem of the Day'),
                        _PotdWidget(potd: homeState.potd).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 20),

                        // ─── Coding Sheet Progress ─────────────────
                        _SectionTitle('Coding Sheets', onAction: () => context.go('/plan'), actionLabel: 'View All'),
                        const _SheetsProgress().animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 20),

                        // ─── Weekly Heatmap ────────────────────────
                        _SectionTitle('Activity (Last 7 Days)', onAction: () => context.go('/analytics'), actionLabel: 'See All'),
                        _WeeklyHeatmap(data: homeState.heatmap).animate().fadeIn(delay: 350.ms),

                        const SizedBox(height: 20),

                        // ─── Upcoming Contests ─────────────────────
                        if (homeState.contests.isNotEmpty) ...[
                          _SectionTitle('Upcoming Contests', onAction: () => context.go('/contests'), actionLabel: 'See All'),
                          ...homeState.contests.take(2).map((c) => _ContestCard(contest: c)),
                        ],

                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<Widget> _buildShimmerCards() {
    return List.generate(2, (_) => Container(
      height: 100, margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(AppRadius.lg)),
    ));
  }

  Widget _buildPlatformCard(PlatformStatsModel s) {
    final Map<String, (String, Color)> info = {
      'leetcode': ('🟡', AppColors.leetcode),
      'gfg': ('🟢', AppColors.gfg),
      'codeforces': ('🔵', AppColors.codeforces),
      'codechef': ('🟠', AppColors.codechef),
      'github': ('⬛', AppColors.github),
      'hackerrank': ('🟩', AppColors.success),
    };
    final (emoji, color) = info[s.platform] ?? ('🏆', AppColors.primary);
    final name = s.platform[0].toUpperCase() + s.platform.substring(1);

    return PlatformStatCard(
      platform: name, totalSolved: s.totalSolved,
      easySolved: s.easySolved, mediumSolved: s.mediumSolved, hardSolved: s.hardSolved,
      rating: s.rating, contestCount: s.contestCount,
      platformColor: color, platformEmoji: emoji,
      onTap: s.profileUrl != null ? () => LinkLauncher.open(s.profileUrl!) : null,
    ).animate().fadeIn().slideX(begin: 0.2);
  }
}

// ─── Welcome Card Widget ──────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String greeting, name;
  final int streak, xp, level;
  const _WelcomeCard({required this.greeting, required this.name, required this.streak, required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.glow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greeting, $name! 👋', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text("Today's Goal: Solve 3 Problems", style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
        const SizedBox(height: 16),
        Row(children: [
          StreakBadge(streak: streak),
          const SizedBox(width: 10),
          XpLevelBadge(xp: xp, level: level),
        ]),
      ]),
    );
  }
}

// ─── Section title helper ─────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle(this.title, {this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!, style: const TextStyle(color: AppColors.primary, fontSize: 12))),
      ]),
    );
  }
}

// ─── Empty Platform Card ──────────────────────────────────────────
class _EmptyPlatformCard extends StatelessWidget {
  final VoidCallback onConnect;
  const _EmptyPlatformCard({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.darkBorder)),
      child: Column(children: [
        const Text('📊', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        const Text('No platform stats yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Connect your coding profiles to see your stats', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OwlButton(label: 'Connect Platforms', onTap: onConnect, width: 200),
      ]),
    );
  }
}

// ─── POTD Widget ──────────────────────────────────────────────────
class _PotdWidget extends StatelessWidget {
  final Map<String, PotdModel?> potd;
  const _PotdWidget({required this.potd});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (potd['leetcode'] != null) _PotdCard(potd: potd['leetcode']!),
      if (potd['gfg'] != null) _PotdCard(potd: potd['gfg']!),
      if (potd.isEmpty) Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.darkBorder)),
        child: const Text('Loading POTD...', style: TextStyle(color: AppColors.darkTextSecondary)),
      ),
    ]);
  }
}

class _PotdCard extends StatelessWidget {
  final PotdModel potd;
  const _PotdCard({required this.potd});

  @override
  Widget build(BuildContext context) {
    final platformEmoji = potd.platform == 'leetcode' ? '🟡' : '🟢';
    final platformName = potd.platform == 'leetcode' ? 'LeetCode' : 'GeeksForGeeks';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(children: [
        Text('📌 $platformEmoji', style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(platformName, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(potd.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        DifficultyChip(potd.difficulty),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => LinkLauncher.open(potd.link),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), foregroundColor: AppColors.accent,
            backgroundColor: AppColors.accent.withValues(alpha: 0.1), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Solve →', style: TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }
}

// ─── Coding Sheets Progress ───────────────────────────────────────
class _SheetsProgress extends StatelessWidget {
  const _SheetsProgress();

  // Static mock data — replace with API later
  static const _sheets = [
    ('Striver A2Z', 0.45, 120, 455, AppColors.primary),
    ('NeetCode 150', 0.40, 60, 150, AppColors.secondary),
    ('Love Babbar 450', 0.22, 100, 450, AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.darkBorder)),
      child: Column(children: _sheets.map((s) {
        final (name, progress, done, total, color) = s;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13))),
              Text('$done/$total', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.round),
              child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: color.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation(color)),
            ),
          ]),
        );
      }).toList()),
    );
  }
}

// ─── Weekly Heatmap ───────────────────────────────────────────────
class _WeeklyHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _WeeklyHeatmap({required this.data});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final week = List.generate(7, (i) {
      final d = today.subtract(Duration(days: today.weekday - 1 - i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      final entry = data.firstWhere((e) => e['_id'] == key, orElse: () => {'count': 0});
      return (days[i], (entry['count'] ?? 0) as int);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.darkBorder)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: week.map((entry) {
          final (day, count) = entry;
          final opacity = count == 0 ? 0.08 : count < 3 ? 0.4 : count < 5 ? 0.7 : 1.0;
          return Column(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(6),
              ),
              child: count > 0 ? Center(child: Text('$count', style: TextStyle(color: Colors.white.withValues(alpha: opacity < 0.4 ? 0 : 1), fontSize: 10, fontWeight: FontWeight.w600))) : null,
            ),
            const SizedBox(height: 4),
             Text(day, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10)),
          ]);
        }).toList(),
      ),
    );
  }
}

// ─── Contest Card ─────────────────────────────────────────────────
class _ContestCard extends StatelessWidget {
  final ContestModel contest;
  const _ContestCard({required this.contest});

  @override
  Widget build(BuildContext context) {
    final diff = contest.timeUntilStart;
    final timeStr = diff.inDays > 0
        ? '${diff.inDays}d ${diff.inHours.remainder(24)}h ${diff.inMinutes.remainder(60)}m'
        : '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';

    final platformColor = contest.platform == 'Codeforces' ? AppColors.codeforces : AppColors.leetcode;
    final platformEmoji = contest.platform == 'Codeforces' ? '🔵' : '🟡';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: platformColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Text('🏁 $platformEmoji', style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contest.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('⏰ Starts in: $timeStr', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
        ])),
        TextButton(
          onPressed: () => LinkLauncher.open(contest.registerUrl),
          style: TextButton.styleFrom(
            foregroundColor: platformColor, backgroundColor: platformColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Register', style: TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }
}

// ─── Due Revision Widget ──────────────────────────────────────────
class _DueRevisionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RevisionBloc>()..add(LoadDueRevisions()),
      child: BlocBuilder<RevisionBloc, RevisionState>(
        builder: (context, state) {
          if (state.status == RevisionStatus.loading) {
            return Container(
              height: 70,
              decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            );
          }
          final count = state.dueRevisions.length;
          
          return GestureDetector(
            onTap: () => context.go('/revision'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: count > 0 ? AppColors.dangerGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadow.glow,
              ),
              child: Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count > 0 ? '$count problems due for review' : 'All caught up!',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          count > 0 ? 'Review now to beat the forgetting curve' : 'Check back tomorrow',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
