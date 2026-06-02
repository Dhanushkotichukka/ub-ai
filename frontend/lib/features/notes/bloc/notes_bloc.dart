import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/notes_repository.dart';

abstract class NotesEvent extends Equatable { const NotesEvent(); @override List<Object?> get props => []; }
class NotesLoadRequested extends NotesEvent { final String? folder, search; const NotesLoadRequested({this.folder, this.search}); @override List<Object?> get props => [folder, search]; }
class NotesCreateRequested extends NotesEvent { final Map<String, dynamic> data; const NotesCreateRequested(this.data); @override List<Object?> get props => [data]; }
class NotesDeleteRequested extends NotesEvent { final String id; const NotesDeleteRequested(this.id); @override List<Object?> get props => [id]; }

enum NotesStatus { initial, loading, loaded, error }

class NotesState extends Equatable {
  final NotesStatus status;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> folders;
  final String? error;
  const NotesState({this.status = NotesStatus.initial, this.notes = const [], this.folders = const [], this.error});
  NotesState copyWith({NotesStatus? status, List<Map<String, dynamic>>? notes, List<Map<String, dynamic>>? folders, String? error}) =>
    NotesState(status: status ?? this.status, notes: notes ?? this.notes, folders: folders ?? this.folders, error: error);
  @override List<Object?> get props => [status, notes, folders, error];
}

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository _repo;
  NotesBloc(this._repo) : super(const NotesState()) {
    on<NotesLoadRequested>(_onLoad);
    on<NotesCreateRequested>(_onCreate);
    on<NotesDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(NotesLoadRequested event, Emitter<NotesState> emit) async {
    emit(state.copyWith(status: NotesStatus.loading));
    try {
      final results = await Future.wait([_repo.getNotes(folder: event.folder, search: event.search), _repo.getFolders()]);
      emit(state.copyWith(status: NotesStatus.loaded, notes: results[0], folders: results[1]));
    } catch (e) { emit(state.copyWith(status: NotesStatus.error, error: e.toString())); }
  }

  Future<void> _onCreate(NotesCreateRequested event, Emitter<NotesState> emit) async {
    try { final note = await _repo.createNote(event.data); emit(state.copyWith(notes: [note, ...state.notes])); }
    catch (e) { emit(state.copyWith(error: e.toString())); }
  }

  Future<void> _onDelete(NotesDeleteRequested event, Emitter<NotesState> emit) async {
    try {
      await _repo.deleteNote(event.id);
      emit(state.copyWith(notes: state.notes.where((n) => n['_id'] != event.id).toList()));
    } catch (e) { emit(state.copyWith(error: e.toString())); }
  }
}
