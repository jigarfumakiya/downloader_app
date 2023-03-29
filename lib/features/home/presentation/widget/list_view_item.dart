import 'package:flutter/material.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 28/03/23
 * @Project: downloader_app
 * list_view_item
 */

class ListViewItem extends StatelessWidget {
  const ListViewItem({Key? key}) : super(key: key);

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
                child: Text('Dummy Download',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.play_arrow),
                label: Text('Start'),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                icon: Icon(Icons.stop_circle),
                label: Text('Stop'),
              ),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(),
          SizedBox(height: 10),
          Divider(
            thickness: 1,
          ),
        ],
      ),
    );
  }
}
