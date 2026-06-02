import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../bloc/tracker_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/owl_button.dart';
import '../../../shared/services/link_launcher.dart';
import '../../../core/constants/hive_keys.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});
  @override State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadForDate(_selectedDate);
  }

  void _loadForDate(DateTime date) {
    context.read<TrackerBloc>().add(TrackerLoadRequested(date: DateFormat('yyyy-MM-dd').format(date)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Daily Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
            onPressed: () => _showAddProblemSheet(context),
            tooltip: 'Add Problem',
          ),
        ],
      ),
      body: BlocBuilder<TrackerBloc, TrackerState>(
        builder: (context, state) {
          return Column(children: [
            // ─── Date Header ─────────────────────────────────
            _DateHeader(
              date: _selectedDate,
              count: state.logs.length,
              onPrev: () { setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))); _loadForDate(_selectedDate); },
              onNext: () { setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))); _loadForDate(_selectedDate); },
            ),

            // ─── Content ──────────────────────────────────────
            Expanded(
              child: state.status == TrackerStatus.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : state.logs.isEmpty
                  ? _EmptyDay(onAdd: () => _showAddProblemSheet(context))
                  : RefreshIndicator(
                      onRefresh: () async => _loadForDate(_selectedDate),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: state.logs.length,
                        itemBuilder: (_, i) => ProblemCard(
                          name: state.logs[i].problemName,
                          topic: state.logs[i].topic,
                          platform: state.logs[i].platform,
                          difficulty: state.logs[i].difficulty,
                          timeTaken: state.logs[i].timeTaken,
                          confidence: state.logs[i].confidence,
                          bookmarked: state.logs[i].isBookmarked,
                          link: state.logs[i].link,
                          onOpenLink: state.logs[i].link.isNotEmpty ? () => LinkLauncher.open(state.logs[i].link) : null,
                          onDelete: () => context.read<TrackerBloc>().add(TrackerDeleteLogRequested(state.logs[i].id)),
                        ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.2),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  void _showAddProblemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TrackerBloc>(),
        child: _AddProblemSheet(date: _selectedDate),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final int count;
  final VoidCallback onPrev, onNext;
  const _DateHeader({required this.date, required this.count, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200)),
      ),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        Expanded(child: Column(children: [
          Text(isToday ? 'Today' : DateFormat('EEE, d MMM yyyy').format(date),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text('$count problem${count != 1 ? 's' : ''} logged', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
        ])),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDay({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📝', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 16),
      Text('No problems logged yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
      const SizedBox(height: 8),
      const Text('Track your progress by adding problems you solve', style: TextStyle(color: AppColors.darkTextSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      OwlButton(label: '+ Add Problem', onTap: onAdd, width: 180),
    ]));
  }
}

// ─── Add Problem Bottom Sheet ─────────────────────────────────────
class _AddProblemSheet extends StatefulWidget {
  final DateTime date;
  const _AddProblemSheet({required this.date});
  @override State<_AddProblemSheet> createState() => _AddProblemSheetState();
}

class _AddProblemSheetState extends State<_AddProblemSheet> {
  final _nameCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _topic = 'Arrays', _platform = 'LeetCode', _difficulty = 'medium';
  int _time = 30, _confidence = 3;
  bool _needsRevision = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Log a Problem', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.lightText)),
        const SizedBox(height: 20),

        TextFormField(controller: _nameCtrl, style: TextStyle(color: isDark ? Colors.white : AppColors.lightText),
          decoration: const InputDecoration(labelText: 'Problem Name *', prefixIcon: Icon(Icons.code, color: AppColors.primary, size: 18))),
        const SizedBox(height: 12),

        // Topic + Difficulty row
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: _topic, onChanged: (v) => setState(() => _topic = v!),
            style: TextStyle(color: isDark ? Colors.white : AppColors.lightText), dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            decoration: const InputDecoration(labelText: 'Topic', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            items: AppConstants.topics.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.lightText)))).toList())),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(initialValue: _difficulty, onChanged: (v) => setState(() => _difficulty = v!),
            style: TextStyle(color: isDark ? Colors.white : AppColors.lightText), dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            decoration: const InputDecoration(labelText: 'Difficulty', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            items: [('easy','🟢 Easy'),('medium','🟡 Medium'),('hard','🔴 Hard')]
              .map((d) => DropdownMenuItem(value: d.$1, child: Text(d.$2, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.lightText)))).toList())),
        ]),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(initialValue: _platform, onChanged: (v) => setState(() => _platform = v!),
          style: TextStyle(color: isDark ? Colors.white : AppColors.lightText), dropdownColor: isDark ? AppColors.darkCard : Colors.white,
          decoration: const InputDecoration(labelText: 'Platform'),
          items: AppConstants.platforms.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: isDark ? Colors.white : AppColors.lightText)))).toList()),
        const SizedBox(height: 12),

        TextFormField(controller: _linkCtrl, style: TextStyle(color: isDark ? Colors.white : AppColors.lightText),
          decoration: const InputDecoration(labelText: 'Problem Link (URL)', prefixIcon: Icon(Icons.link, color: AppColors.primary, size: 18))),
        const SizedBox(height: 12),

        // Time taken
        Row(children: [
          Text('Time: ${_time}m', style: TextStyle(color: isDark ? Colors.white : AppColors.lightText, fontWeight: FontWeight.w500)),
          Expanded(child: Slider(value: _time.toDouble(), min: 5, max: 180, divisions: 35, activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _time = v.toInt()))),
        ]),

        // Confidence
        Row(children: [
          Text('Confidence:', style: TextStyle(color: isDark ? Colors.white : AppColors.lightText, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          ...List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _confidence = i + 1),
            child: Icon(Icons.star, color: i < _confidence ? AppColors.warning : AppColors.darkBorder, size: 24),
          )),
        ]),
        const SizedBox(height: 8),

        Row(children: [
          Switch(value: _needsRevision, onChanged: (v) => setState(() => _needsRevision = v), activeThumbColor: AppColors.primary),
          const SizedBox(width: 8),
          Text('Needs Revision', style: TextStyle(color: isDark ? Colors.white : AppColors.lightText)),
        ]),
        const SizedBox(height: 16),

        OwlButton(
          label: 'Log Problem 🎯',
          onTap: _nameCtrl.text.isNotEmpty ? _submit : null,
        ),
        const SizedBox(height: 4),
      ])),
    );
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    context.read<TrackerBloc>().add(TrackerAddLogRequested({
      'problemName': _nameCtrl.text.trim(),
      'topic': _topic, 'platform': _platform, 'difficulty': _difficulty,
      'timeTaken': _time, 'link': _linkCtrl.text.trim(),
      'notes': _notesCtrl.text, 'confidence': _confidence,
      'needsRevision': _needsRevision,
      'date': DateFormat('yyyy-MM-dd').format(widget.date),
    }));
    Navigator.pop(context);
  }
}
