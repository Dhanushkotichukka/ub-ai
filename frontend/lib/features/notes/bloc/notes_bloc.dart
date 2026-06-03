import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/notes_repository.dart';

// ─── Events ──────────────────────────────────────────────────────
abstract class NotesEvent extends Equatable { const NotesEvent(); @override List<Object?> get props => []; }
class NotesLoadRequested extends NotesEvent {
  final String? folder, search, type, collection;
  final bool? dueReview;
  const NotesLoadRequested({this.folder, this.search, this.type, this.collection, this.dueReview});
  @override List<Object?> get props => [folder, search, type, collection, dueReview];
}
class NotesDailyRequested extends NotesEvent { const NotesDailyRequested(); }
class NotesRevisionRequested extends NotesEvent { const NotesRevisionRequested(); }
class NotesStatsRequested extends NotesEvent { const NotesStatsRequested(); }
class NotesCreateRequested extends NotesEvent { final Map<String, dynamic> data; const NotesCreateRequested(this.data); @override List<Object?> get props => [data]; }
class NotesDeleteRequested extends NotesEvent { final String id; const NotesDeleteRequested(this.id); @override List<Object?> get props => [id]; }

// AI Events
class NotesAiChatRequested extends NotesEvent {
  final String noteId, message;
  const NotesAiChatRequested(this.noteId, this.message);
  @override List<Object?> get props => [noteId, message];
}
class NotesAutoTagRequested extends NotesEvent { final String noteId; const NotesAutoTagRequested(this.noteId); @override List<Object?> get props => [noteId]; }
class NotesGenerateSummaryRequested extends NotesEvent { final String noteId; const NotesGenerateSummaryRequested(this.noteId); @override List<Object?> get props => [noteId]; }
class NotesGenerateQuizRequested extends NotesEvent { final String noteId; final int count; const NotesGenerateQuizRequested(this.noteId, {this.count = 5}); @override List<Object?> get props => [noteId, count]; }
class NotesGenerateRoadmapRequested extends NotesEvent { final String noteId; const NotesGenerateRoadmapRequested(this.noteId); @override List<Object?> get props => [noteId]; }
class NotesGenerateFlashcardsRequested extends NotesEvent { final String noteId; final int count; const NotesGenerateFlashcardsRequested(this.noteId, {this.count = 7}); @override List<Object?> get props => [noteId, count]; }
class NotesScheduleRevisionRequested extends NotesEvent { final String noteId; const NotesScheduleRevisionRequested(this.noteId); @override List<Object?> get props => [noteId]; }
class NotesSemanticSearchRequested extends NotesEvent { final String query; const NotesSemanticSearchRequested(this.query); @override List<Object?> get props => [query]; }

// ─── State ───────────────────────────────────────────────────────
enum NotesStatus { initial, loading, loaded, error }
enum NotesAiStatus { idle, loading, loaded, error }

class NotesState extends Equatable {
  final NotesStatus status;
  final NotesAiStatus aiStatus;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> folders;
  final Map<String, dynamic>? dailyNote;
  final List<Map<String, dynamic>> revisionNotes;
  final Map<String, dynamic> stats;
  final String? error;
  final String? aiChatReply;
  final List<Map<String, dynamic>> currentQuiz;
  final List<Map<String, dynamic>> currentFlashcards;
  final String? currentRoadmap;
  final String? aiAction; // tracks what AI is doing

  const NotesState({
    this.status = NotesStatus.initial,
    this.aiStatus = NotesAiStatus.idle,
    this.notes = const [],
    this.folders = const [],
    this.dailyNote,
    this.revisionNotes = const [],
    this.stats = const {},
    this.error,
    this.aiChatReply,
    this.currentQuiz = const [],
    this.currentFlashcards = const [],
    this.currentRoadmap,
    this.aiAction,
  });

  NotesState copyWith({
    NotesStatus? status,
    NotesAiStatus? aiStatus,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? folders,
    Map<String, dynamic>? dailyNote,
    List<Map<String, dynamic>>? revisionNotes,
    Map<String, dynamic>? stats,
    String? error,
    String? aiChatReply,
    List<Map<String, dynamic>>? currentQuiz,
    List<Map<String, dynamic>>? currentFlashcards,
    String? currentRoadmap,
    String? aiAction,
  }) => NotesState(
    status: status ?? this.status,
    aiStatus: aiStatus ?? this.aiStatus,
    notes: notes ?? this.notes,
    folders: folders ?? this.folders,
    dailyNote: dailyNote ?? this.dailyNote,
    revisionNotes: revisionNotes ?? this.revisionNotes,
    stats: stats ?? this.stats,
    error: error,
    aiChatReply: aiChatReply,
    currentQuiz: currentQuiz ?? this.currentQuiz,
    currentFlashcards: currentFlashcards ?? this.currentFlashcards,
    currentRoadmap: currentRoadmap ?? this.currentRoadmap,
    aiAction: aiAction ?? this.aiAction,
  );

  @override List<Object?> get props => [status, aiStatus, notes, folders, dailyNote, stats, error, aiChatReply, currentQuiz, currentFlashcards, currentRoadmap, aiAction];
}

// ─── BLoC ────────────────────────────────────────────────────────
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository _repo;

  NotesBloc(this._repo) : super(const NotesState()) {
    on<NotesLoadRequested>(_onLoad);
    on<NotesDailyRequested>(_onDaily);
    on<NotesRevisionRequested>(_onRevision);
    on<NotesStatsRequested>(_onStats);
    on<NotesCreateRequested>(_onCreate);
    on<NotesDeleteRequested>(_onDelete);
    on<NotesAiChatRequested>(_onAiChat);
    on<NotesAutoTagRequested>(_onAutoTag);
    on<NotesGenerateSummaryRequested>(_onSummary);
    on<NotesGenerateQuizRequested>(_onQuiz);
    on<NotesGenerateRoadmapRequested>(_onRoadmap);
    on<NotesGenerateFlashcardsRequested>(_onFlashcards);
    on<NotesScheduleRevisionRequested>(_onScheduleRevision);
    on<NotesSemanticSearchRequested>(_onSemanticSearch);
  }

  Future<void> _onLoad(NotesLoadRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(status: NotesStatus.loading));
    try {
      final results = await Future.wait([
        _repo.getNotes(folder: event.folder, search: event.search, type: event.type, collection: event.collection, dueReview: event.dueReview),
        _repo.getFolders(),
      ]);
      emit(state.copyWith(status: NotesStatus.loaded, notes: results[0], folders: results[1]));
    } catch (e) { emit(state.copyWith(status: NotesStatus.error, error: e.toString())); }
  }

  Future<void> _onDaily(NotesDailyRequested event, Emitter<NotesState> emit) async {
    try {
      final note = await _repo.getDailyNote();
      emit(state.copyWith(dailyNote: note));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onRevision(NotesRevisionRequested event, Emitter<NotesState> emit) async {
    try {
      final notes = await _repo.getRevisionNotes();
      emit(state.copyWith(revisionNotes: notes));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onStats(NotesStatsRequested event, Emitter<NotesState> emit) async {
    try {
      final stats = await _repo.getStats();
      emit(state.copyWith(stats: stats));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onCreate(NotesCreateRequested event, Emitter<NotesState> emit) async {
    try {
      final note = await _repo.createNote(event.data);
      emit(state.copyWith(notes: [note, ...state.notes]));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onDelete(NotesDeleteRequested event, Emitter<NotesState> emit) async {
    try {
      await _repo.deleteNote(event.id);
      emit(state.copyWith(notes: state.notes.where((n) => n['_id'] != event.id).toList()));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onAiChat(NotesAiChatRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(aiStatus: NotesAiStatus.loading, aiAction: 'chat'));
    try {
      final reply = await _repo.aiChat(event.noteId, event.message);
      emit(state.copyWith(aiStatus: NotesAiStatus.loaded, aiChatReply: reply));
    } catch (e) { emit(state.copyWith(aiStatus: NotesAiStatus.error, error: e.toString())); }
  }

  Future<void> _onAutoTag(NotesAutoTagRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(aiStatus: NotesAiStatus.loading, aiAction: 'autotag'));
    try {
      final result = await _repo.autoTag(event.noteId);
      emit(state.copyWith(aiStatus: NotesAiStatus.loaded, aiChatReply: '${result['title']}|${(result['tags'] as List).join(',')}'));
    } catch (e) { emit(state.copyWith(aiStatus: NotesAiStatus.error, error: e.toString())); }
  }

  Future<void> _onSummary(NotesGenerateSummaryRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(aiStatus: NotesAiStatus.loading, aiAction: 'summary'));
    try {
      final summary = await _repo.generateSummary(event.noteId);
      emit(state.copyWith(aiStatus: NotesAiStatus.loaded, aiChatReply: summary));
    } catch (e) { emit(state.copyWith(aiStatus: NotesAiStatus.error, error: e.toString())); }
  }

  Future<void> _onQuiz(NotesGenerateQuizRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(aiStatus: NotesAiStatus.loading, aiAction: 'quiz'));
    try {
      final quiz = await _repo.generateQuiz(event.noteId, count: event.count);
      emit(state.copyWith(aiStatus: NotesAiStatus.loaded, currentQuiz: quiz));
    } catch (e) { emit(state.copyWith(aiStatus: NotesAiStatus.error, error: e.toString())); }
  }

  Future<void> _onRoadmap(NotesGenerateRoadmapRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(aiStatus: NotesAiStatus.loading, aiAction: 'roadmap'));
    try {
      final roadmap = await _repo.generateRoadmap(event.noteId);
      emit(state.copyWith(aiStatus: NotesAiStatus.loaded, currentRoadmap: roadmap));
    } catch (e) { emit(state.copyWith(aiStatus: NotesAiStatus.error, error: e.toString())); }
  }

  Future<void> _onFlashcards(NotesGenerateFlashcardsRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(aiStatus: NotesAiStatus.loading, aiAction: 'flashcards'));
    try {
      final flashcards = await _repo.generateFlashcards(event.noteId, count: event.count);
      emit(state.copyWith(aiStatus: NotesAiStatus.loaded, currentFlashcards: flashcards));
    } catch (e) { emit(state.copyWith(aiStatus: NotesAiStatus.error, error: e.toString())); }
  }

  Future<void> _onScheduleRevision(NotesScheduleRevisionRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(aiStatus: NotesAiStatus.loading, aiAction: 'revision'));
    try {
      await _repo.scheduleRevision(event.noteId);
      emit(state.copyWith(aiStatus: NotesAiStatus.loaded));
    } catch (e) { emit(state.copyWith(aiStatus: NotesAiStatus.error, error: e.toString())); }
  }

  Future<void> _onSemanticSearch(NotesSemanticSearchRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(status: NotesStatus.loading));
    try {
      final results = await _repo.semanticSearch(event.query);
      emit(state.copyWith(status: NotesStatus.loaded, notes: results));
    } catch (e) { emit(state.copyWith(status: NotesStatus.error, error: e.toString())); }
  }
}
