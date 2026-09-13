import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/data_importer_service.dart';

class DataImportScreen extends StatefulWidget {
  const DataImportScreen({super.key});

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  final _pasteController = TextEditingController();
  String? _error;
  List<String> _warnings = [];
  bool _busy = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import your own data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Bring in real clubs and players instead of the sample data. '
            'Two ways to do it:',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Option A — one JSON file', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'A single file with "countries", "leagues", and "clubs" '
                    'arrays. See the sample schema in the project README.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _pickJsonFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose JSON file'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Option B — two CSV files', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'A clubs.csv (id, name, country_name, league_name, tier, '
                    'reputation, ...) and a players.csv (id, club_id, name, '
                    'position, pace, shooting, ...), joined by club_id.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _pickCsvFiles,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Choose clubs.csv + players.csv'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Or paste JSON directly'),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _pasteController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '{"countries": [...], "leagues": [...], "clubs": [...]}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _busy ? null : _importPastedJson,
                        child: const Text('Import pasted JSON'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            ),
          ],
          if (_warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Imported with warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._warnings.map((w) => Text('• $w')),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickJsonFile() async {
    setState(() {
      _busy = true;
      _error = null;
      _warnings = [];
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final bytes = picked.files.first.bytes;
      if (bytes == null) throw const ImportException('Could not read the file.');
      final raw = utf8.decode(bytes);
      _finishImport(DataImporterService.parseJson(raw));
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e is ImportException ? e.message : 'Import failed: $e';
      });
    }
  }

  Future<void> _pickCsvFiles() async {
    setState(() {
      _busy = true;
      _error = null;
      _warnings = [];
    });
    try {
      final clubsPicked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
        dialogTitle: 'Select clubs.csv',
      );
      if (clubsPicked == null || clubsPicked.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final playersPicked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
        dialogTitle: 'Select players.csv',
      );
      if (playersPicked == null || playersPicked.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final clubsBytes = clubsPicked.files.first.bytes;
      final playersBytes = playersPicked.files.first.bytes;
      if (clubsBytes == null || playersBytes == null) {
        throw const ImportException('Could not read one of the files.');
      }
      _finishImport(DataImporterService.parseCsv(
        clubsCsv: utf8.decode(clubsBytes),
        playersCsv: utf8.decode(playersBytes),
      ));
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e is ImportException ? e.message : 'Import failed: $e';
      });
    }
  }

  void _importPastedJson() {
    setState(() {
      _busy = true;
      _error = null;
      _warnings = [];
    });
    try {
      _finishImport(DataImporterService.parseJson(_pasteController.text));
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e is ImportException ? e.message : 'Import failed: $e';
      });
    }
  }

  void _finishImport(ImportResult result) {
    if (result.warnings.isEmpty) {
      Navigator.of(context).pop(result);
    } else {
      setState(() {
        _busy = false;
        _warnings = result.warnings;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop(result);
      });
    }
  }
}
