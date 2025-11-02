
import 'package:bloc/bloc.dart';
import '../../../core/database/app_database.dart';
import '../../organisms/data/repositories/organism_repository.dart';

sealed class OrganismEvent {}
class LoadPragas extends OrganismEvent { final int culturaId; LoadPragas(this.culturaId); }
class LoadDoencas extends OrganismEvent { final int culturaId; LoadDoencas(this.culturaId); }

sealed class OrganismState {}
class OrganismInitial extends OrganismState {}
class OrganismLoading extends OrganismState {}
class OrganismLoaded extends OrganismState {
  final List<Organismo> data;
  OrganismLoaded(this.data);
}
class OrganismError extends OrganismState {
  final String message;
  OrganismError(this.message);
}

class OrganismBloc extends Bloc<OrganismEvent, OrganismState> {
  final IOrganismRepository repo;
  OrganismBloc(this.repo): super(OrganismInitial()) {
    on<LoadPragas>((event, emit) async {
      emit(OrganismLoading());
      try {
        final list = await repo.getByCulture(event.culturaId, isDisease: false);
        emit(OrganismLoaded(list));
      } catch (e) {
        emit(OrganismError(e.toString()));
      }
    });
    on<LoadDoencas>((event, emit) async {
      emit(OrganismLoading());
      try {
        final list = await repo.getByCulture(event.culturaId, isDisease: true);
        emit(OrganismLoaded(list));
      } catch (e) {
        emit(OrganismError(e.toString()));
      }
    });
  }
}
