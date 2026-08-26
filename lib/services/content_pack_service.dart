import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/club.dart';
import '../sim/sim_config.dart';

/// Loads a versioned content pack (world data + sim tunables) — see
/// spec §4. In production this fetches from a CDN and caches locally;
/// this skeleton loads the bundled asset directly for simplicity.
class ContentPack {
  final String version;
  final String season;
  final List<Club> clubs;
  final SimConfig simConfig;

  const ContentPack({
    required this.version,
    required this.season,
    required this.clubs,
    required this.simConfig,
  });

  factory ContentPack.fromJson(Map<String, dynamic> json) {
    return ContentPack(
      version: json['version'] as String,
      season: json['season'] as String,
      clubs: (json['clubs'] as List<dynamic>)
          .map((c) => Club.fromJson(c as Map<String, dynamic>))
          .toList(),
      simConfig: SimConfig.fromJson(
        json['sim_config'] as Map<String, dynamic>,
      ),
    );
  }

  Club clubById(String id) => clubs.firstWhere((c) => c.id == id);
}

class ContentPackService {
  static Future<ContentPack> loadBundled(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ContentPack.fromJson(json);
  }
}
