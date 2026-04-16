import 'dart:io';

class AppConfigModel {
  final PlatformConfig platform;
  final MaintenanceConfig maintenance;
  final Map<String, bool> featureFlags;
  final AnnouncementConfig announcement;

  AppConfigModel({
    required this.platform,
    required this.maintenance,
    required this.featureFlags,
    required this.announcement,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final platformKey = Platform.isIOS ? 'ios' : 'android';
    final platformJson = json[platformKey] as Map<String, dynamic>? ?? {};
    final maintenanceJson = json['maintenance'] as Map<String, dynamic>? ?? {};
    final flagsJson = json['feature_flags'] as Map<String, dynamic>? ?? {};
    final announcementJson = json['announcement'] as Map<String, dynamic>? ?? {};

    return AppConfigModel(
      platform: PlatformConfig.fromJson(platformJson),
      maintenance: MaintenanceConfig.fromJson(maintenanceJson),
      featureFlags: flagsJson.map((k, v) => MapEntry(k, v == true)),
      announcement: AnnouncementConfig.fromJson(announcementJson),
    );
  }

  /// Safe defaults — used when API fails or no config
  factory AppConfigModel.defaults() {
    return AppConfigModel(
      platform: PlatformConfig(
        latestVersion: '1.0.0',
        minSupportedVersion: '1.0.0',
        forceUpdate: false,
        updateMessage: '',
        storeUrl: '',
      ),
      maintenance: MaintenanceConfig(isActive: false, message: '', estimatedEnd: null),
      featureFlags: {
        'chat_enabled': true,
        'boost_enabled': true,
        'payments_enabled': true,
        'google_auth_enabled': true,
        'free_listing_enabled': true,
      },
      announcement: AnnouncementConfig(isActive: false),
    );
  }
}

class PlatformConfig {
  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String updateMessage;
  final String storeUrl;

  PlatformConfig({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.updateMessage,
    required this.storeUrl,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      minSupportedVersion: json['min_supported_version']?.toString() ?? '1.0.0',
      forceUpdate: json['force_update'] == true,
      updateMessage: json['update_message']?.toString() ?? '',
      storeUrl: json['store_url']?.toString() ?? '',
    );
  }
}

class MaintenanceConfig {
  final bool isActive;
  final String message;
  final DateTime? estimatedEnd;

  MaintenanceConfig({required this.isActive, required this.message, this.estimatedEnd});

  factory MaintenanceConfig.fromJson(Map<String, dynamic> json) {
    return MaintenanceConfig(
      isActive: json['is_active'] == true,
      message: json['message']?.toString() ?? 'We are under maintenance. Please try again later.',
      estimatedEnd: json['estimated_end'] != null ? DateTime.tryParse(json['estimated_end'].toString()) : null,
    );
  }
}

class AnnouncementConfig {
  final bool isActive;
  final String? title;
  final String? message;
  final String? imageUrl;
  final String? actionUrl;
  final String? dismissKey;

  AnnouncementConfig({
    required this.isActive,
    this.title,
    this.message,
    this.imageUrl,
    this.actionUrl,
    this.dismissKey,
  });

  factory AnnouncementConfig.fromJson(Map<String, dynamic> json) {
    return AnnouncementConfig(
      isActive: json['is_active'] == true,
      title: json['title'],
      message: json['message'],
      imageUrl: json['image_url'],
      actionUrl: json['action_url'],
      dismissKey: json['dismiss_key'],
    );
  }
}
