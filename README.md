# Downloader App

#### The Downloader App is a Dart-based application that handles downloading large files in chunks using isolates. The application supports pausing and resuming the download, and provides progress updates throughout the download process.

## Features

* Download large files in chunks
* Pause and resume downloads
* Track progress during download
* Manage download tasks using isolates

## Usage
#### Here is an example of how to use the Downloader App:


```dart
 final downloadId = await downloadManager.addDownload(
      Paste URL here,
      full/path/to/file,
      progressCallback: (remainBytes, totalBytes, percentage) {
        print('Remain Bytes $remainBytes ');
         print('Total Bytes $totalBytes ');
         print('percentage $percentage ');
      },
      doneCallback: (filepath) {
        setState(() {});
      },
      errorCallback: (error) {
        print('on error called');
      },
    );
    print('downloadId $downloadId');
```

