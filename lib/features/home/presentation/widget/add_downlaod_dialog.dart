import 'package:flutter/material.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 30/03/23
 * @Project: downloader_app
 * add_downlaod_dialog
 */

class AddDownloadDialog extends StatelessWidget {
  AddDownloadDialog({Key? key}) : super(key: key);
  final _urlTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            controller: _urlTextController,
            decoration: InputDecoration(hintText: 'Paste URL'),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Enter URl';
              }
              if (!Uri.parse(value).isAbsolute) {
                return 'Enter valid download url';
              }
              return null;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_urlTextController),
          child: Text('Add'),
        )
      ],
    );
  }
}
