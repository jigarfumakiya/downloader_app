import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:downloader_app/features/home/domain/usecase/home_use_case.dart';
import 'package:equatable/equatable.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeUseCase homeUseCase;

  HomeCubit(this.homeUseCase) : super(HomeInitial());

  Future<void> getDownloads() async {
    emit(HomeLoading());

    try {
      final result = await homeUseCase.getDownloads();
      result.fold((failure) {
        emit(HomeFailureState(failure.message));
      }, (success) {
        log(success.toString());
        emit(HomeSuccessState(success));
      });
    } catch (e) {
      //Todo make generic class for error handling
      emit(HomeFailureState(e.toString()));
    }
  }
}
