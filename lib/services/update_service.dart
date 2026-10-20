import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model for app update information stored on GitHub or Firestore
class AppUpdateInfo {
  final String version;
  final String url;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;

  AppUpdateInfo({
    required this.version,
    required this.url,
    String? downloadUrl,
    required this.changelog,
    this.forceUpdate = false,
  }) : downloadUrl = (downloadUrl != null && downloadUrl.isNotEmpty) ? downloadUrl : url;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final urlStr = json['url'] as String? ?? '';
    final dlStr = json['downloadUrl'] as String? ?? urlStr;
    return AppUpdateInfo(
      version: json['version'] as String? ?? '',
      url: urlStr,
      downloadUrl: dlStr.isNotEmpty ? dlStr : urlStr,
      changelog: json['changelog'] as String? ?? '',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'url': url,
      'downloadUrl': downloadUrl,
      'changelog': changelog,
      'forceUpdate': forceUpdate,
    };
  }
}

/// Service to fetch and check app updates directly from GitHub or Firestore
class UpdateService {
  /// Default GitHub Raw URL for update.json
  static const String defaultGithubUrl =
      'https://raw.githubusercontent.com/Gt2433/TUSSI/main/update.json';

  /// Fetch the latest update details (GitHub first, then Firestore fallback)
  static Future<AppUpdateInfo?> checkAppUpdate({String? customUrl}) async {
    // 1. Check GitHub raw update.json
    final targetUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : defaultGithubUrl;

    try {
      final response = await http
          .get(Uri.parse(targetUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final info = AppUpdateInfo.fromJson(data);
        if (info.version.isNotEmpty) {
          return info;
        }
      }
    } catch (e) {
      debugPrint('GitHub update check note: $e');
    }

    // 2. Hybrid fallback: Check Firestore app_updates/latest for legacy compatibility
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_updates')
          .doc('latest')
          .get();
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final version = data['version'] as String? ?? '';
        final url = data['url'] as String? ?? '';
        final changelog = data['changelog'] as String? ?? '';
        if (version.isNotEmpty && url.isNotEmpty) {
          return AppUpdateInfo(
            version: version,
            url: url,
            downloadUrl: url,
            changelog: changelog,
            forceUpdate: data['forceUpdate'] as bool? ?? false,
          );
        }
      }
    } catch (e) {
      debugPrint('Firestore update check note: $e');
    }

    return null;
  }

  /// Alias for backward compatibility
  static Future<AppUpdateInfo?> checkGithubUpdate({String? customUrl}) =>
      checkAppUpdate(customUrl: customUrl);
}
