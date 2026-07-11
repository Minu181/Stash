import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String changelog;
  final String downloadUrl;
  final int downloadSize;

  UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.downloadSize,
  });
}

class UpdateService {
  static const _owner = 'Minu181';
  static const _repo = 'Stash';
  static const _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static Future<UpdateInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst('v', '');

      if (latestVersion.isEmpty) return null;

      final body = json['body'] as String? ?? 'No changelog available.';

      final assets = json['assets'] as List<dynamic>? ?? [];
      String? downloadUrl;
      int downloadSize = 0;

      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String?;
          downloadSize = asset['size'] as int? ?? 0;
          break;
        }
      }

      if (downloadUrl == null) return null;

      return UpdateInfo(
        version: latestVersion,
        changelog: body,
        downloadUrl: downloadUrl,
        downloadSize: downloadSize,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isNewerVersion(String latestVersion) async {
    final current = await _getCurrentVersion();
    return _compareVersions(latestVersion, current) > 0;
  }

  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal.compareTo(bVal);
    }
    return 0;
  }

  static Future<String> downloadUpdate(
    String url,
    void Function(double progress, int received, int total)? onProgress,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/stash_update.apk';

    final dio = Dio();
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (onProgress != null && total > 0) {
          onProgress(received / total, received, total);
        }
      },
    );

    return filePath;
  }

  static Future<void> installApk(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Could not open APK: ${result.message}');
    }
  }
}
