import 'dart:io';

import 'package:downloader_app/core/service/downloader_service/download_service.dart';
import 'package:downloader_app/features/home/data/models/home_network.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:downloader_app/features/home/presentation/widget/list_view_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    askPermission();
  }

  Future<void> askPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      print('You have storage permssion');
    } else {
      print('You have storage permssion ${status.toString()}');
    }
  }

  Future<String> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // return (await getExternalStorageDirectory())!.path;
      return (await getApplicationDocumentsDirectory()).path;
    } else {
      return (await getDownloadsDirectory())!.path;
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
      body: _buildHomeBody(),
    );
  }

  Widget _buildHomeBody() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocBuilder<HomeCubit, HomeState>(
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              TextField(
                decoration: InputDecoration(hintText: 'Paste URL'),
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
              onPressed: () {

              },
              child: Text('Add'),
            )
          ],
        );
      },
    );
  }

  Future<void> onDownloadTap() async {
    // // const url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
    // const url = "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-MP4-Video-File-Download.mp4"; // 50 MB
    const url =
        "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"; // 50 MB
    // const url = "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-MP4-Video-File-for-Testing.mp4";
    // const url = "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-Video-File-For-Testing.mp4"; //95 MB
    // const url = "https://file-examples.com/wp-content/uploads/2017/10/file-example_PDF_1MB.pdf"; //95 MB
    // const url = "https://file-examples.com/wp-content/uploads/2017/10/file_example_JPG_2500kB.jpg"; //Image
    // const url = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_5MG.mp3"; //Audio
    // const url = "https://filesamples.com/samples/video/mp4/sample_3840x2160.mp4"; //Video
    final fileName = p.basename(url);
    final path = await _getDownloadDirectory();
    final fullPath = '$path/$fileName';
    print(fullPath);

    DownloadService().downloadFile(url, fullPath);
  }
}
