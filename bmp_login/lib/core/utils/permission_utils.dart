import 'package:permission_handler/permission_handler.dart';

/// Requests storage permission and returns true if granted.
Future<bool> requestStoragePermission() async {
  final status = await Permission.storage.request();
  return status.isGranted;
}