import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/analytics_bloc.dart';
import '../../../core/di/service_locator.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AnalyticsBloc>()..add(FetchAnalyticsData()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                context.read<AnalyticsBloc>().add(FetchAnalyticsData());
              },
              tooltip: 'Refresh stats',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'AI Reports'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
          ),
        ),
        body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsInitial || state is AnalyticsLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is AnalyticsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load analytics',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AnalyticsBloc>().add(FetchAnalyticsData());
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is AnalyticsLoaded || state is AnalyticsGeneratingReport) {
              final overview = (state is AnalyticsLoaded) ? state.overview : (context.read<AnalyticsBloc>().state as AnalyticsLoaded).overview;
              final reports = (state is AnalyticsLoaded) ? state.reports : (context.read<AnalyticsBloc>().state as AnalyticsLoaded).reports;

              return TabBarView(
                children: [
                  // Tab 1: Overview
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReadinessCard(overview),
                        const SizedBox(height: 20),
                        _buildQuickStatsGrid(overview),
                        const SizedBox(height: 24),
                        _buildDifficultyBreakdownCard(overview, isDark),
                        const SizedBox(height: 24),
                        _buildTopTopicsCard(overview, isDark),
                        const SizedBox(height: 24),
                        _buildPlatformShareCard(overview, isDark),
                      ],
                    ),
                  ),
                  // Tab 2: AI Reports
                  _buildAiReportsTab(context, reports, state is AnalyticsGeneratingReport),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAiReportsTab(BuildContext context, List<Map<String, dynamic>> reports, bool isGenerating) {
    return Stack(
      children: [
        if (reports.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📝', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                const Text('No reports yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Generate your first weekly progress report!', style: TextStyle(color: AppColors.darkTextSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isGenerating ? null : () => context.read<AnalyticsBloc>().add(GenerateWeeklyReport()),
                  child: const Text('Generate Report'),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Week of ${r['weekStartDate'].toString().split('T')[0]}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.round),
                          ),
                          child: Text(
                            'Score: ${r['interviewReadinessScore'] ?? 0}',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(r['summary'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 16),
                    const Text('Strong Topics', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text((r['strongTopics'] as List).join(', '), style: const TextStyle(color: AppColors.success, fontSize: 12)),
                    const SizedBox(height: 12),
                    const Text('Weak Topics', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text((r['weakTopics'] as List).join(', '), style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    const SizedBox(height: 16),
                    const Text('Next Actions', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...(r['recommendedNextActions'] as List).map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.primary)),
                          Expanded(child: Text(a.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        
        if (isGenerating)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('🦉 AI is analyzing your progress...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReadinessCard(Map<String, dynamic> overview) {
    final readiness = overview['interviewReadiness'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: AppShadow.glow,
      ),
      child: Row(
        children: [
          // Ring Chart
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: readiness / 100.0,
                  strokeWidth: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              Text(
                '$readiness%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ).animate().scale(duration: 400.ms),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Placement Readiness',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  readiness >= 75
                      ? 'Excellent progress! You are placement-ready. Focus on hard/revision problems.'
                      : readiness >= 50
                          ? 'Looking good! Complete more medium problems to build confidence.'
                          : 'Early days! Solve easy and topic-wise medium problems regularly.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(Map<String, dynamic> overview) {
    final total = overview['totalSolved'] ?? 0;
    final streak = overview['streak'] ?? 0;
    final xp = overview['xp'] ?? 0;
    final avgTime = overview['avgTime'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Solved', '$total', '📚', AppColors.primary),
        _buildStatCard('Active Streak', '$streak days', '🔥', AppColors.danger),
        _buildStatCard('Total XP', '$xp XP', '⭐', AppColors.warning),
        _buildStatCard('Avg. Time', '${avgTime}m', '⏱️', AppColors.accent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildDifficultyBreakdownCard(Map<String, dynamic> overview, bool isDark) {
    final easy = overview['easySolved'] ?? 0;
    final medium = overview['mediumSolved'] ?? 0;
    final hard = overview['hardSolved'] ?? 0;
    final total = easy + medium + hard;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Difficulty Breakdown',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDiffBar('Easy', easy, total, AppColors.easy),
          const SizedBox(height: 12),
          _buildDiffBar('Medium', medium, total, AppColors.medium),
          const SizedBox(height: 12),
          _buildDiffBar('Hard', hard, total, AppColors.hard),
        ],
      ),
    );
  }

  Widget _buildDiffBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('$count solved (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.round),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTopicsCard(Map<String, dynamic> overview, bool isDark) {
    final topTopics = overview['topTopics'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Strongest DSA Areas',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (topTopics.isEmpty)
            const Text(
              'Solve problems in the tracker to see your topic strengths.',
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
            )
          else
            ...topTopics.map((topic) {
              final name = topic['topic'] ?? '';
              final solved = topic['totalSolved'] ?? 0;
              final target = topic['target'] ?? 30;
              final progress = target > 0 ? (solved / target).clamp(0.0, 1.0) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text('$solved/$target Solved', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.round),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPlatformShareCard(Map<String, dynamic> overview, bool isDark) {
    final stats = overview['platformStats'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Stats & Profiles',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (stats.isEmpty)
            const Text(
              'No platform accounts synced yet.',
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
            )
          else
            ...stats.map((stat) {
              final platform = stat['platform'] ?? '';
              final solved = stat['totalSolved'] ?? 0;
              final rating = stat['rating'] ?? 0;
              final contests = stat['contestCount'] ?? 0;

              Color color = AppColors.primary;
              if (platform.toLowerCase() == 'leetcode') color = const Color(0xFFFFA116);
              if (platform.toLowerCase() == 'codeforces') color = const Color(0xFF1F8ACB);
              if (platform.toLowerCase() == 'gfg') color = const Color(0xFF2F8D46);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        platform,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$solved Solved', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        if (rating > 0 || contests > 0)
                          Text(
                            '${rating > 0 ? "⭐ $rating" : ""} ${contests > 0 ? "• $contests Contests" : ""}',
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
