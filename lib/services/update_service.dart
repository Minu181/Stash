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

      final json = _parseJson(response.body);
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

  static Map<String, dynamic> _parseJson(String text) {
    final result = <String, dynamic>{};
    text = text.trim();

    // Simple JSON parser for GitHub API response
    if (text.startsWith('{')) {
      _parseObject(text, 0, result);
    }
    return result;
  }

  static int _parseObject(String text, int pos, Map<String, dynamic> result) {
    pos++; // skip {
    while (pos < text.length && text[pos] != '}') {
      while (pos < text.length && (text[pos] == ',' || text[pos] == ' ' || text[pos] == '\n' || text[pos] == '\r')) pos++;
      if (text[pos] == '}') break;

      // Parse key
      pos++; // skip "
      final keyStart = pos;
      while (pos < text.length && text[pos] != '"') {
        if (text[pos] == '\\') pos++;
        pos++;
      }
      final key = text.substring(keyStart, pos);
      pos++; // skip "

      while (pos < text.length && text[pos] != ':') pos++;
      pos++; // skip :

      // Parse value
      while (pos < text.length && text[pos] == ' ') pos++;
      if (text[pos] == '"') {
        pos++; // skip "
        final valStart = pos;
        while (pos < text.length && text[pos] != '"') {
          if (text[pos] == '\\') pos++;
          pos++;
        }
        result[key] = text.substring(valStart, pos);
        pos++; // skip "
      } else if (text[pos] == '{') {
        final inner = <String, dynamic>{};
        pos = _parseObject(text, pos, inner);
        result[key] = inner;
      } else if (text[pos] == '[') {
        pos = _parseArray(text, pos, result, key);
      } else {
        final valStart = pos;
        while (pos < text.length && text[pos] != ',' && text[pos] != '}' && text[pos] != ' ') pos++;
        final val = text.substring(valStart, pos);
        if (val == 'true') {
          result[key] = true;
        } else if (val == 'false') {
          result[key] = false;
        } else if (val == 'null') {
          result[key] = null;
        } else {
          result[key] = val;
        }
      }
    }
    return pos + 1;
  }

  static int _parseArray(String text, int pos, Map<String, dynamic> parent, String key) {
    final list = <dynamic>[];
    pos++; // skip [
    while (pos < text.length && text[pos] != ']') {
      while (pos < text.length && (text[pos] == ',' || text[pos] == ' ' || text[pos] == '\n')) pos++;
      if (text[pos] == ']') break;

      if (text[pos] == '"') {
        pos++;
        final valStart = pos;
        while (pos < text.length && text[pos] != '"') {
          if (text[pos] == '\\') pos++;
          pos++;
        }
        list.add(text.substring(valStart, pos));
        pos++;
      } else if (text[pos] == '{') {
        final inner = <String, dynamic>{};
        pos = _parseObject(text, pos, inner);
        list.add(inner);
      } else {
        final valStart = pos;
        while (pos < text.length && text[pos] != ',' && text[pos] != ']') pos++;
        list.add(text.substring(valStart, pos));
      }
    }
    parent[key] = list;
    return pos + 1;
  }
}
