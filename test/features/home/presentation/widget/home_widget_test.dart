import 'dart:developer';

import 'package:bloc_test/bloc_test.dart';
import 'package:downloader_app/core/injeaction/injection_container.dart';
import 'package:downloader_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:downloader_app/features/home/presentation/widget/home_list_view.dart';
import 'package:downloader_app/features/home/presentation/widget/home_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

// ignore: depend_on_referenced_packages
import 'package:mocktail/mocktail.dart';

import '../../../../utils/fixtures.dart';
import '../../../../utils/test.mock.mocks.dart';
import '../../../../utils/test_widgets.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  late MockHomeCubit mockTopicCubit;
  late MockDownloadManager mockDownloadManager;
  late MockNotificationService mockNotificationService;

  setUp(() async {
    /// It imports the necessary dependencies, initializes the dependency injection container,
    await init(isMock: true);
    mockTopicCubit = MockHomeCubit();
    mockDownloadManager = MockDownloadManager();
    mockNotificationService = MockNotificationService();

    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance?.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log('methods called');
      if (methodCall.method == 'getDownloadsDirectory') {
        return '/mock/download/directory';
      }
    });
  });

  group('Render Home Page Goldans', () {
    final downloadList = sampleTestDownloadList;

    testGoldens('Should show listview when data is loaded ',
        (widgetTester) async {
      final widget = BlocProvider<HomeCubit>(
        create: (context) => mockTopicCubit,
        child: wrapWithGoldenWidget(HomeWidget(
          downloadManager: mockDownloadManager,
          notificationService: mockNotificationService,
        )),
      );

      when(() => mockTopicCubit.state)
          .thenReturn(HomeSuccessState(downloadList));

      final builder = DeviceBuilder();
      builder.overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11]);

      builder.addScenario(
        widget: widget,
        onCreate: (scenarioWidgetKey) async {
          final finder = find.descendant(
            of: find.byKey(scenarioWidgetKey),
            matching: find.byType(HomeListView),
          );
          expect(finder, findsOneWidget);
        },
      );

      await widgetTester.pumpDeviceBuilder(builder);

      await widgetTester.pump(const Duration(seconds: 1));

      await screenMatchesGolden(widgetTester, 'home_screen_success');
    });
  });
}
