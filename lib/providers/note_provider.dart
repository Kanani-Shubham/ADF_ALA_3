import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/note_model.dart';
import '../services/hive_service.dart';
import '../services/pin_service.dart';

enum SortMode { updated, title, created }

class NoteProvider extends ChangeNotifier {
  final List<NoteModel> _notes = [];
  final Set<String> _selectedIds = {};

  String _query = '';
  String _category = 'All';
  SortMode _sortMode = SortMode.updated;
  bool _favoritesOnly = false;
  bool _darkMode = false;
  bool _appLockEnabled = false;

  List<NoteModel> get notes => List.unmodifiable(_notes);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  String get query => _query;
  String get category => _category;
  SortMode get sortMode => _sortMode;
  bool get favoritesOnly => _favoritesOnly;
  bool get darkMode => _darkMode;
  bool get appLockEnabled => _appLockEnabled;
  bool get isSelecting => _selectedIds.isNotEmpty;

  List<String> get categories {
    final values = _notes.map((note) => note.category).toSet().toList()..sort();
    return ['All', ...values];
  }

  List<NoteModel> get filteredNotes {
    final lowerQuery = _query.trim().toLowerCase();
    final filtered = _notes.where((note) {
      final matchesCategory = _category == 'All' || note.category == _category;
      final matchesFavorite = !_favoritesOnly || note.isFavorite;
      final searchSpace = '${note.title} ${note.isLocked ? '' : note.content} ${note.category}'.toLowerCase();
      final matchesSearch = lowerQuery.isEmpty || searchSpace.contains(lowerQuery);
      return matchesCategory && matchesFavorite && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case SortMode.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortMode.created:
          return b.dateCreated.compareTo(a.dateCreated);
        case SortMode.updated:
          return b.dateUpdated.compareTo(a.dateUpdated);
      }
    });
    return filtered;
  }

  Future<void> load() async {
    _notes
      ..clear()
      ..addAll(HiveService.getAllNotes());
    _appLockEnabled = await PinService.isAppLockEnabled();
    notifyListeners();
  }

  Future<void> addNote({
    required String title,
    required String content,
    required bool isLocked,
    required String category,
    required int colorIndex,
  }) async {
    final now = DateTime.now();
    final note = NoteModel(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Untitled note' : title.trim(),
      content: content.trim(),
      isLocked: isLocked,
      isFavorite: false,
      category: category.trim().isEmpty ? 'Personal' : category.trim(),
      dateCreated: now,
      dateUpdated: now,
      colorIndex: colorIndex,
    );
    _notes.add(note);
    await HiveService.saveNote(note);
    notifyListeners();
  }

  Future<void> updateNote(NoteModel note) async {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index == -1) return;
    final updated = note.copyWith(dateUpdated: DateTime.now());
    _notes[index] = updated;
    await HiveService.saveNote(updated);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
    _selectedIds.remove(id);
    await HiveService.deleteNote(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    final ids = _selectedIds.toList();
    _notes.removeWhere((note) => _selectedIds.contains(note.id));
    _selectedIds.clear();
    await HiveService.deleteMany(ids);
    notifyListeners();
  }

  Future<void> toggleFavorite(NoteModel note) async {
    await updateNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setSortMode(SortMode value) {
    _sortMode = value;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool value) async {
    _appLockEnabled = value;
    await PinService.setAppLockEnabled(value);
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  String exportJson() {
    final payload = {
      'app': 'Secure Notes Pro',
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': _notes.map((note) => note.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<int> importJson(String jsonText) async {
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final items = decoded['notes'] as List<dynamic>? ?? [];
    final imported = items
        .whereType<Map<String, dynamic>>()
        .map(NoteModel.fromJson)
        .toList();
    if (imported.isEmpty) return 0;

    final byId = {for (final note in _notes) note.id: note};
    for (final note in imported) {
      byId[note.id] = note;
    }
    _notes
      ..clear()
      ..addAll(byId.values);

    await HiveService.replaceAll(_notes);
    notifyListeners();
    return imported.length;
  }
}
