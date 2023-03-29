import 'package:downloader_app/core/service/downloader_service/download_service.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
/**
 * @Author: Jigar Fumakiya
 * @Date: 29/03/23
 * @Project: downloader_app
 * download_manager
 */

/// A class to manage multiple downloads, allowing for pausing, resuming, and tracking the state of each download.
///
/// Example usage:
///
///     DownloadManager downloadManager = DownloadManager();
///     String downloadId = await downloadManager.addDownload(
///         magnetUri, savePath,
///         progressCallback: (progress) => print(progress),
///         doneCallback: (path) => print('Download completed: $path'),
///         errorCallback: (error) => print('Error: $error'));
///
class DownloadManager {
  // Stores the download states using download IDs as keys.

  final Map<String, DownloadState> _downloadStates = {};

  // A list of download service instances to manage active downloads.

  final List<DownloadService> _downloads = [];

  /// Adds a new download with the provided [magnetUri] and [savePath].
  ///
  /// [progressCallback] is called to provide progress updates.
  /// [doneCallback] is called when the download is completed.
  /// [errorCallback] is called when an error occurs during the download.
  ///
  /// Returns a unique [downloadId] for the added download.
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

  /// Pauses all active downloads.

  void pauseAllDownloads() {
    for (var download in _downloads) {
      download.pauseDownload();
    }
  }

  /// Resumes all paused downloads.

  void resumeAllDownloads() {
    for (var download in _downloads) {
      download.resumeDownload();
    }
  }

  /// Pauses the download with the specified [id].

  void pauseDownload(String id) {
    _downloads.firstWhere((download) => download.id == id).pauseDownload();
    _downloadStates[id] = DownloadState.pause;
  }

  /// Resumes the download with the specified [id].
  void resumeDownload(String id) {
    _downloads.firstWhere((download) => download.id == id).resumeDownload();
    _downloadStates[id] = DownloadState.downloading;
  }

  /// Generates a unique download ID using the hash codes of [url] and [savePath].
  String _createDownloadId(String url, String savePath) {
    return '${url.hashCode}_${savePath.hashCode}';
  }

  /// Retrieves the download state for the given [downloadId].
  DownloadState getDownloadState(String downloadId) {
    return _downloadStates[downloadId] ?? DownloadState.notStarted;
  }
}
