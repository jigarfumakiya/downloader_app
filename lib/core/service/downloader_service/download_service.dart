/**
 * @Author: Jigar Fumakiya
 * @Date: 28/03/23
 * @Project: downloader_app
 * download_service
 */
// import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:http/http.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;

/// Global [typedef] that returns a `int` with the current byte on download
/// and another `int` with the total of bytes of the file.
typedef ProgressCallback = void Function(
    int remainBytes, int totalBytes, double percentage);

/// Global [typedef] that returns a `string` with download file path
typedef ProgressDoneCallback = void Function(String filepath);

typedef ProgressErrorCallback = void Function(dynamic error);

/// A class that handles downloading a file in chunks, with support for pausing and resuming the download.
///
/// Example usage:
///
///     DownloadService downloadService = DownloadService(
///         id: "example",
///         progressCallback: (remainingBytes, contentLength, percentage) =>
///             print('$percentage% downloaded'),
///         doneCallback: (path) => print('Download completed: $path'),
///         errorCallback: (error) => print('Error: $error'));
///
///     await downloadService.downloadFile(magnetUri, savePath);
///
class DownloadService {
  static const int _chunkSize = (1024 * 8) * (1024 * 8); // 64 MB
  final HttpClient ioClient;
  final String id;

  final ProgressCallback _progressCallback;
  final ProgressDoneCallback _doneCallback;
  final ProgressErrorCallback _errorCallback;
  List<_DownloadTask> isolates;
  final Client client;

  /// Creates a new DownloadService instance.
  ///
  /// [id] is a unique identifier for the download.
  /// [progressCallback] is called to provide progress updates.
  /// [doneCallback] is called when the download is completed.
  /// [errorCallback] is called when an error occurs during the download.
  DownloadService({
    required this.id,
    required this.ioClient,
    required this.client,
    required ProgressCallback progressCallback,
    required ProgressDoneCallback doneCallback,
    required ProgressErrorCallback errorCallback,
  })  : _progressCallback = progressCallback,
        _doneCallback = doneCallback,
        _errorCallback = errorCallback,
        isolates = [];

  /// Downloads a file using the given [magnetUri] and saves it to [savePath].
  ///
  /// The file will be downloaded in chunks, with each chunk being handled by a separate isolate.
  Future<void> downloadFile(String magnetUri, String savePath) async {
    // Calculate dynamic chunk size based on content length and maximum chunks allowed
    final int contentLength = await _getContentLength(magnetUri);
    const int maxChunks = 4;
    int dynamicChunkSize =
        max(contentLength ~/ maxChunks, 1024 * 1024 * 64); // Default 64 MB

    final int numberOfChunks = (contentLength / dynamicChunkSize).ceil();
    final List<Range> ranges = _splitRange(contentLength, numberOfChunks);
    final List<File> downloadedFiles = [];
    final int totalChunksSize = contentLength * numberOfChunks;

    // Create a list of ReceivePort instances to receive data from isolates
    List<ReceivePort> receivePorts = [];

    // Run downloadChunk function in separate isolates
    for (int i = 0; i < ranges.length; i++) {
      ReceivePort receivePort = ReceivePort();
      receivePorts.add(receivePort);
      // Spawn an isolate and pass the download information

      Isolate isolate = await Isolate.spawn(
        downloadChunkInIsolate,
        DownloadChunkModel(
          magnetUri: magnetUri,
          savePath: savePath,
          range: ranges[i],
          contentLength: contentLength,
          sendPort: receivePort.sendPort,
          chunkSize: totalChunksSize,
        ),
      );
      final model = _DownloadTask(isolate: isolate);
      isolates.add(model);

      // Listen for messages from the isolate
      receivePort.listen((message) {
        if (message['type'] == 'progress') {
          // Update progress
          _progressCallback(
            message['currentBytes'],
            message['contentLength'],
            message['percentage'],
          );
        } else if (message['type'] == 'done') {
          // Mark the chunk as downloaded and add the file to the list

          downloadedFiles.add(File(message['filePath']));
          _doneCallback(message['filePath']);
          // Kill the isolate
          isolate.kill(priority: Isolate.immediate);
        } else if (message['type'] == 'error') {
          _errorCallback(message['error']);
        }
      });
    }

    // Merge downloaded files after all isolates have completed their tasks
    while (downloadedFiles.length != ranges.length) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Verify sequence of downloaded files
    downloadedFiles
        .sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

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

  /// Top Level Function
  /// Downloads a chunk of a file using partial content requests.
  ///
  /// This function downloads a specified range of bytes from the given [magnetUri] and saves it to a temporary file
  /// in the same directory as the final [savePath]. It reports progress, completion, and errors through the
  /// [_progressCallback], [_doneCallback], and [_errorCallback] functions, respectively.
  ///
  /// [magnetUri] is the URI of the file to download.
  /// [savePath] is the path where the final merged file will be saved.
  /// [start] is the starting byte of the range to download.
  /// [end] is the ending byte of the range to download.
  /// [contentLength] is the total length of the file being downloaded.
  ///
  /// Returns a [Future] that completes with the path of the downloaded chunk file.
  static Future<void> downloadChunkInIsolate(DownloadChunkModel model) async {
    final String magnetUri = model.magnetUri;
    final String savePath = model.savePath;
    final Range range = model.range;
    final int contentLength = model.contentLength;
    final SendPort sendPort = model.sendPort;
    final _mutex = Mutex();

    var request = Request('GET', Uri.parse(magnetUri));

    final removePath = savePath.split('/').last;
    final dirPath = savePath.replaceAll(removePath, "");
    final filePath = '$dirPath${range.start}-${range.end}.tmp';
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
    final resumedStart = range.start + lastProgress;

    if (resumedStart > range.end) {
      // File is already downloaded, send completion message
      sendPort.send({'type': 'done', 'filePath': currentFile.path});
      return;
    }
    final rangeHeader = 'bytes=$resumedStart-${range.end}';

    final header = {
      HttpHeaders.rangeHeader: rangeHeader,
      'cache-control': 'no-cache',
    };
    request.headers.addAll(header);

    try {
      final response = await request.send();
      if (response.statusCode == HttpStatus.partialContent) {
        final randomAccessFile = await currentFile.open(mode: FileMode.append);

        final completer = Completer<String>();
        response.stream.listen((List<int> data) async {
          _mutex.acquire();
          final rangeLength = range.end - range.start + 1;
          final currentProgress = (lastProgress) + (data.length);
          final percentage = (currentProgress / rangeLength) * 100;
          randomAccessFile.writeFromSync(data);

          // print('percentage $percentage');
          // print('currentBytes $currentProgress');

          // Send progress update
          sendPort.send({
            'type': 'progress',
            'currentBytes': currentProgress ,
            'contentLength': contentLength,
            'percentage': percentage,
            'path': currentFile.path
          });

          // lastProgress = currentProgress;
          lastProgress = range.start + (currentFile.lengthSync());
          _mutex.release();
        }, onDone: () async {
          completer.complete(currentFile.path);
          await randomAccessFile.close();
          // Send completion message
          sendPort.send({'type': 'done', 'filePath': currentFile.path});
        }, onError: (error) async {
          await randomAccessFile.close();
          completer.completeError(error);
          // Send error message
          sendPort.send({'type': 'error', 'error': error.toString()});
        });
      } else {
        throw Exception('Failed to download chunk from $magnetUri');
      }
    } catch (e) {
      // Send error message
      sendPort.send({'type': 'error', 'error': e.toString()});
    }
  }

  /// Pauses the download by pausing each isolate.
  ///
  /// This method iterates through the isolates and pauses each one, storing
  /// their capabilities in the corresponding `_DownloadTask` instances.
  void pauseDownload() {
    for (var subscription in isolates) {
      final isolate = subscription.isolate;
      subscription.capability =
          isolate.pause(subscription.isolate.pauseCapability);
    }
  }

  /// Resumes the download by resuming each isolate.
  ///
  /// This method iterates through the isolates and resumes each one using
  /// the capabilities stored in the corresponding `_DownloadTask` instances.
  void resumeDownload() {
    for (var subscription in isolates) {
      final isolate = subscription.isolate;
      print('isolate called');
      isolate.resume(subscription.capability!);
    }
  }

  /// Splits the content length into a specified number of ranges.
  ///
  /// This method divides the [contentLength] into [numberOfChunks] ranges, ensuring
  /// each range is no larger than the defined [_chunkSize].
  ///
  /// Returns a list of [Range] objects, where each represents a range of bytes.
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

  /// Retrieves the content length from the provided magnet URI.
  ///
  /// This method sends an HTTP request to the [magnetUri] to obtain the content length
  /// from the response headers.
  ///
  /// Returns a [Future] that completes with the content length as an integer.
  Future<int> _getContentLength(String magnetUri) async {
    final uri = Uri.parse(magnetUri);
    final request = await ioClient.getUrl(uri);
    final response = await request.close();
    final contentLength =
        int.parse(response.headers.value(HttpHeaders.contentLengthHeader)!);
    return contentLength;
  }
}

/// Represents a range of bytes to be downloaded.
class Range {
  final int start;
  final int end;

  Range(this.start, this.end);

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      json['start'] as int,
      json['end'] as int,
    );
  }
}

/// Model for passing download chunk information to isolates.
class DownloadChunkModel {
  final String magnetUri;
  final String savePath;
  final Range range;
  final int contentLength;
  final SendPort sendPort;
  final int chunkSize;

  DownloadChunkModel({
    required this.magnetUri,
    required this.savePath,
    required this.range,
    required this.contentLength,
    required this.sendPort,
    required this.chunkSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'magnetUri': magnetUri,
      'savePath': savePath,
      'range': range.toJson(),
      'contentLength': contentLength,
      'sendPort': sendPort,
    };
  }

  factory DownloadChunkModel.fromJson(Map<String, dynamic> json) {
    return DownloadChunkModel(
        magnetUri: json['magnetUri'] as String,
        savePath: json['savePath'] as String,
        range: Range.fromJson(json['range'] as Map<String, dynamic>),
        contentLength: json['contentLength'] as int,
        sendPort: json['sendPort'] as SendPort,
        chunkSize: json['chunkSize'] as int);
  }
}

/// Represents a download task being handled by an isolate.
///
/// [_DownloadTask] keeps track of the isolate and its pause capability, allowing for pausing and resuming the download.
class _DownloadTask {
  final Isolate isolate;
  Capability? capability;

  _DownloadTask({
    required this.isolate,
    this.capability,
  });
}
