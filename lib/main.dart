import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:downloader_app/core/injeaction/injection_container.dart';
import 'package:downloader_app/core/service/downloader_service/download_service.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:downloader_app/features/home/presentation/widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import 'features/home/data/datasource/local/database/database_util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init();
  await DatabaseUtil.initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<HomeCubit>()),
      ],
      child: ScreenUtilInit(
        builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Downloader',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: child),
        child: const HomeWidget(),
      ),
    );
  }
}

Future<void> downloadChunkInIsolate(DownloadChunkModel model) async {
  final String magnetUri = model.magnetUri;
  final String savePath = model.savePath;
  final Range range = model.range;
  final int contentLength = model.contentLength;
  final SendPort sendPort = model.sendPort;

  var request = http.Request('GET', Uri.parse(magnetUri));

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
        final rangeLength = range.end - range.start + 1;
        final currentProgress = lastProgress + data.length;
        final remainingBytes = rangeLength - currentProgress;
        final percentage = (currentProgress / rangeLength) * 100;
        if (resumedStart > range.end) {
          print('Chunk Downloaded Range ${currentFile.path}');
        }
        randomAccessFile.writeFromSync(data);

        // Send progress update
        sendPort.send({
          'type': 'progress',
          'remainingBytes': remainingBytes,
          'contentLength': contentLength,
          'percentage': percentage,
          'path': currentFile.path
        });

        lastProgress = currentProgress;
      }, onDone: () async {
        print('Chunk Downloaded ${currentFile.path}');
        print('Chunk currentProgress ${currentFile.lengthSync()}');
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
