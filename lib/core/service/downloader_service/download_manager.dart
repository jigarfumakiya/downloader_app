import 'package:downloader_app/core/service/downloader_service/download_service.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 29/03/23
 * @Project: downloader_app
 * download_manager
 */

class DownloadManager {
  Map<String, DownloadState> _downloadStates = {};

  final List<DownloadService> _downloads = [];

  Future<String> addDownload(
    String magnetUri,
    String savePath, {
    required ProgressCallback progressCallback,
    required ProgressDoneCallback doneCallback,
    required ProgressErrorCallback errorCallback,
  }) async {
    final downloadId = _createDownloadId(magnetUri, savePath);
    _downloadStates[downloadId] = DownloadState.downloading;

    final downloadService = DownloadService(
        id: downloadId,
        progressCallback: progressCallback,
        doneCallback: doneCallback,
        errorCallback: errorCallback);
    _downloads.add(downloadService);
    downloadService.downloadFile(magnetUri, savePath).then((value) {
      _downloads.remove(downloadService);
      _downloadStates[downloadId] = DownloadState.completed;
    });

    return downloadId;
  }

  void pauseAllDownloads() {
    for (var download in _downloads) {
      download.pauseDownload();
    }
  }

  void resumeAllDownloads() {
    for (var download in _downloads) {
      download.resumeDownload();
    }
  }

  void pauseDownload(String id) {
    _downloads.firstWhere((download) => download.id == id).pauseDownload();
    _downloadStates[id] = DownloadState.pause;
  }

  void resumeDownload(String id) {
    _downloads.firstWhere((download) => download.id == id).resumeDownload();
    _downloadStates[id] = DownloadState.downloading;
  }

  String _createDownloadId(String url, String savePath) {
    return '${url.hashCode}_${savePath.hashCode}';
  }

  DownloadState getDownloadState(String downloadId) {
    return _downloadStates[downloadId] ?? DownloadState.notStarted;
  }
}
