import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model for app update information stored on GitHub
class AppUpdateInfo {
  final String version;
  final String url;
  final String changelog;
  final bool forceUpdate;

  AppUpdateInfo({
    required this.version,
    required this.url,
    required this.changelog,
    this.forceUpdate = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String? ?? '',
      url: json['url'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'url': url,
      'changelog': changelog,
      'forceUpdate': forceUpdate,
    };
  }
}

/// Service to fetch and check app updates directly from a GitHub repository JSON file
class UpdateService {
  /// Default GitHub Raw URL for update.json
  static const String defaultGithubUrl =
      'https://raw.githubusercontent.com/Gt2433/TUSSI/main/update.json';

  /// Fetch the latest update details from GitHub
  static Future<AppUpdateInfo?> checkGithubUpdate({String? customUrl}) async {
    final targetUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : defaultGithubUrl;

    try {
      final response = await http
          .get(Uri.parse(targetUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AppUpdateInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching update from GitHub ($targetUrl): $e');
    }
    return null;
  }
}
