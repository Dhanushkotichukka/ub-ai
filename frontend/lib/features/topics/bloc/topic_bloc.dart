import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/topic_repository.dart';
import '../../../shared/models/models.dart';

abstract class TopicEvent extends Equatable { const TopicEvent(); @override List<Object?> get props => []; }
class TopicLoadRequested extends TopicEvent {}
class TopicRecalculateRequested extends TopicEvent {}

enum TopicStatus { initial, loading, loaded, error }

class TopicState extends Equatable {
  final TopicStatus status;
  final List<TopicModel> topics;
  final String? error;
  const TopicState({this.status = TopicStatus.initial, this.topics = const [], this.error});
  TopicState copyWith({TopicStatus? status, List<TopicModel>? topics, String? error}) => TopicState(status: status ?? this.status, topics: topics ?? this.topics, error: error);
  @override List<Object?> get props => [status, topics, error];
}

class TopicBloc extends Bloc<TopicEvent, TopicState> {
  final TopicRepository _repo;
  TopicBloc(this._repo) : super(const TopicState()) {
    on<TopicLoadRequested>(_onLoad);
    on<TopicRecalculateRequested>(_onRecalculate);
  }

  Future<void> _onLoad(TopicLoadRequested event, Emitter<TopicState> emit) async {
    emit(state.copyWith(status: TopicStatus.loading));
    try { final topics = await _repo.getTopics(); emit(state.copyWith(status: TopicStatus.loaded, topics: topics)); }
    catch (e) { emit(state.copyWith(status: TopicStatus.error, error: e.toString())); }
  }

  Future<void> _onRecalculate(TopicRecalculateRequested event, Emitter<TopicState> emit) async {
    try { final topics = await _repo.recalculate(); emit(state.copyWith(topics: topics)); }
    catch (e) { emit(state.copyWith(error: e.toString())); }
  }
}
