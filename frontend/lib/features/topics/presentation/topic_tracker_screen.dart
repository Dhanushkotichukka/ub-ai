import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/topic_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/link_launcher.dart';
import '../../../shared/widgets/owl_button.dart';

class TopicTrackerScreen extends StatefulWidget {
  const TopicTrackerScreen({super.key});
  @override State<TopicTrackerScreen> createState() => _TopicTrackerScreenState();
}

class _TopicTrackerScreenState extends State<TopicTrackerScreen> {
  String? _expandedTopic;

  @override
  void initState() {
    super.initState();
    context.read<TopicBloc>().add(TopicLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TopicBloc>().add(TopicRecalculateRequested()),
            tooltip: 'Recalculate from logs',
          ),
        ],
      ),
      body: BlocBuilder<TopicBloc, TopicState>(
        builder: (context, state) {
          if (state.status == TopicStatus.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (state.topics.isEmpty) return _EmptyTopics();

          return RefreshIndicator(
            onRefresh: () async => context.read<TopicBloc>().add(TopicLoadRequested()),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.topics.length,
              itemBuilder: (_, i) => _TopicRow(
                topic: state.topics[i],
                index: i + 1,
                isExpanded: _expandedTopic == state.topics[i].topic,
                onExpand: () => setState(() => _expandedTopic = _expandedTopic == state.topics[i].topic ? null : state.topics[i].topic),
              ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.2),
            ),
          );
        },
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final TopicModel topic;
  final int index;
  final bool isExpanded;
  final VoidCallback onExpand;
  const _TopicRow({required this.topic, required this.index, required this.isExpanded, required this.onExpand});

  Color get _masteryColor {
    if (topic.mastery == 0) return AppColors.darkTextSecondary;
    if (topic.mastery <= 2) return AppColors.easy;
    if (topic.mastery <= 3) return AppColors.medium;
    return AppColors.primary;
  }

  String get _masteryLabel {
    const labels = ['Not Started', 'Beginner', 'Basic', 'Intermediate', 'Advanced', 'Master'];
    return labels[topic.mastery.clamp(0, 5)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onExpand,
      child: AnimatedContainer(
        duration: 250.ms,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isExpanded ? AppColors.primary.withValues(alpha: 0.4) : (isDark ? AppColors.darkBorder : Colors.grey.shade200)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('$index', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)))),
            const SizedBox(width: 10),
            Expanded(child: Text(topic.topic, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _masteryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.round)),
              child: Text(_masteryLabel, style: TextStyle(color: _masteryColor, fontSize: 10, fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.darkTextSecondary, size: 20),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _DiffBadge('E', topic.easySolved, AppColors.easy),
            const SizedBox(width: 6),
            _DiffBadge('M', topic.mediumSolved, AppColors.medium),
            const SizedBox(width: 6),
            _DiffBadge('H', topic.hardSolved, AppColors.hard),
            const Spacer(),
            Text('${topic.totalSolved}/${topic.target}', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.round),
            child: LinearProgressIndicator(value: topic.progress, minHeight: 4,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12), valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
          ),

          if (isExpanded) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text('Recommended Problems', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _RecommendedProblems(topic: topic.topic),
          ],
        ]),
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _DiffBadge(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.round)),
    child: Text('$label:$count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// Static recommended problems (AI integration later)
class _RecommendedProblems extends StatelessWidget {
  final String topic;
  const _RecommendedProblems({required this.topic});

  static const _problems = {
    'Arrays': [('Two Sum', 'easy', 'https://leetcode.com/problems/two-sum/'), ('3Sum', 'medium', 'https://leetcode.com/problems/3sum/'), ('Trapping Rain Water', 'hard', 'https://leetcode.com/problems/trapping-rain-water/')],
    'Dynamic Programming': [('Climbing Stairs', 'easy', 'https://leetcode.com/problems/climbing-stairs/'), ('Coin Change', 'medium', 'https://leetcode.com/problems/coin-change/'), ('Edit Distance', 'hard', 'https://leetcode.com/problems/edit-distance/')],
    'Graphs': [('Number of Islands', 'medium', 'https://leetcode.com/problems/number-of-islands/'), ('Course Schedule', 'medium', 'https://leetcode.com/problems/course-schedule/'), ('Word Ladder', 'hard', 'https://leetcode.com/problems/word-ladder/')],
  };

  @override
  Widget build(BuildContext context) {
    final problems = _problems[topic] ?? [('Practice $topic problems', 'medium', 'https://leetcode.com/')];
    return Column(children: problems.map((p) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        DifficultyChip(p.$2),
        const SizedBox(width: 8),
        Expanded(child: Text(p.$1, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        TextButton(onPressed: () => LinkLauncher.open(p.$3),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), foregroundColor: AppColors.accent, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Practice →', style: TextStyle(fontSize: 11))),
      ]),
    )).toList());
  }
}

class _EmptyTopics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📋', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 16),
      Text('No topics tracked yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
      const SizedBox(height: 8),
      const Text('Add problems in the Daily Tracker to start tracking topics automatically', textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkTextSecondary)),
    ]));
  }
}
