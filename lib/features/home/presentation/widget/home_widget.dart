import 'dart:io';

import 'package:downloader_app/core/widgets/resposive_layout.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:downloader_app/features/home/presentation/widget/list_view_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key}) : super(key: key);

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  void initState() {
    super.initState();
    if (!Platform.isMacOS) {
      askPermission();
    }
  }

  Future<void> askPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      print('You have storage permssion');
    } else {
      print('You have storage permssion ${status.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<HomeCubit>(context).getDownloads();
    return Scaffold(
      appBar: AppBar(title: Text('File Downloader')),
      floatingActionButton: FloatingActionButton(
        onPressed: onAddDownload,
        child: Icon(Icons.add),
      ),
      body: ResponsiveLayout(
        mobile: _buildHomeBody(),
        macOS: _buildHomeBody(),
        tablet: Container(),
      ),
    );
  }

  Widget _buildHomeBody() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocConsumer<HomeCubit, HomeState>(
        listenWhen: (previous, current) {
          return current is AddDownloadStateFailure;
        },
        listener: (context, state) {
          if (state is AddDownloadStateFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.failureMessage)));
          }
        },
        buildWhen: (previous, current) {
          return current is! AddDownloadStateFailure;
        },
        builder: (context, state) {
          if (state is HomeLoading) {
            return const CircularProgressIndicator();
          } else if (state is HomeFailureState) {
            return Text(state.failureMessage);
          } else if (state is HomeSuccessState) {
            return _buildListView(state.downloads);
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Widget _buildListView(List<DownloadNetwork> downloads) {
    return ListView.builder(
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final item = downloads[index];
        return ListViewItem(
          item: item,
        );
      },
    );
  }

  void onAddDownload() {
    final _urlTextController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => onAddCall(_urlTextController, context),
              child: Text('Add'),
            )
          ],
        );
      },
    );
  }

  void onAddCall(
      TextEditingController urlTextController, BuildContext context) {
    if (urlTextController.text.isEmpty) {
      return;
    }
    final url = urlTextController.text.trim();
    if (Uri.parse(url).isAbsolute) {
      /// Url is valid
      BlocProvider.of<HomeCubit>(context).addDownload(url);
      Navigator.of(context).pop();
    }
  }
}
