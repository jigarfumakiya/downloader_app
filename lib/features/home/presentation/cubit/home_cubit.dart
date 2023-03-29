import 'package:bloc/bloc.dart';
import 'package:downloader_app/features/home/domain/usecase/home_use_case.dart';
import 'package:equatable/equatable.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeUseCase homeUseCase;

  HomeCubit(this.homeUseCase) : super(HomeInitial());



  getDownloads(){

  }
}
