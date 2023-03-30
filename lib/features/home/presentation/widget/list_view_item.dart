import 'dart:async';
import 'dart:io';

import 'package:downloader_app/core/injeaction/injection_container.dart';
import 'package:downloader_app/core/service/downloader_service/download_manager.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 28/03/23
 * @Project: downloader_app
 * list_view_item
 */
final downloadManager = sl<DownloadManager>();

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

  @override
  void initState() {
    super.initState();
    _progressStreamController = StreamController<double>();
  }

  @override
  void dispose() {
    _progressStreamController.close();
    super.dispose();
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
                    value: snapshot.data,
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
          // final progress = (current / totalBytes) * 100;
          // print('Downloading: $progress');
          _progressStreamController.sink.add(percentage / 100);
          //
        },
        doneCallback: (filepath) {
          setState(() {});
        },
        errorCallback: (error) {
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

  Future<String> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return (await getApplicationDocumentsDirectory()).path;
    } else {
      return (await getDownloadsDirectory())!.path;
    }
  }
}
