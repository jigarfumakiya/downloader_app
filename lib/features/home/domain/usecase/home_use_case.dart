import 'package:dartz/dartz.dart';
import 'package:downloader_app/core/exceptions/app_exceptions.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';

import '../repositories/home_repository.dart';

class HomeUseCase {
  final HomeRepository _homeRepository;

  HomeUseCase(this._homeRepository);

  Future<Either<Failure, List<DownloadNetwork>>> getDownloads() async {
    return await _homeRepository.getDownloads();
  }

  Future<Either<Failure, bool>> addDownloads(
      String url, String fileName) async {
    return await _homeRepository.addDownloads(url, fileName);
  }
}
