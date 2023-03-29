import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
import 'package:hive_flutter/hive_flutter.dart';



class DownloadNetwork {
  final String fileName;
  final String url;
  final DownloadState state;

  DownloadNetwork({
    required this.fileName,
    required this.url,
    required this.state,
  });
}
