import 'package:downloader_app/features/home/data/datasource/local/database/base_local_database.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/database_util.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';

final sampleDownloadList = [
  DownloadNetwork(
      fileName: 'Dummy.PDf',
      url:
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      state: DownloadState.notStarted),
  DownloadNetwork(
      fileName: 'Sample-MP4-Video.mp4',
      url:
          'https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-MP4-Video-File-for-Testing.mp4',
      state: DownloadState.notStarted),
  DownloadNetwork(
      fileName: 'BigBuckBunny.mp4',
      url:
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      state: DownloadState.notStarted),
  DownloadNetwork(
      fileName: '100 MB',
      url: 'https://speed.hetzner.de/100MB.bin',
      state: DownloadState.notStarted),
];

abstract class HomeLocalSource {
  Future<List<DownloadNetwork>> getDownloads();

  Future<void> addDownload(String url, String fileName);

  Future cacheDownloades(List<DownloadNetwork> downloadList);

  Future deleteDownloads(DownloadNetwork downloadNetwork);
}

class HomeLocalSourceImpl
    extends BaseLocalDataSource<DownloadTable, DownloadNetwork>
    with HomeLocalSource {
  HomeLocalSourceImpl() : super(boxName: 'download') {
    DatabaseUtil.registerAdapter<DownloadTable>(DownloadTableAdapter());
    DatabaseUtil.registerAdapter<DownloadState>(DownloadStateAdapter());
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

    /// This is just for test because we have no live date yet
    if (data.isEmpty) {
      insertOrUpdateAll(sampleDownloadList);
      List<DownloadTable> data = await getAll();
      return data.map(DownloadTable.toModel).toList();
    }
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

  @override
  Future<void> addDownload(String url, String fileName) async {
    final currentList = await getFormattedData();

    final newDownload = DownloadNetwork(
      fileName: fileName,
      url: url,
      state: DownloadState.notStarted,
    );

    currentList.add(newDownload);
    await deleteAll();
    await insertOrUpdateAll(currentList);
  }
}
