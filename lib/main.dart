import 'dart:async';

import 'package:downloader_app/core/injeaction/injection_container.dart';
import 'package:downloader_app/core/service/notification_service.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:downloader_app/features/home/presentation/widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'features/home/data/datasource/local/database/database_util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init();
  await sl<NotificationService>().initNotification();
  await DatabaseUtil.initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<HomeCubit>()),
      ],
      child: ScreenUtilInit(
        builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Downloader',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: child),
        child: const HomeWidget(),
      ),
    );
  }
}
