import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/notes_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../data/notes_repository.dart';

// ─── Note Type Config ─────────────────────────────────────────────
class NoteTypeConfig {
  final String key, label, emoji;
  final Color color;
  const NoteTypeConfig(this.key, this.label, this.emoji, this.color);
}

const kNoteTypes = [
  NoteTypeConfig('quick', 'Quick', '⚡', Color(0xFF6C63FF)),
  NoteTypeConfig('dsa', 'DSA', '🧠', Color(0xFF00C49A)),
  NoteTypeConfig('daily', 'Journal', '📅', Color(0xFF4FC3F7)),
  NoteTypeConfig('snippet', 'Snippet', '💻', Color(0xFFFF7043)),
  NoteTypeConfig('meeting', 'Meeting', '📋', Color(0xFFFFB300)),
  NoteTypeConfig('study', 'Study', '📚', Color(0xFFAB47BC)),
];

const kCollections = ['General', 'DSA', 'Flutter', 'Linux', 'ServiceNow', 'Azure', 'Interview Prep', 'Personal Journal'];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedFolder;
  String? _selectedType;
  String? _selectedCollection;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  bool _isSemanticSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final bloc = context.read<NotesBloc>();
    bloc.add(const NotesLoadRequested());
    bloc.add(const NotesStatsRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    context.read<NotesBloc>().add(NotesLoadRequested(
      folder: _selectedFolder,
      search: _isSemanticSearch ? null : (_searchQuery.isEmpty ? null : _searchQuery),
      type: _selectedType,
      collection: _selectedCollection,
    ));
  }

  void _doSearch(String q) {
    setState(() => _searchQuery = q);
    if (_isSemanticSearch && q.length > 3) {
      context.read<NotesBloc>().add(NotesSemanticSearchRequested(q));
    } else {
      _load();
    }
  }

  Color _noteColor(String c) {
    const m = {
      'red': Color(0x33FF5252), 'blue': Color(0x334FC3F7), 'green': Color(0x3366BB6A),
      'purple': Color(0x33AB47BC), 'orange': Color(0x33FF7043), 'yellow': Color(0x33FFB300),
      'pink': Color(0x33EC407A), 'teal': Color(0x3326A69A),
    };
    return m[c] ?? const Color(0xFF1E1E2E);
  }

  Color _noteBorderColor(String c) {
    const m = {
      'red': Color(0xFFFF5252), 'blue': Color(0xFF4FC3F7), 'green': Color(0xFF66BB6A),
      'purple': Color(0xFFAB47BC), 'orange': Color(0xFFFF7043), 'yellow': Color(0xFFFFB300),
      'pink': Color(0xFFEC407A), 'teal': Color(0xFF26A69A),
    };
    return m[c] ?? AppColors.darkBorder;
  }

  NoteTypeConfig _typeConfig(String t) =>
      kNoteTypes.firstWhere((e) => e.key == t, orElse: () => kNoteTypes.first);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTypeFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesList(),
                _buildRevisionView(),
                _buildDashboardStats(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notes Space', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    BlocBuilder<NotesBloc, NotesState>(
                      builder: (_, s) => Text('${s.stats['total'] ?? 0} notes · ${s.stats['thisWeek'] ?? 0} this week',
                          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              // Today's Journal Button
              GestureDetector(
                onTap: _openDailyNote,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF6C63FF)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('📅', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('Today', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white70),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'All Notes'),
              Tab(text: '🔄 Review'),
              Tab(text: '📊 Dashboard'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _doSearch,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isSemanticSearch ? '🔍 Semantic: "my recursion notes"' : 'Search notes...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkTextSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.darkTextSecondary), onPressed: () { _searchController.clear(); _doSearch(''); })
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E2E),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() { _isSemanticSearch = !_isSemanticSearch; if (!_isSemanticSearch) { _searchController.clear(); _doSearch(''); } }),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isSemanticSearch ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isSemanticSearch ? AppColors.primary : AppColors.darkBorder),
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 18, color: _isSemanticSearch ? AppColors.primary : Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip('All', null, null),
          ...kNoteTypes.map((t) => _filterChip('${t.emoji} ${t.label}', t.key, t.color)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? type, Color? color) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () { setState(() => _selectedType = type); _load(); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (color ?? AppColors.primary).withValues(alpha: 0.2) : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? (color ?? AppColors.primary) : AppColors.darkBorder),
        ),
        child: Text(label, style: TextStyle(color: selected ? (color ?? AppColors.primary) : Colors.white60, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildNotesList() {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        if (state.status == NotesStatus.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (state.notes.isEmpty) return _buildEmptyState();
        if (_isGridView) return _buildGrid(state.notes);
        return _buildList(state.notes);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text('No notes yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap + to create a new note', style: TextStyle(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreateMenu,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Note'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) => _buildNoteCard(notes[index], index).animate().fadeIn().scale(delay: (index * 30).ms),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildNoteListTile(notes[index]).animate().fadeIn(delay: (index * 30).ms),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, int index) {
    final noteId = note['_id'] ?? '';
    final title = note['title'] ?? 'Untitled';
    final colorName = note['color'] ?? 'default';
    final tags = List<String>.from(note['tags'] ?? []);
    final textSnippet = note['aiSummary'] ?? note['contentText'] ?? '';
    final isPinned = note['isPinned'] ?? false;
    final isFavorited = note['isFavorited'] ?? false;
    final noteType = note['noteType'] ?? 'quick';
    final typeConf = _typeConfig(noteType);
    final hasFlashcards = (note['flashcards'] as List?)?.isNotEmpty == true;
    final hasQuiz = (note['quiz'] as List?)?.isNotEmpty == true;
    final nextReview = note['nextReviewDate'];

    return GestureDetector(
      onTap: () => context.push('/notes/editor?id=$noteId'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _noteColor(colorName),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _noteBorderColor(colorName), width: isPinned ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(typeConf.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                if (isFavorited) const Text('⭐', style: TextStyle(fontSize: 12)),
                if (isPinned) const Icon(Icons.push_pin_rounded, size: 12, color: AppColors.primary),
                GestureDetector(
                  onTap: () => _deleteNote(noteId),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: typeConf.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: typeConf.color.withValues(alpha: 0.4)),
              ),
              child: Text(typeConf.label, style: TextStyle(color: typeConf.color, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            // Content preview (AI summary preferred)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note['aiSummary'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✨ ', style: TextStyle(fontSize: 10)),
                        Expanded(child: Text(note['aiSummary'], maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4, fontStyle: FontStyle.italic))),
                      ],
                    )
                  else
                    Text(textSnippet, maxLines: 4, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
            // Footer badges
            const SizedBox(height: 6),
            Row(
              children: [
                if (hasFlashcards) _badge('🃏', AppColors.accent),
                if (hasQuiz) _badge('❓', AppColors.warning),
                if (nextReview != null) _badge('🔔', AppColors.primary),
                const Spacer(),
                if (tags.isNotEmpty)
                  Text('#${tags.first}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String emoji, Color color) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
    child: Text(emoji, style: const TextStyle(fontSize: 10)),
  );

  Widget _buildNoteListTile(Map<String, dynamic> note) {
    final noteId = note['_id'] ?? '';
    final title = note['title'] ?? 'Untitled';
    final typeConf = _typeConfig(note['noteType'] ?? 'quick');
    final isPinned = note['isPinned'] ?? false;
    final isFavorited = note['isFavorited'] ?? false;
    final preview = note['aiSummary'] ?? note['contentText'] ?? '';

    return GestureDetector(
      onTap: () => context.push('/notes/editor?id=$noteId'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _noteColor(note['color'] ?? 'default'),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _noteBorderColor(note['color'] ?? 'default')),
        ),
        child: Row(
          children: [
            Text(typeConf.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (isFavorited) const Text('⭐', style: TextStyle(fontSize: 12)),
                      if (isPinned) const Icon(Icons.push_pin_rounded, size: 12, color: AppColors.primary),
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => _deleteNote(noteId), child: const Icon(Icons.close_rounded, size: 16, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionView() {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Notes Due for Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                  TextButton(
                    onPressed: () => context.read<NotesBloc>().add(const NotesRevisionRequested()),
                    child: const Text('Load', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            if (state.revisionNotes.isEmpty)
              const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('✅', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('All caught up!', style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 8),
                Text('No notes due for revision', style: TextStyle(color: AppColors.darkTextSecondary)),
              ])))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.revisionNotes.length,
                  itemBuilder: (ctx, i) {
                    final n = state.revisionNotes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('Due: ${n['nextReviewDate'] ?? ''}', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                        ])),
                        ElevatedButton(
                          onPressed: () => context.push('/notes/editor?id=${n['_id']}'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          child: const Text('Review', style: TextStyle(fontSize: 12)),
                        ),
                      ]),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardStats() {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        final stats = state.stats;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 Notes Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                children: [
                  _statCard('📝', 'Total Notes', '${stats['total'] ?? 0}', const Color(0xFF6C63FF)),
                  _statCard('📅', 'This Week', '${stats['thisWeek'] ?? 0}', const Color(0xFF4FC3F7)),
                  _statCard('🃏', 'Flashcard Sets', '${stats['flashcardsGenerated'] ?? 0}', const Color(0xFF00C49A)),
                  _statCard('❓', 'Quizzes', '${stats['quizzesGenerated'] ?? 0}', const Color(0xFFFFB300)),
                  _statCard('🔔', 'Due Review', '${stats['dueForReview'] ?? 0}', const Color(0xFFFF7043)),
                  _statCard('🤖', 'AI Chats', '${stats['aiChatsUsed'] ?? 0}', const Color(0xFFAB47BC)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('📚 Collections', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: kCollections.map((c) => GestureDetector(
                  onTap: () {
                    setState(() { _selectedCollection = _selectedCollection == c ? null : c; });
                    _load();
                    _tabController.index = 0;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCollection == c ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _selectedCollection == c ? AppColors.primary : AppColors.darkBorder),
                    ),
                    child: Text(c, style: TextStyle(
                      color: _selectedCollection == c ? AppColors.primary : Colors.white70,
                      fontSize: 13, fontWeight: _selectedCollection == c ? FontWeight.w700 : FontWeight.normal,
                    )),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () { context.read<NotesBloc>().add(const NotesStatsRequested()); },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Stats'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 44)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      onPressed: _openCreateMenu,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('New Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  void _openDailyNote() async {
    context.read<NotesBloc>().add(const NotesDailyRequested());
    final note = await sl<NotesRepository>().getDailyNote();
    if (mounted) context.push('/notes/editor?id=${note['_id']}');
  }

  void _deleteNote(String noteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Delete Note', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this note?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text('Cancel', style: TextStyle(color: Colors.white54)), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
            onPressed: () { context.read<NotesBloc>().add(NotesDeleteRequested(noteId)); Navigator.pop(ctx); },
          ),
        ],
      ),
    );
  }

  void _openCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Note', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true, crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: kNoteTypes.map((t) => GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/notes/editor?type=${t.key}');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t.label, style: TextStyle(color: t.color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
