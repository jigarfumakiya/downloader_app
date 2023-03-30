import 'package:downloader_app/core/service/downloader_service/download_manager.dart';
import 'package:downloader_app/core/service/notification_service.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:downloader_app/features/home/presentation/widget/list_view_item.dart';
import 'package:flutter/material.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 30/03/23
 * @Project: downloader_app
 * home_list_view
 */

class HomeListView extends StatelessWidget {
  final List<DownloadNetwork> downloads;
  final DownloadManager downloadManager;
  final NotificationService notificationService;

  const HomeListView(
      {Key? key,
      required this.downloads,
      required this.downloadManager,
      required this.notificationService})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final item = downloads[index];
        return ListViewItem(
          item: item,
          notificationService: notificationService,
          downloadManager: downloadManager,
        );
      },
    );
  }
}
