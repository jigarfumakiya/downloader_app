import 'dart:async';
import 'dart:io';

import 'package:downloader_app/core/injeaction/injection_container.dart';
import 'package:downloader_app/core/service/downloader_service/download_manager.dart';
import 'package:downloader_app/core/service/notification_service.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 28/03/23
 * @Project: downloader_app
 * list_view_item
 */
final downloadManager = sl<DownloadManager>();
final notificationService = sl<NotificationService>();

class ListViewItem extends StatefulWidget {
  final DownloadNetwork item;

  ListViewItem({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<ListViewItem> createState() => _ListViewItemState();
}

class _ListViewItemState extends State<ListViewItem> {
  double progress = 0.0;
  String downloadId = '';
  late StreamController<double> _progressStreamController;
  bool isFileDownloaded = false;

  @override
  void initState() {
    super.initState();
    _progressStreamController = StreamController<double>();
    checkIfFileDownloaded();
  }

  @override
  void dispose() {
    _progressStreamController.close();
    super.dispose();
  }

  Future<void> checkIfFileDownloaded() async {
    final fileName = p.basename(widget.item.url);
    final path = await _getDownloadDirectory();
    final fullPath = '$path/$fileName';

    /// Checks if a file has already been downloaded at the specified [savePath].
    final file = File(fullPath);
    return file.exists().then((value) {
      if (mounted) {
        setState(() {
          isFileDownloaded = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.item.fileName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<double>(
            stream: _progressStreamController.stream,
            initialData: 0.0,
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: isFileDownloaded ? 100 : snapshot.data,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 10),
                  downloadState(widget.item)
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget downloadState(DownloadNetwork item) {
    if (downloadId != '') {
      final state = downloadManager.getDownloadState(downloadId);
      switch (state) {
        case DownloadState.notStarted:
          return TextButton.icon(
            onPressed: () => onStart(widget.item),
            icon: Icon(Icons.play_arrow),
            label: Text('Start'),
          );
        case DownloadState.downloading:
          return TextButton.icon(
            onPressed: onPause,
            icon: Icon(Icons.pause),
            label: Text('Pause'),
          );
          break;
        case DownloadState.completed:
          return TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.check_circle),
            label: Text('Completed'),
          );

        case DownloadState.pause:
          return TextButton.icon(
            onPressed: onResume,
            icon: Icon(Icons.play_arrow),
            label: Text('Resume'),
          );
      }
    } else {
      if (isFileDownloaded)
        return TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.check_circle),
          label: Text('Completed'),
        );
      else
        return TextButton.icon(
          onPressed: () => onStart(widget.item),
          icon: Icon(Icons.play_arrow),
          label: Text('Start'),
        );
    }
  }

  /// class methods

  Future<void> onStart(DownloadNetwork item) async {
    try {
      final fileName = p.basename(item.url);
      final path = await _getDownloadDirectory();
      final fullPath = '$path/$fileName';
      print(fullPath);

      downloadId = await downloadManager.addDownload(
        item.url,
        fullPath,
        progressCallback: (current, totalBytes, percentage) {
          _progressStreamController.sink.add(percentage / 100);
        },
        doneCallback: (filepath) {
          onDone(item);
        },
        errorCallback: (error) {
          print(error);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
      print('downloadId $downloadId');
    } catch (e) {
      print('widget called');
      print(e);
    }
  }

  void onResume() {
    downloadManager.resumeDownload(downloadId);
  }

  void onPause() {
    downloadManager.pauseDownload(downloadId);
  }

  void onDone(DownloadNetwork item) {
    if (mounted) {
      setState(() {});
    }
    print('file is downloaded');
    notificationService.showNotification(
        item.fileName, 'Download complete: ${item.fileName}');
    BlocProvider.of<HomeCubit>(context);
  }

  Future<String> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return (await getApplicationDocumentsDirectory()).path;
    } else {
      return (await getDownloadsDirectory())!.path;
    }
  }
}
