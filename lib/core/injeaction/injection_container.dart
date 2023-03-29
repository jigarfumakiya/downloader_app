import 'dart:io';

import 'package:downloader_app/core/service/downloader_service/download_manager.dart';
import 'package:downloader_app/features/home/data/datasource/home_remote_source.dart';
import 'package:downloader_app/features/home/data/datasource/local/home_local_source.dart';
import 'package:downloader_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:downloader_app/features/home/domain/repositories/home_repository.dart';
import 'package:downloader_app/features/home/domain/usecase/home_use_case.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';

final GetIt sl = GetIt.instance;

Future<void> init({bool isMock = false}) async {
  //? Bloc
  sl.registerFactory(() => HomeCubit(sl()));

  //? Use Case
  sl.registerLazySingleton(() => HomeUseCase(sl()));

  sl.registerLazySingleton(() => DownloadManager());
  sl.registerLazySingleton(() => Client());
  sl.registerLazySingleton(() => HttpClient());

  //? Repository
  //Home
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteSource: sl(), localSource: sl()),
  );

  //? Data Source
  sl.registerLazySingleton<HomeRemoteSource>(() => HomeRemoteSourceImpl());

  sl.registerLazySingleton<HomeLocalSource>(() => HomeLocalSourceImpl());
}
