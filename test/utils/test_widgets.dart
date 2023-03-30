import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget wrapWithGoldenWidget(Widget child) {
  return ScreenUtilInit(
    minTextAdapt: true,
    scaleByHeight: true,
    useInheritedMediaQuery: true,
    builder: (context, _) {
      return child;
    },
  );
}

Widget wrapWithMaterial(Widget child) {
  return ScreenUtilInit(
    minTextAdapt: true,
    useInheritedMediaQuery: true,
    builder: (context, _) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Downloader',
        locale: Locale('en'),
        home: Scaffold(body: child),
      );
    },
  );
}
