enum DownloadState { notStarted, downloading, completed, pause }

class DownloadNetwork {
  final String fileName;
  final String url;
  final DownloadState state;

  DownloadNetwork({
    required this.fileName,
    required this.url,
    required this.state,
  });
}
