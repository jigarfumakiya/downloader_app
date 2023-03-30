
// Run
//flutter pub run build_runner build --delete-conflicting-outputs
// For Golden
//flutter test --update-goldens --tags=golden
import 'package:downloader_app/core/service/downloader_service/download_manager.dart';
import 'package:downloader_app/core/service/notification_service.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  NotificationService,
  DownloadManager
])
void main() {}
