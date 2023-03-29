import 'package:downloader_app/features/home/data/datasource/local/database/table/download_table.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:flutter/material.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 28/03/23
 * @Project: downloader_app
 * list_view_item
 */

class ListViewItem extends StatelessWidget {
  final DownloadNetwork item;

  const ListViewItem({
    Key? key,
    required this.item,
  }) : super(key: key);

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
              const Expanded(
                child: Text('Dummy Download',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              if (item.state == DownloadState.notStarted)
                TextButton.icon(
                  onPressed: onStart,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start'),
                ),
              const SizedBox(width: 10),
              if (item.state == DownloadState.downloading) ...{
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.pause),
                  label: Text('Pause'),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Stop'),
                ),
              }
            ],
          ),
          const SizedBox(height: 10),
          const LinearProgressIndicator(
            value: 0,
            minHeight: 10,
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 1),
        ],
      ),
    );
  }


  /// class methods

  void onStart(){

  }


}
