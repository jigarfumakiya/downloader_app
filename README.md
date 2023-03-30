# Downloader App
#### The Downloader App is a Dart-based application that handles downloading large files in chunks using isolates. The application supports pausing and resuming the download, and provides progress updates throughout the download process.

## 🎉 Features included:

- [x] Download large files in chunks
- [x] Pause and resume downloads
- [x] Pause and resume downloads
- [x] Track progress during download
- [x] **Clean Architecture**
    - [x] Unit Test
    - [x] Widget/Golden Test
    - [x] Integration/Automated
- [x] Internet Checking


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


## 📹 Here is the demo

https://user-images.githubusercontent.com/11865669/228920560-2725c031-73b9-4772-be5a-647432aa52f3.mp4




## 🧪 Testing

### Widget/Golden Test
The app also has widget tests that test the UI of the app [Here](https://github.com/jigarfumakiya/downloader_app/tree/main/test/features/home/presentation/widget) 


### Integration/Automated Test
The app has integration/automated tests that test the interaction of different parts of the app  [Here](https://github.com/jigarfumakiya/downloader_app/tree/main/integration_test)




