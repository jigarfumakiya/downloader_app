import 'package:downloader_app/features/home/presentation/widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) => MaterialApp(
          title: 'Downloader',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: child),
      child: const HomeWidget(),
    );
  }
}
