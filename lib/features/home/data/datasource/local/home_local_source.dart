import 'package:downloader_app/features/home/data/datasource/local/database/base_local_database.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/database_util.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';

abstract class HomeLocalSource {
  Future<List<DownloadNetwork>> getDownloads();

  Future cacheDownloades(List<DownloadNetwork> downloadList);

  Future deleteDownloads(DownloadNetwork downloadNetwork);
}

class HomeLocalSourceImpl
    extends BaseLocalDataSource<DownloadTable, DownloadNetwork>
    with HomeLocalSource {
  HomeLocalSourceImpl() : super(boxName: 'download') {
    DatabaseUtil.registerAdapter<DownloadTable>(DownloadTableAdapter());
  }

  @override
  Future cacheDownloades(List<DownloadNetwork> downloadList) async {
    await insertOrUpdateAll(downloadList);
  }

  @override
  Future deleteDownloads(DownloadNetwork downloadNetwork) {
    return delete(downloadNetwork.fileName);
  }

  @override
  Future<List<DownloadNetwork>> getDownloads() {
    return getFormattedData();
  }

  @override
  Future<List<DownloadNetwork>> getFormattedData() async {
    final List<DownloadTable> data = await getAll();
    return data.map(DownloadTable.toModel).toList();
  }

  @override
  Future<void> insertOrUpdateAll(List<DownloadNetwork> downloads) async {
    final Map<String, DownloadTable> downloadMap = {
      for (var download in downloads)
        download.fileName: DownloadTable.fromModel(download)
    };
    print('Download cached');
    await putAll(downloadMap);
  }
}
