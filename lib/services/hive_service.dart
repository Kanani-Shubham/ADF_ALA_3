import 'package:hive_flutter/hive_flutter.dart';

import '../models/note_model.dart';

class HiveService {
  HiveService._();

  static const String notesBoxName = 'secure_notes_box';
  static Box<NoteModel>? _notesBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    _notesBox = await Hive.openBox<NoteModel>(notesBoxName);
  }

  static Box<NoteModel> get box {
    final openedBox = _notesBox;
    if (openedBox == null || !openedBox.isOpen) {
      throw StateError('HiveService.init() must be called before using notes.');
    }
    return openedBox;
  }

  static List<NoteModel> getAllNotes() {
    return box.values.toList();
  }

  static Future<void> saveNote(NoteModel note) async {
    await box.put(note.id, note);
  }

  static Future<void> deleteNote(String id) async {
    await box.delete(id);
  }

  static Future<void> deleteMany(Iterable<String> ids) async {
    await box.deleteAll(ids);
  }

  static Future<void> replaceAll(List<NoteModel> notes) async {
    await box.clear();
    for (final note in notes) {
      await box.put(note.id, note);
    }
  }
}
