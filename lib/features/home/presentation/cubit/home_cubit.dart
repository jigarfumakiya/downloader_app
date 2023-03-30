import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:downloader_app/features/home/domain/usecase/home_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

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

  Future<void> addDownload(String url) async {
    try {
      final result = await homeUseCase.addDownloads(url, p.basename(url));
      result.fold((failure) {
        emit(AddDownloadStateFailure(failure.message));
      }, (success) {
        log(success.toString());
        getDownloads();
      });
    } catch (e) {

      emit(HomeFailureState(e.toString()));
    }
  }

}
