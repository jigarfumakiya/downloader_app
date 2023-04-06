import 'dart:async';
import 'dart:io';

import 'package:downloader_app/core/service/downloader_service/download_manager.dart';
import 'package:downloader_app/core/service/notification_service.dart';
import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 28/03/23
 * @Project: downloader_app
 * list_view_item
 */

/// A widget that displays a single item in a ListView of downloads.
class ListViewItem extends StatefulWidget {
  final DownloadManager downloadManager;
  final NotificationService notificationService;
  final DownloadNetwork item;

  ListViewItem({
    Key? key,
    required this.item,
    required this.downloadManager,
    required this.notificationService,
  }) : super(key: key);

  @override
  State<ListViewItem> createState() => _ListViewItemState();
}

class _ListViewItemState extends State<ListViewItem> {
  String downloadId = '';

  File? downloadFile;
  late DownloadState _downloadState;
  late ValueNotifier<double> _progressNotifier;

  @override
  void initState() {
    super.initState();
    // Initialize the download state to 'not started', and the progress notifier to 0.

    _downloadState = DownloadState.notStarted;
    _progressNotifier = ValueNotifier<double>(0);
    // Check if the file has already been downloaded.

    checkIfFileDownloaded();
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }

  /// Checks if the file has already been downloaded and sets the downloadFile and
  /// downloadState accordingly.
  Future<void> checkIfFileDownloaded() async {
    final fileName = p.basename(widget.item.url);
    final path = await _getDownloadDirectory();
    final fullPath = '$path/$fileName';

    /// Checks if a file has already been downloaded at the specified [savePath].
    final file = File(fullPath);
    return file.exists().then((value) {
      if (mounted && value) {
        setState(() {
          downloadFile = file;
          _downloadState = DownloadState.completed;
          _progressNotifier.value = 100;
        });
        print('downladed file path $downloadFile');
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
          ValueListenableBuilder(
            valueListenable: _progressNotifier,
            builder: (context, value, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: downloadFile != null ? 100 : value,
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
    switch (_downloadState) {
      case DownloadState.notStarted:
        return TextButton.icon(
          onPressed: () => onStart(widget.item),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
        );
      case DownloadState.downloading:
        return TextButton.icon(
          onPressed: onPause,
          icon: const Icon(Icons.pause),
          label: const Text('Pause'),
        );
        break;
      case DownloadState.completed:

        /// This edge condition if user delete the download file then change the widget
        if (downloadFile != null) {
          return downlaodedWidget();
        } else {
          return TextButton.icon(
            onPressed: () => onStart(widget.item),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          );
        }

      case DownloadState.pause:
        return TextButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Resume'),
        );
    }
  }

  Widget downlaodedWidget() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.check_circle),
          label: const Text('Completed'),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
          style: TextButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          label: const Text('Delete'),
        ),
      ],
    );
  }

  /// class methods

  Future<void> onStart(DownloadNetwork item) async {
    if (!(await isInternetAvailable())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please connect to internet')));
      return;
    }
    try {
      final fileName = p.basename(item.url);
      final path = await _getDownloadDirectory();
      final fullPath = '$path/$fileName';
      print(fullPath);

      downloadId = await widget.downloadManager.addDownload(
        item.url,
        fullPath,
        progressCallback: (current, totalBytes, percentage) {
          _progressNotifier.value = percentage / 100;
          print('current $current');
          print('totalBytes $totalBytes');
          print('percentage $percentage');
        },
        doneCallback: (filepath) {
          downloadFile = File(filepath);
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
    _downloadState = DownloadState.downloading;
    setState(() {});
  }

  Future<void> onResume() async {
    if (!(await isInternetAvailable())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please connect to internet')));
      return;
    }
    _downloadState = DownloadState.downloading;
    widget.downloadManager.resumeDownload(downloadId);
    setState(() {});
  }

  void onPause() {
    widget.downloadManager.pauseDownload(downloadId);
    _downloadState = DownloadState.pause;
    setState(() {});
  }

  Future<void> onDelete() async {
    // To our current logic will show delete only when file is downloaded
    if (downloadFile != null) {
      await downloadFile!.delete();
      _progressNotifier.value = 0.0;
      setState(() {
        downloadFile = null;
      });
      return;
    }
    print('No File found');
  }

  void onDone(DownloadNetwork item) {
    _downloadState = DownloadState.completed;
    if (mounted) {
      setState(() {});
    }
    print('file is downloaded');
    widget.notificationService
        .showNotification(item.fileName, 'Download complete: ${item.fileName}');
  }

  Future<String> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return (await getApplicationDocumentsDirectory()).path;
    } else {
      return (await getDownloadsDirectory())!.path;
    }
  }

  Future<bool> isInternetAvailable() async {
    bool hasDataAvailable = await InternetConnectionChecker().hasConnection;
    return hasDataAvailable;
  }
}
