import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/contests_bloc.dart';
import '../../../shared/services/link_launcher.dart';
import '../../../core/di/service_locator.dart';

class ContestsScreen extends StatelessWidget {
  const ContestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ContestsBloc>()..add(FetchContests()),
      child: const _ContestsView(),
    );
  }
}

class _ContestsView extends StatelessWidget {
  const _ContestsView();

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    } else if (hours > 0) {
      return '$hours hr';
    }
    return '$minutes min';
  }

  String _getTimeUntil(DateTime startTime) {
    final now = DateTime.now();
    final diff = startTime.difference(now);

    if (diff.isNegative) return 'Started';

    if (diff.inDays > 0) {
      return 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'Starts in ${diff.inMinutes}m';
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'leetcode':
        return const Color(0xFFFFA116);
      case 'codeforces':
        return const Color(0xFF3B5998);
      case 'codechef':
        return const Color(0xFF5B4638);
      case 'atcoder':
        return const Color(0xFF1F1F1F);
      default:
        return AppColors.primary;
    }
  }

  String _getPlatformEmoji(String platform) {
    switch (platform.toLowerCase()) {
      case 'leetcode':
        return '👑';
      case 'codeforces':
        return '📊';
      case 'codechef':
        return '🍳';
      case 'atcoder':
        return '🇯🇵';
      default:
        return '🏁';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coding Contests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<ContestsBloc>().add(FetchContests());
            },
            tooltip: 'Refresh Contests',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: BlocBuilder<ContestsBloc, ContestsState>(
              builder: (context, state) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'LeetCode', 'Codeforces'].map((platform) {
                    final isSelected = state.selectedPlatform == platform;
                    return GestureDetector(
                      onTap: () {
                        context.read<ContestsBloc>().add(FilterContests(platform));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getPlatformColor(platform == 'All' ? 'default' : platform)
                              : (isDark ? AppColors.darkCard : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(AppRadius.round),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            platform,
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Content Panel
          Expanded(
            child: BlocBuilder<ContestsBloc, ContestsState>(
              builder: (context, state) {
                if (state.status == ContestsStatus.initial || state.status == ContestsStatus.loading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (state.status == ContestsStatus.error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔌', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to fetch contests',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error ?? 'Unknown error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ContestsBloc>().add(FetchContests());
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredContests = state.filteredContests;

                if (filteredContests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        Text(
                          'No contests found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try changing the filters or refresh',
                          style: TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredContests.length,
                  itemBuilder: (context, index) {
                    final contest = filteredContests[index];
                    final name = contest.name;
                    final platform = contest.platform;
                    final startTime = contest.startTime;
                    final duration = contest.durationSeconds;
                    final registerUrl = contest.registerUrl;
                    final type = contest.type;

                    final platformColor = _getPlatformColor(platform);
                    final formattedTime = DateFormat('EEE, MMM d, yyyy  •  hh:mm a').format(startTime.toLocal());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: platformColor.withValues(alpha: 0.25)),
                        boxShadow: AppShadow.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: platformColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.round),
                                  border: Border.all(color: platformColor.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Text(_getPlatformEmoji(platform), style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      platform,
                                      style: TextStyle(color: platformColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.round),
                                ),
                                child: Text(
                                  _getTimeUntil(startTime),
                                  style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.darkTextSecondary),
                              const SizedBox(width: 6),
                              Text(formattedTime, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppColors.darkTextSecondary),
                              const SizedBox(width: 6),
                              Text('Duration: ${_formatDuration(duration)}', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                              if (type != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.style_outlined, size: 14, color: AppColors.darkTextSecondary),
                                const SizedBox(width: 6),
                                Text('Type: $type', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                                  label: const Text('Register & Compete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: platformColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                  ),
                                  onPressed: () => LinkLauncher.open(registerUrl),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, delay: (index * 40).ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

