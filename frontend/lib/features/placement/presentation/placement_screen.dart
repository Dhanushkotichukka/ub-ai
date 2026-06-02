import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/placement_bloc.dart';
import '../../../shared/services/link_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../../shared/widgets/owl_button.dart';
import '../../plan/data/plan_repository.dart';

class PlacementScreen extends StatelessWidget {
  const PlacementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PlacementBloc>()..add(LoadCompanies()),
      child: const _PlacementView(),
    );
  }
}

class _PlacementView extends StatefulWidget {
  const _PlacementView();

  @override
  State<_PlacementView> createState() => _PlacementViewState();
}

class _PlacementViewState extends State<_PlacementView> {
  final _resumeTextController = TextEditingController();

  @override
  void dispose() {
    _resumeTextController.dispose();
    super.dispose();
  }

  Future<void> _addQuestionToPlan(Map<String, dynamic> q) async {
    try {
      final selectedCompany = context.read<PlacementBloc>().state.selectedCompany ?? "Placement";
      final task = {
        'id': q['id'] ?? UniqueKey().toString(),
        'text': 'Solve ${q['name']} for $selectedCompany',
        'type': 'problem',
        'platform': q['platform'] ?? 'LeetCode',
        'link': q['link'] ?? '',
        'priority': q['difficulty'] == 'hard' ? 'high' : 'medium',
        'estimatedMinutes': q['difficulty'] == 'hard' ? 45 : 30,
      };

      await sl<PlanRepository>().addTask(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to today\'s todo list! 📝'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _runAtsAnalyzer() {
    if (_resumeTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste some resume details'), backgroundColor: AppColors.warning),
      );
      return;
    }
    context.read<PlacementBloc>().add(AnalyzeResume(_resumeTextController.text));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Placement Prep Hub'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Company DSA Sheets'),
              Tab(text: 'Resume ATS Scorecard'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        body: BlocListener<PlacementBloc, PlacementState>(
          listenWhen: (previous, current) => previous.atsError != current.atsError && current.atsError != null,
          listener: (context, state) {
            if (state.atsError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ATS Analyzer error: ${state.atsError}'), backgroundColor: AppColors.danger),
              );
            }
          },
          child: TabBarView(
            children: [
              // Company Sheets view
              _buildCompanySheetsView(isDark),
              // Resume ATS view
              _buildResumeAtsView(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanySheetsView(bool isDark) {
    return BlocBuilder<PlacementBloc, PlacementState>(
      builder: (context, state) {
        if (state.status == PlacementStatus.initial || state.status == PlacementStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state.status == PlacementStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔌', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                const Text('Could not fetch companies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<PlacementBloc>().add(LoadCompanies());
                  },
                  child: const Text('Reload'),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            // Side Company Bar
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200)),
                ),
                child: ListView.builder(
                  itemCount: state.companies.length,
                  itemBuilder: (context, index) {
                    final c = state.companies[index];
                    final name = c['name'] ?? '';
                    final logo = c['logo'] ?? '🏢';
                    final count = c['count'] ?? 0;
                    final isSelected = state.selectedCompany == name;

                    return ListTile(
                      leading: Text(logo, style: const TextStyle(fontSize: 16)),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text('$count questions', style: const TextStyle(fontSize: 10, color: AppColors.darkTextSecondary)),
                      onTap: () {
                        context.read<PlacementBloc>().add(SelectCompany(name));
                      },
                    );
                  },
                ),
              ),
            ),

            // Questions List
            Expanded(
              flex: 2,
              child: state.selectedCompany == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🏢', style: TextStyle(fontSize: 50)),
                          SizedBox(height: 12),
                          Text('Select a company to view their interview questions', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                        ],
                      ),
                    )
                  : state.companyLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                '${state.selectedCompany} Questions',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: state.companyQuestions.length,
                                itemBuilder: (context, index) {
                                  final q = state.companyQuestions[index];
                                  final name = q['name'] ?? '';
                                  final diff = q['difficulty'] ?? 'medium';
                                  final topic = q['topic'] ?? '';
                                  final link = q['link'] ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkCard,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(color: AppColors.darkBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  DifficultyChip(diff),
                                                  const SizedBox(width: 8),
                                                  Text(topic, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_task_rounded, color: AppColors.success, size: 18),
                                          onPressed: () => _addQuestionToPlan(q),
                                          tooltip: 'Add to plan',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 18),
                                          onPressed: () => LinkLauncher.open(link),
                                          tooltip: 'Solve on platform',
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn().slideY(begin: 0.1, delay: (index * 20).ms);
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumeAtsView(bool isDark) {
    return BlocBuilder<PlacementBloc, PlacementState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resume ATS Analyzer (Mock / AI)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste your resume text details (skills, experiences, education, projects) to score its ATS compatibility.',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _resumeTextController,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste resume content here...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OwlButton(
                  label: 'Analyze Resume Score',
                  loading: state.atsLoading,
                  onTap: _runAtsAnalyzer,
                ),
              ),
              if (state.atsResult != null) ...[
                const SizedBox(height: 24),
                _buildAtsResultCard(state.atsResult!, isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAtsResultCard(Map<String, dynamic> atsResult, bool isDark) {
    final score = atsResult['score'] ?? 0;
    final strengths = List<String>.from(atsResult['strengths'] ?? []);
    final missing = List<String>.from(atsResult['missingKeywords'] ?? []);
    final tips = List<String>.from(atsResult['formatTips'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ATS Compatibility Score', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: score >= 75 ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.round),
                ),
                child: Text(
                  '$score / 100',
                  style: TextStyle(color: score >= 75 ? AppColors.success : AppColors.warning, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Strengths
          const Text('✅ Strengths', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...strengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.success)),
                    Expanded(child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                  ],
                ),
              )),
          const SizedBox(height: 16),

          // Missing Keywords
          const Text('🚨 Missing Keywords & DSA Concepts', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (missing.isEmpty)
            const Text('None! Excellent keyword optimization.', style: TextStyle(color: AppColors.success, fontSize: 11))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missing.map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.round),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(m, style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w600)),
                  )).toList(),
            ),
          const SizedBox(height: 16),

          // Formatting & ATS Tips
          const Text('💡 Structuring & ATS Formatting Tips', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.accent)),
                    Expanded(child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    ).animate().fadeIn().scale(duration: 350.ms);
  }
}
