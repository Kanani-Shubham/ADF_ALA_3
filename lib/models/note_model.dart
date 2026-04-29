import 'dart:convert';

import 'package:hive/hive.dart';

class NoteModel {
  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.isLocked,
    required this.isFavorite,
    required this.category,
    required this.dateCreated,
    required this.dateUpdated,
    required this.colorIndex,
  });

  final String id;
  final String title;
  final String content;
  final bool isLocked;
  final bool isFavorite;
  final String category;
  final DateTime dateCreated;
  final DateTime dateUpdated;
  final int colorIndex;

  NoteModel copyWith({
    String? title,
    String? content,
    bool? isLocked,
    bool? isFavorite,
    String? category,
    DateTime? dateUpdated,
    int? colorIndex,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      isLocked: isLocked ?? this.isLocked,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      dateCreated: dateCreated,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  String get encodedContent => base64Encode(utf8.encode(content));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': encodedContent,
      'isLocked': isLocked,
      'isFavorite': isFavorite,
      'category': category,
      'dateCreated': dateCreated.toIso8601String(),
      'dateUpdated': dateUpdated.toIso8601String(),
      'colorIndex': colorIndex,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as String? ?? '';
    return NoteModel(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled',
      content: _decodeContent(rawContent),
      isLocked: json['isLocked'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      category: json['category'] as String? ?? 'Personal',
      dateCreated: DateTime.tryParse(json['dateCreated'] as String? ?? '') ?? DateTime.now(),
      dateUpdated: DateTime.tryParse(json['dateUpdated'] as String? ?? '') ?? DateTime.now(),
      colorIndex: json['colorIndex'] as int? ?? 0,
    );
  }

  static String _decodeContent(String value) {
    try {
      return utf8.decode(base64Decode(value));
    } catch (_) {
      return value;
    }
  }
}

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 1;

  @override
  NoteModel read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final fieldCount = reader.readByte();
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return NoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      isLocked: fields[3] as bool,
      isFavorite: fields[4] as bool,
      category: fields[5] as String,
      dateCreated: fields[6] as DateTime,
      dateUpdated: fields[7] as DateTime,
      colorIndex: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.isLocked)
      ..writeByte(4)
      ..write(obj.isFavorite)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.dateCreated)
      ..writeByte(7)
      ..write(obj.dateUpdated)
      ..writeByte(8)
      ..write(obj.colorIndex);
  }
}
