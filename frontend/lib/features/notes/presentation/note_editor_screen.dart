import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/notes_bloc.dart';
import '../data/notes_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/di/service_locator.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _folderController = TextEditingController();

  String _color = 'default';
  bool _isPinned = false;
  bool _loading = false;
  bool _saving = false;

  // AI assistant states
  bool _aiLoading = false;
  String _aiResponse = '';
  String _aiAction = ''; // summarize, flashcards, explain, complexity, fix

  final List<String> _colors = ['default', 'red', 'blue', 'green', 'purple', 'orange', 'yellow'];

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadNote();
    } else {
      _folderController.text = 'All Notes';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() => _loading = true);
    try {
      final note = await sl<NotesRepository>().getNote(widget.noteId!);
      setState(() {
        _titleController.text = note['title'] ?? '';
        _contentController.text = note['contentText'] ?? '';
        _folderController.text = note['folderPath'] ?? 'All Notes';
        _color = note['color'] ?? 'default';
        _isPinned = note['isPinned'] ?? false;
        final tagsList = List<String>.from(note['tags'] ?? []);
        _tagsController.text = tagsList.join(', ');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading note: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note title'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _saving = true);
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Map content to Quill Delta format
    final contentDelta = {
      'ops': [
        {'insert': _contentController.text}
      ]
    };

    final data = {
      'title': _titleController.text.trim(),
      'content': contentDelta,
      'folder': _folderController.text.trim(),
      'folderPath': _folderController.text.trim(),
      'tags': tags,
      'color': _color,
      'isPinned': _isPinned,
    };

    try {
      if (widget.noteId != null) {
        await sl<NotesRepository>().updateNote(widget.noteId!, data);
      } else {
        await sl<NotesRepository>().createNote(data);
      }
      if (mounted) {
        context.read<NotesBloc>().add(const NotesLoadRequested());
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _runAiAssistant(String action) async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write some content first'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() {
      _aiLoading = true;
      _aiAction = action;
      _aiResponse = '';
    });

    try {
      final res = await sl<ApiService>().post('/ai/notes-assistant', data: {
        'action': action,
        'content': _contentController.text,
      });

      setState(() {
        final result = res.data['result'];
        if (result is List) {
          _aiResponse = result.map((item) {
            if (item is Map && item.containsKey('question')) {
              return 'Q: ${item['question']}\nA: ${item['answer']}';
            }
            return item.toString();
          }).join('\n\n');
        } else {
          _aiResponse = result.toString();
        }
      });
    } catch (e) {
      setState(() {
        _aiResponse = 'Error: $e';
      });
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  Color _getColorHex(String name) {
    switch (name) {
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
        return AppColors.darkCard;
    }
  }

  void _insertText(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.isValid) {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length + suffix.length),
      );
    } else {
      final offset = _contentController.text.length;
      _contentController.value = TextEditingValue(
        text: '$text$prefix$suffix',
        selection: TextSelection.collapsed(offset: offset + prefix.length + suffix.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? 'Edit Note' : 'Create Note'),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
            color: _isPinned ? AppColors.primary : null,
            onPressed: () => setState(() => _isPinned = !_isPinned),
            tooltip: 'Pin Note',
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded),
            onPressed: _saving ? null : _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: Row(
        children: [
          // Main Editor Panel
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Note Title...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadata Row: Folder & Tags
                  Row(
                    children: [
                      const Icon(Icons.folder_rounded, size: 16, color: AppColors.darkTextSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _folderController,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Folder (e.g. Dynamic Programming)',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 16, color: AppColors.darkTextSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _tagsController,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Tags (comma separated: dp, graphs, arrays)',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Colors Row
                  Row(
                    children: [
                      const Text('Color:', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                      const SizedBox(width: 10),
                      ..._colors.map((c) => GestureDetector(
                            onTap: () => setState(() => _color = c),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _getColorHex(c),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _color == c ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.darkBorder),

                  // Formatting Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.format_bold_rounded, size: 18),
                          onPressed: () => _insertText('**', '**'),
                          tooltip: 'Bold',
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_italic_rounded, size: 18),
                          onPressed: () => _insertText('*', '*'),
                          tooltip: 'Italic',
                        ),
                        IconButton(
                          icon: const Icon(Icons.code_rounded, size: 18),
                          onPressed: () => _insertText('`', '`'),
                          tooltip: 'Inline Code',
                        ),
                        IconButton(
                          icon: const Icon(Icons.integration_instructions_outlined, size: 18),
                          onPressed: () => _insertText('\n```cpp\n', '\n```\n'),
                          tooltip: 'Code Block',
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.accent),
                          onPressed: () {
                            // Show AI actions sheet on mobile or small screens
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: AppColors.darkCard,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                              builder: (context) => _buildAiActionsMenu(),
                            );
                          },
                          tooltip: 'AI Actions',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Note Textarea
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 15,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Start writing your DSA notes, code explanations, or templates...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AI Sidebar (for Desktop/Web view, showing split-screen AI panel)
          if (MediaQuery.of(context).size.width > 700)
            Container(
              width: 320,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.darkBorder)),
              ),
              child: _buildAiPanel(),
            ),
        ],
      ),
      // AI assistant sheet button on mobile
      bottomNavigationBar: MediaQuery.of(context).size.width <= 700
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.darkBorder))),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text('AI Assistant Panel', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.darkCard,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      padding: const EdgeInsets.all(16),
                      child: _buildAiPanel(),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildAiActionsMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Notes Assistant', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.summarize_rounded, color: AppColors.primary),
            title: const Text('Summarize Note', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _runAiAssistant('summarize');
            },
          ),
          ListTile(
            leading: const Icon(Icons.style_rounded, color: AppColors.accent),
            title: const Text('Generate Flashcards', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _runAiAssistant('flashcards');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning),
            title: const Text('Explain Concepts Simply', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _runAiAssistant('explain');
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: AppColors.easy),
            title: const Text('Analyze Time & Space Complexity', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _runAiAssistant('complexity');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: AppColors.danger),
            title: const Text('Find & Fix Code Bugs', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _runAiAssistant('fix');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text('AI Mentor Space', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_aiLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 12),
          if (MediaQuery.of(context).size.width > 700) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _aiActionBtn('Summarize', 'summarize'),
                _aiActionBtn('Flashcards', 'flashcards'),
                _aiActionBtn('Explain', 'explain'),
                _aiActionBtn('Complexity', 'complexity'),
                _aiActionBtn('Fix Bugs', 'fix'),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: _aiLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🧙‍♂️', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text('AI is working on ${_aiAction.toUpperCase()}...', style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _aiResponse.isEmpty
                            ? 'Run one of the AI functions above to analyze or summarize your note content.'
                            : _aiResponse,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.87), fontSize: 13, height: 1.4),
                      ),
                    ),
            ),
          ),
          if (_aiResponse.isNotEmpty && !_aiLoading) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _contentController.text += '\n\n### AI Summary / Insights:\n$_aiResponse';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Insert into note', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiActionBtn(String label, String action) {
    final isCurrent = _aiAction == action;
    return GestureDetector(
      onTap: () => _runAiAssistant(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.accent.withValues(alpha: 0.2) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.round),
          border: Border.all(color: isCurrent ? AppColors.accent : AppColors.darkBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.accent : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
