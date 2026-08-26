import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/save_state.dart';

/// Persists the single career save as a JSON file on-device. Real
/// production version would sync this to the backend backup service
/// (spec §2/§4); this skeleton is local-only.
class SaveService {
  static const _fileName = 'career_save.json';

  static Future<File> _saveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<bool> hasSave() async {
    final file = await _saveFile();
    return file.exists();
  }

  static Future<void> save(SaveState state) async {
    final file = await _saveFile();
    await file.writeAsString(jsonEncode(state.toJson()));
  }

  static Future<SaveState?> load() async {
    final file = await _saveFile();
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    return SaveState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> deleteSave() async {
    final file = await _saveFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
