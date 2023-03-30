import 'package:flutter/material.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 30/03/23
 * @Project: downloader_app
 * add_downlaod_dialog
 */

class AddDownloadDialog extends StatelessWidget {
  AddDownloadDialog({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormState>();
  final _urlTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add File'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: _urlTextController,
              decoration: InputDecoration(hintText: 'Paste URL'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a valid URL';
                }
                if (!Uri.parse(value).isAbsolute) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_urlTextController);
            }
          },
          child: Text('Add'),
        )
      ],
    );
  }
}
