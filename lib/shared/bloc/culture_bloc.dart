
import 'package:bloc/bloc.dart';
import '../../culture/data/repositories/culture_repository.dart';
import '../../../core/database/app_database.dart';

sealed class CultureEvent {}
class LoadCultures extends CultureEvent {}

sealed class CultureState {}
class CultureInitial extends CultureState {}
class CultureLoading extends CultureState {}
class CultureLoaded extends CultureState {
  final List<Cultura> culturas;
  CultureLoaded(this.culturas);
}
class CultureError extends CultureState {
  final String message;
  CultureError(this.message);
}

class CultureBloc extends Bloc<CultureEvent, CultureState> {
  final ICultureRepository repo;
  CultureBloc(this.repo) : super(CultureInitial()) {
    on<LoadCultures>((event, emit) async {
      emit(CultureLoading());
      try {
        final list = await repo.getAll();
        emit(CultureLoaded(list));
      } catch (e) {
        emit(CultureError(e.toString()));
      }
    });
  }
}
