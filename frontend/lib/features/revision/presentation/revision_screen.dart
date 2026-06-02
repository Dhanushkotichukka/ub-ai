import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../bloc/revision_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/link_launcher.dart';
import '../../../shared/widgets/owl_button.dart';
import '../../../core/di/service_locator.dart';

class RevisionScreen extends StatelessWidget {
  const RevisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RevisionBloc>()..add(LoadDueRevisions()),
      child: const _RevisionView(),
    );
  }
}

class _RevisionView extends StatelessWidget {
  const _RevisionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaced Repetition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Ebbinghaus Curve Info',
          ),
        ],
      ),
      body: BlocBuilder<RevisionBloc, RevisionState>(
        builder: (context, state) {
          if (state.status == RevisionStatus.initial || state.status == RevisionStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state.status == RevisionStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔌', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  const Text('Error loading revisions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(state.error ?? '', style: const TextStyle(color: AppColors.darkTextSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<RevisionBloc>().add(LoadDueRevisions()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.dueRevisions.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Due for Review Today (${state.dueRevisions.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.dueRevisions.length,
                  itemBuilder: (context, index) {
                    final revision = state.dueRevisions[index];
                    return _RevisionCard(revision: revision, index: index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Spaced Repetition', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Problems are scheduled for review using the Ebbinghaus Forgetting Curve intervals:\n\n'
          '• Day 1\n• Day 3\n• Day 7\n• Day 14\n• Day 30\n• Day 60\n• Day 90\n\n'
          'Rate your confidence after solving to adjust the schedule!',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _RevisionCard extends StatefulWidget {
  final Map<String, dynamic> revision;
  final int index;

  const _RevisionCard({required this.revision, required this.index});

  @override
  State<_RevisionCard> createState() => _RevisionCardState();
}

class _RevisionCardState extends State<_RevisionCard> {
  int _selectedConfidence = 0;

  @override
  Widget build(BuildContext context) {
    final r = widget.revision;
    final name = r['problemName'] ?? 'Unknown Problem';
    final topic = r['topic'] ?? 'General';
    final platform = r['platform'] ?? '';
    final link = r['link'] ?? '';
    final revisionCount = r['revisionCount'] ?? 0;
    
    // Last revised
    String lastRevisedStr = 'Never';
    if (r['lastRevised'] != null) {
      final date = DateTime.parse(r['lastRevised']);
      lastRevisedStr = DateFormat('MMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.round),
                          ),
                          child: Text(topic, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        if (platform.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(platform, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (link.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 20),
                  onPressed: () => LinkLauncher.open(link),
                  tooltip: 'Solve Problem',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Revised', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(lastRevisedStr, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Revision #', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('${revisionCount + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.darkBorder),
          const Text('How confident were you solving this?', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final val = i + 1;
              final isSelected = _selectedConfidence == val;
              return GestureDetector(
                onTap: () => setState(() => _selectedConfidence = val),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.warning : AppColors.darkSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.warning : AppColors.darkBorder,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$val',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OwlButton(
              label: 'Mark Revised',
              onTap: _selectedConfidence > 0
                  ? () {
                      context.read<RevisionBloc>().add(MarkRevisionComplete(r['_id'], _selectedConfidence));
                    }
                  : null,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, delay: (widget.index * 30).ms);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🧠', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text('All caught up!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('You have no pending revisions for today.', style: TextStyle(color: AppColors.darkTextSecondary)),
          SizedBox(height: 24),
          Text('Use the Daily Tracker to log new problems\nand they will appear here when due.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkTextSecondary, height: 1.5)),
        ],
      ).animate().fadeIn().scale(),
    );
  }
}
