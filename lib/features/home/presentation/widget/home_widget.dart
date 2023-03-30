import 'dart:io';

import 'package:downloader_app/core/service/downloader_service/download_manager.dart';
import 'package:downloader_app/core/service/notification_service.dart';
import 'package:downloader_app/core/widgets/resposive_layout.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:downloader_app/features/home/presentation/widget/add_downlaod_dialog.dart';
import 'package:downloader_app/features/home/presentation/widget/home_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeWidget extends StatefulWidget {
  final DownloadManager downloadManager;
  final NotificationService notificationService;

  const HomeWidget({
    Key? key,
    required this.downloadManager,
    required this.notificationService,
  }) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(title: Text('File Downloader')),
      floatingActionButton: FloatingActionButton(
        onPressed: onAddDownload,
        child: const Icon(Icons.add),
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
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeFailureState) {
            //Todo make single reusable wide
            return Center(child: Text(state.failureMessage));
          } else if (state is HomeSuccessState) {
            return HomeListView(
              downloads: state.downloads,
              notificationService: widget.notificationService,
              downloadManager: widget.downloadManager,
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Future<void> onAddDownload() async {
    final url = await showDialog(
      context: context,
      builder: (context) {
        return AddDownloadDialog();
      },
    );

    /// If not null mean user has click on add
    if (url != null) {
      onAddCall(url, context);
    }
  }

  void onAddCall(String urlTextController, BuildContext context) {
    final url = urlTextController.trim();
    if (Uri.parse(url).isAbsolute) {
      /// Url is valid
      BlocProvider.of<HomeCubit>(context).addDownload(url);
      Navigator.of(context).pop();
    }
  }
}
