import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/notes_bloc.dart';
import '../../../core/theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _selectedFolder;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(NotesLoadRequested(folder: _selectedFolder, search: _searchQuery));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFolderSelected(String? folder) {
    setState(() {
      _selectedFolder = folder;
    });
    context.read<NotesBloc>().add(NotesLoadRequested(folder: _selectedFolder, search: _searchQuery));
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<NotesBloc>().add(NotesLoadRequested(folder: _selectedFolder, search: _searchQuery));
  }

  Color _getNoteColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.redAccent.withValues(alpha: 0.2);
      case 'blue':
        return Colors.blueAccent.withValues(alpha: 0.2);
      case 'green':
        return Colors.greenAccent.withValues(alpha: 0.2);
      case 'purple':
        return Colors.purpleAccent.withValues(alpha: 0.2);
      case 'orange':
        return Colors.orangeAccent.withValues(alpha: 0.2);
      case 'yellow':
        return Colors.yellowAccent.withValues(alpha: 0.2);
      default:
        return AppColors.darkCard;
    }
  }

  Color _getNoteBorderColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.redAccent;
      case 'blue':
        return Colors.blueAccent;
      case 'green':
        return Colors.greenAccent;
      case 'purple':
        return Colors.purpleAccent;
      case 'orange':
        return Colors.orangeAccent;
      case 'yellow':
        return Colors.yellowAccent;
      default:
        return AppColors.darkBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Space'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => context.read<NotesBloc>().add(NotesLoadRequested(folder: _selectedFolder, search: _searchQuery)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search notes and code snippets...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkTextSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.darkTextSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),

          // Folder selector horizontal list
          BlocBuilder<NotesBloc, NotesState>(
            builder: (context, state) {
              final folders = state.folders;
              return Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: folders.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final folderName = isAll ? 'All Notes' : (folders[index - 1]['_id'] ?? 'General');
                    final isSelected = isAll ? _selectedFolder == null : _selectedFolder == folderName;
                    final count = isAll
                        ? state.notes.length
                        : (folders[index - 1]['count'] ?? 0);

                    return GestureDetector(
                      onTap: () => _onFolderSelected(isAll ? null : folderName),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkCard : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(AppRadius.round),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAll ? Icons.folder_copy_rounded : Icons.folder_rounded,
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              folderName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : (isDark ? Colors.white10 : Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Notes List / Grid
          Expanded(
            child: BlocBuilder<NotesBloc, NotesState>(
              builder: (context, state) {
                if (state.status == NotesStatus.loading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (state.notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        Text(
                          'No notes found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to create your first note or code snippet',
                          style: TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: state.notes.length,
                  itemBuilder: (context, index) {
                    final note = state.notes[index];
                    final noteId = note['_id'] ?? '';
                    final title = note['title'] ?? 'Untitled';
                    final colorName = note['color'] ?? 'default';
                    final tags = List<String>.from(note['tags'] ?? []);
                    final textSnippet = note['contentText'] ?? '';
                    final isPinned = note['isPinned'] ?? false;
                    final hasCode = note['hasCode'] ?? false;
                    final folder = note['folderPath'] ?? 'All Notes';

                    return GestureDetector(
                      onTap: () => context.push('/notes/editor?id=$noteId'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getNoteColor(colorName),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _getNoteBorderColor(colorName),
                            width: isPinned ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isPinned)
                                  const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
                                if (isPinned) const SizedBox(width: 4),
                                if (hasCode)
                                  const Icon(Icons.code_rounded, size: 14, color: AppColors.accent),
                                if (hasCode) const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Note'),
                                        content: const Text('Are you sure you want to delete this note?'),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () => Navigator.pop(ctx),
                                          ),
                                          TextButton(
                                            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                                            onPressed: () {
                                              context.read<NotesBloc>().add(NotesDeleteRequested(noteId));
                                              Navigator.pop(ctx);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              folder,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                textSnippet,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 18,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: tags.length,
                                  itemBuilder: (context, i) => Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.round),
                                    ),
                                    child: Text(
                                      '#${tags[i]}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn().scale(delay: (index * 30).ms),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/notes/editor'),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
