import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'download_table.g.dart';
/**
 * @Author: Jigar Fumakiya
 * @Date: 29/03/23
 * @Project: downloader_app
 * download_table
 */

@HiveType(typeId: 001)
class DownloadTable extends DownloadNetwork {
  @HiveField(1)
  final String fileName;
  @HiveField(2)
  final String url;
  @HiveField(3)
  final DownloadState state;

  DownloadTable({
    required this.fileName,
    required this.url,
    required this.state,
  }) : super(state: state, fileName: fileName, url: url);

  factory DownloadTable.fromModel(DownloadNetwork model) => DownloadTable(
        fileName: model.fileName,
        url: model.url,
        state: model.state,
      );

  static DownloadNetwork toModel(DownloadTable table) => DownloadNetwork(
        state: table.state,
        url: table.url,
        fileName: table.fileName,
      );
}
