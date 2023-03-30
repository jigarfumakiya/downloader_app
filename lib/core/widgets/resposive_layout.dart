/**
 * @Author: Jigar Fumakiya
 * @Date: 30/03/23
 * @Project: downloader_app
 * resposive_layout
 */

import 'dart:io' show Platform;

import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget macOS;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    required this.tablet,
    required this.macOS,
  }) : super(key: key);

  /// This size work fine on my design, maybe you need some customization depends on your design
  /// This isMobile, isTablet, isDesktop helep us later
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 500;

  static bool isMacos() => Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      /// If our width is more than 1100 then we consider it a desktop
      builder: (context, constraints) {
        if (isMacos()) {
          return macOS;
        }

        /// If width it less then 1100 and more then 650 we consider it as tablet
        else if (constraints.maxWidth >= 600) {
          return tablet;
        }

        /// Or less then that we called it mobile
        else {
          return mobile;
        }
      },
    );
  }
}
