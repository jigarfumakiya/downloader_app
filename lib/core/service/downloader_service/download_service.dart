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
        print('Chunk Downloaded');
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
