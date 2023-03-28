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
import 'package:path_provider/path_provider.dart';

/// Global [typedef] that returns a `int` with the current byte on download
/// and another `int` with the total of bytes of the file.
typedef ProgressCallback = void Function(int count, int total);

/// Global [typedef] that returns a `string` with download file path
typedef ProgressDoneCallback = void Function(String filepath);

// class DownloadService {
//   final List<String> _downloadIds = [];
//
//   final StreamController<double> _progressController =
//   StreamController<double>.broadcast();
//
//   Stream<double> get progressStream => _progressController.stream;
//
//   final List<HttpClient> _httpClients = [];
//   final Map<String, String> _downloadPaths = {};
//   final Map<String, RandomAccessFile> _rafMap = {};
//   final Map<String, int> _bytesReceivedMap = {};
//   final Map<String, List<Completer<void>>> _completerMap = {};
//   final Map<String, List<String>> _hostsMap = {};
//   final StreamController<double> _progressController =
//   StreamController<double>.broadcast();
//
//   Future<String> _getDownloadDirectory() async {
//     if (Platform.isAndroid) {
//       return (await getExternalStorageDirectory())!.path;
//     } else {
//       return (await getDownloadsDirectory())!.path;
//     }
//   }
//
//   Future<void> downloadFile(String url) async {
//     final String dir = await _getDownloadDirectory();
//     final HttpClient httpClient = HttpClient();
//     final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
//     final HttpClientResponse response = await request.close();
//     final int contentLength =
//     int.parse(response.headers.value('content-length') ?? '0');
//     final File file = File('$dir/${DateTime
//         .now()
//         .millisecondsSinceEpoch}');
//     final RandomAccessFile raf = file.openSync(mode: FileMode.write);
//     int bytesReceived = 0;
//
//     response.listen(
//           (List<int> data) {
//         bytesReceived += data.length;
//         final double progress = bytesReceived / contentLength;
//         _progressController.add(progress);
//
//         raf.writeFromSync(data);
//       },
//       onDone: () {
//         raf.closeSync();
//         httpClient.close();
//       },
//       onError: (error) {
//         print(error);
//         raf.closeSync();
//         httpClient.close();
//       },
//       cancelOnError: true,
//     );
//   }
//
//
//   Future<void> downloadFile({required String url,
//     required int fileSize,
//     int chunkSize = 1024 * 1024}) async {
//     final String dir = await _getDownloadDirectory();
//     final String fileName = url
//         .split('/')
//         .last;
//     final String filePath = '$dir/$fileName';
//
//     if (_httpClients.length >= 5) {
//       // Limit number of active download connections to 5
//       final completer = Completer<void>();
//       _completerMap[url]?.add(completer);
//       await completer.future;
//       return;
//     }
//
//     if (await File(filePath).exists()) {
//       // File already exists, notify completer(s)
//       _completerMap[url]?.forEach((completer) {
//         completer.complete();
//       });
//       _completerMap[url] = [];
//       return;
//     }
//
//     final List<String> hosts = await _getHosts(url);
//     final List<Completer<void>> completers = [];
//
//     for (int i = 0; i < hosts.length; i++) {
//       final int offset = i * chunkSize;
//       final int length = min(chunkSize, fileSize - offset);
//       final String chunkUrl = '$hosts[i]$url';
//       final HttpClient httpClient = HttpClient();
//       final HttpClientRequest request =
//       await httpClient.getUrl(Uri.parse(chunkUrl));
//       request.headers.add('Range', 'bytes=$offset-${offset + length - 1}');
//       final HttpClientResponse response = await request.close();
//       final RandomAccessFile raf = File(filePath).openSync(
//           mode: FileMode.write);
//       raf.setPositionSync(offset);
//
//       _httpClients.add(httpClient);
//       _downloadPaths[chunkUrl] = filePath;
//       _rafMap[chunkUrl] = raf;
//       _bytesReceivedMap[chunkUrl] = offset;
//
//       final completer = Completer<void>();
//       completers.add(completer);
//       _completerMap[chunkUrl] = [completer];
//
//       response.listen(
//               (List<int> data) {
//             final int bytesReceived = _bytesReceivedMap[chunkUrl]!;
//             final double progress = (bytesReceived + data.length) / fileSize;
//             _progressController.add(progress);
//
//             _rafMap[chunkUrl]!.writeFromSync(data);
//             _bytesReceivedMap[chunkUrl] = bytesReceived + data.length;
//           },
//           onDone: () {
//             _rafMap[chunkUrl]!.closeSync();
//           },
//           onError: (error) {
//             print(error);
//             raf.closeSync();
//             httpClient.close();
//           });
//     }
//   }

class DownloadService {
  static const int _chunkSize = (1024 * 8) * (1024 * 8); // 16 MB
  int _progress = 0;

  DownloadService();

  Future<void> downloadFile(String magnetUri, String savePath) async {
    final List<Completer<void>> completerList = [];
    final int contentLength = await _getContentLength(magnetUri);

    // Create directory
    final dir = Directory(savePath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final int numberOfChunks = (contentLength / _chunkSize).ceil();
    final List<Range> ranges = _splitRange(contentLength, numberOfChunks);

    final List<File> downloadedFiles = [];

    await Future.wait(ranges.map((range) async {
      print('Range $range ');
      final completer = Completer<void>();
      completerList.add(completer);
      final dirPath = await _getDownloadDirectory();
      final filePath =
          '$dirPath/${range.start}-${range.end}-${p.basename(magnetUri)}';
      final dir = Directory(filePath).parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await _downloadChunk(
        magnetUri,
        filePath,
        range.start,
        range.end,
        contentLength,
        (count, total) {
          _progress += count;
          final progress = _progress / contentLength * 100;
          print(
              'Download progress: ${progress.toStringAsFixed(2)}  MB ${_progress / 1000000}');
        },
      ).then(
        (value) {
          downloadedFiles.add(File(filePath));
          completer.complete();
        },
      ).catchError((error) => completer.completeError(error));
    }));

    // Verify sequence of downloaded files
    downloadedFiles.sort(
      (a, b) {
        final String filenameA = p.basename(a.path);
        final String filenameB = p.basename(b.path);
        return filenameA.compareTo(filenameB);
      },
    );

    final outputFile = File(savePath);
    await outputFile.writeAsBytes(
      downloadedFiles.expand((f) {
        return f.readAsBytesSync();
      }).toList(growable: false),
    );

    /// Delete all file in download
    downloadedFiles.forEach((element) {
      element.delete();
    });
  }

  Future<String> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // return (await getExternalStorageDirectory())!.path;
      return (await getApplicationDocumentsDirectory()).path;
    } else {
      return (await getDownloadsDirectory())!.path;
    }
  }

  List<Range> _splitRange(int contentLength, int numberOfChunks) {
    final List<Range> ranges = [];
    for (int i = 0; i < numberOfChunks; i++) {
      final start = i * _chunkSize;
      final end = min(start + _chunkSize, contentLength);
      ranges.add(Range(start, end));
    }
    return ranges;
  }

  Future<int> _getContentLength(String magnetUri) async {
    final client = HttpClient();
    final uri = Uri.parse(magnetUri);
    final request = await client.getUrl(uri);
    final response = await request.close();
    final contentLength =
        int.parse(response.headers.value(HttpHeaders.contentLengthHeader)!);
    client.close();
    return contentLength;
  }

  Future<void> _downloadChunk(String magnetUri, String savePath, int start,
      int end, int contentLength, ProgressCallback progressCallback) async {
    final client = HttpClient();
    var request = http.Request('GET', Uri.parse(magnetUri));

    final header = {
      HttpHeaders.rangeHeader: 'bytes=$start-$end',
      'cache-control': 'no-cache',
    };
    request.headers.addAll(header);
    print('headers ${request.headers}');

    final response = await request.send();

    if (response.statusCode == HttpStatus.partialContent) {
      final file = File(savePath);
      final randomAccessFile = await file.open(mode: FileMode.append);
      final completer = Completer();
      print('response ${response.headers}');

      response.stream.listen((List<int> data) async {
        randomAccessFile.writeFromSync(data);
        print('Range Header bytes=$start-$end Filepath $file');
        progressCallback(data.length, end - start + 1);
      }, onDone: () {
        randomAccessFile.closeSync();
        completer.complete();
      }, onError: (error) {
        randomAccessFile.closeSync();
        completer.completeError(error);
      });

      await completer.future;
    } else {
      throw Exception('Failed to download chunk from $magnetUri');
    }

    client.close();
  }
}

class Range {
  final int start;
  final int end;

  Range(this.start, this.end);
}
