import 'package:flutter/material.dart';

import '../../core/authed_http.dart';

class ResourceLink {
  final String title;
  final String description;
  final String url;
  final String? phone;
  final String? phoneLabel;

  ResourceLink({
    required this.title,
    required this.description,
    required this.url,
    this.phone,
    this.phoneLabel,
  });

  factory ResourceLink.fromJson(Map<String, dynamic> json) => ResourceLink(
    title: json['title'],
    description: json['description'],
    url: json['url'],
    phone: json['phone'],
    phoneLabel: json['phoneLabel'],
  );
}

class ResourceGroup {
  final String title;
  final String icon;
  final List<ResourceLink> items;

  ResourceGroup({required this.title, required this.icon, required this.items});

  factory ResourceGroup.fromJson(Map<String, dynamic> json) => ResourceGroup(
    title: json['title'],
    icon: json['icon'],
    items: (json['items'] as List<dynamic>)
        .map((i) => ResourceLink.fromJson(i as Map<String, dynamic>))
        .toList(),
  );

  /// Maps the server's icon key; unknown keys get a generic link icon.
  IconData get iconData => switch (icon) {
    'school' => Icons.school,
    'family' => Icons.family_restroom,
    'benefits' => Icons.card_giftcard,
    'support' => Icons.support_agent,
    'health' => Icons.health_and_safety,
    'work' => Icons.work,
    'search' => Icons.travel_explore,
    _ => Icons.link,
  };
}

List<ResourceGroup> _groups(dynamic json) => (json as List<dynamic>)
    .map((g) => ResourceGroup.fromJson(g as Map<String, dynamic>))
    .toList();

class ResourceDirectory {
  final ResourceLink crisisLine;
  final List<ResourceGroup> newJersey;
  final List<ResourceGroup> national;

  ResourceDirectory({
    required this.crisisLine,
    required this.newJersey,
    required this.national,
  });

  factory ResourceDirectory.fromJson(Map<String, dynamic> json) =>
      ResourceDirectory(
        crisisLine: ResourceLink.fromJson(json['crisisLine']),
        newJersey: _groups(json['newJersey']),
        national: _groups(json['national']),
      );
}

class ResourceApi {
  static Future<ResourceDirectory> fetchResources() async {
    final response = await authedGet('/resources');
    return ResourceDirectory.fromJson(decodeOrThrow(response, 200));
  }

  static Future<List<ResourceGroup>> fetchJobs() async {
    final response = await authedGet('/resources/jobs');
    final body = decodeOrThrow(response, 200) as Map<String, dynamic>;
    return _groups(body['sections']);
  }
}
