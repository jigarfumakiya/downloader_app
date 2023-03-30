import 'package:dartz/dartz.dart';
import 'package:downloader_app/core/exceptions/app_exceptions.dart';
import 'package:downloader_app/features/home/data/datasource/local/home_local_source.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';

import '../../domain/repositories/home_repository.dart';
import '../datasource/home_remote_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteSource remoteSource;
  final HomeLocalSource localSource;

  HomeRepositoryImpl({
    required this.remoteSource,
    required this.localSource,
  });

  @override
  Future<Either<Failure, List<DownloadNetwork>>> getDownloads() async {
    try {
      List<DownloadNetwork> downloads = await localSource.getDownloads();

      return Right(downloads);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  Future<void> refreshList() async {
    final useResponse = await remoteSource.getDownloads();
    await localSource.cacheDownloades(useResponse);
  }

  @override
  Future<Either<Failure, bool>> addDownloads(
      String url, String fileName) async {
    try {
      await localSource.addDownload(url, fileName);
      return const Right(true);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
