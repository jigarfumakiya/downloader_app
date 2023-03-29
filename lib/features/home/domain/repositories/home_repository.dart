import 'package:dartz/dartz.dart';
import 'package:downloader_app/core/exceptions/app_exceptions.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<DownloadNetwork>>> getDownloads();

}
