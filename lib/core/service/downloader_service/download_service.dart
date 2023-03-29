/**
 * @Author: Jigar Fumakiya
 * @Date: 28/03/23
 * @Project: downloader_app
 * download_service
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Global [typedef] that returns a `int` with the current byte on download
/// and another `int` with the total of bytes of the file.
typedef ProgressCallback = void Function(
    int remainBytes, int totalBytes, double percentage);

/// Global [typedef] that returns a `string` with download file path
typedef ProgressDoneCallback = void Function(String filepath);

typedef ProgressErrorCallback = void Function(dynamic error);

class DownloadService {
  static const int _chunkSize = (1024 * 8) * (1024 * 8); // 64 MB
  final client = HttpClient();
  final String id;

  final ProgressCallback _progressCallback;
  final ProgressDoneCallback _doneCallback;
  final ProgressErrorCallback _errorCallback;
  final List<StreamSubscription<List<int>>> _subscriptions;

  DownloadService({
    required this.id,
    required ProgressCallback progressCallback,
    required ProgressDoneCallback doneCallback,
    required ProgressErrorCallback errorCallback,
  })  : _progressCallback = progressCallback,
        _doneCallback = doneCallback,
        _errorCallback = errorCallback,
        _subscriptions = [];

  Future<void> downloadFile(String magnetUri, String savePath) async {
    // Calculate dynamic chunk size based on content length and maximum chunks allowed

    final int contentLength = await _getContentLength(magnetUri);
    const int maxChunks = 4;
    int dynamicChunkSize =
        max(contentLength ~/ maxChunks, 1024 * 1024 * 64); // Default 64 MB

    final int numberOfChunks = (contentLength / dynamicChunkSize).ceil();
    final List<Range> ranges = _splitRange(contentLength, numberOfChunks);
    final List<File> downloadedFiles = [];

    await Future.wait(ranges.map((range) async {
      print('Range $range ');
      final filePath = await _downloadChunk(
        magnetUri,
        savePath,
        range.start,
        range.end,
        contentLength,
      ).catchError((error) => print('Download error: $error'));

      if (filePath != null) {
        downloadedFiles.add(File(filePath));
      } else {
        print('Download null value');
      }
    }));

    // Verify sequence of downloaded files
    downloadedFiles
        .sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    downloadedFiles.sort(
      (a, b) {
        final String filenameA = p.basename(a.path);
        final String filenameB = p.basename(b.path);
        return filenameA.compareTo(filenameB);
      },
    );

    // Create directory
    final dir = Directory(savePath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Merge downloaded files into a single file
    final outputFile = File(savePath);
    final outputSink = outputFile.openWrite();
    for (final file in downloadedFiles) {
      await outputSink.addStream(file.openRead());
      await file.delete();
    }
    await outputSink.close();
    _doneCallback(outputFile.path);
  }

  void pauseDownload() {
    for (var subscription in _subscriptions) {
      subscription.pause();
    }
  }

  void resumeDownload() {
    for (var subscription in _subscriptions) {
      subscription.resume();
    }
  }

  List<Range> _splitRange(int contentLength, int numberOfChunks) {
    final List<Range> ranges = [];
    for (int i = 0; i < numberOfChunks; i++) {
      final start = i * _chunkSize;
      final end = min(start + _chunkSize - 1,
          contentLength - 1); // Subtract 1 from end range
      ranges.add(Range(start, end));
    }
    return ranges;
  }

  Future<int> _getContentLength(String magnetUri) async {
    final uri = Uri.parse(magnetUri);
    final request = await client.getUrl(uri);
    final response = await request.close();
    final contentLength =
        int.parse(response.headers.value(HttpHeaders.contentLengthHeader)!);
    client.close();
    return contentLength;
  }

  Future<String?> _downloadChunk(String magnetUri, String savePath, int start,
      int end, int contentLength) async {
    var request = http.Request('GET', Uri.parse(magnetUri));

    final removePaht = savePath.split('/').last;
    final dirPath = savePath.replaceAll(removePaht, "");
    final filePath = '$dirPath$start-$end.tmp';
    final currentFile = File(filePath);
    int lastProgress = 0;

    final bool fileExists = await currentFile.exists();
    if (!fileExists) {
      final dir = Directory(filePath).parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      lastProgress = await currentFile.length();
    }
    final rangeHeader = 'bytes=$start-$end';
    final header = {
      HttpHeaders.rangeHeader:
          fileExists ? 'bytes=$lastProgress-' : rangeHeader,
      'cache-control': 'no-cache',
    };
    request.headers.addAll(header);

    final response = await request.send();
    if (response.statusCode == HttpStatus.partialContent) {
      final randomAccessFile = await currentFile.open(mode: FileMode.append);
      final completer = Completer<String>();
      final subscription = response.stream.listen((List<int> data) async {
        final rangeLength = end - start + 1;
        final currentProgress = lastProgress + data.length;
        final remainingBytes = rangeLength - currentProgress;
        final percentage = (currentProgress / rangeLength) * 100;
        randomAccessFile.writeFromSync(data);
        _progressCallback(remainingBytes, contentLength, percentage);
        lastProgress = currentProgress;
      }, onDone: () async {
        print('Chunk Downloaded ${currentFile.path}');
        completer.complete(currentFile.path);
        await randomAccessFile.close();
      }, onError: (error) async {
        await randomAccessFile.close();
        completer.completeError(error);
        _errorCallback(error);
      });

      _subscriptions.add(subscription);
      completer.future.then((_) {
        _subscriptions.remove(subscription);
      }).catchError((_) {
        _subscriptions.remove(subscription);
      });
      return completer.future;
    } else {
      throw Exception('Failed to download chunk from $magnetUri');
    }
  }
}

class Range {
  final int start;
  final int end;

  Range(this.start, this.end);
}

class DownloadChunkModel {
  late final String magnetUri;
  final String savePath;
  final int start;
  final int end;
  final int contentLength;
}
