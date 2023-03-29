import 'package:downloader_app/features/home/data/models/home_network.dart';

abstract class HomeRemoteSource {
  Future<List<DownloadNetwork>> getDownloads();

}

class HomeRemoteSourceImpl implements HomeRemoteSource {
  @override
  Future<List<DownloadNetwork>> getDownloads() async {
    return [
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
          state: DownloadState.notStarted)
    ];
  }
}
