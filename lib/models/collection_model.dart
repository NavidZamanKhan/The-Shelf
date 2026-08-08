import 'package:equatable/equatable.dart';

/// Data model representing a user-created custom collection.
class CollectionModel extends Equatable {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final int itemCount;

  const CollectionModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    this.itemCount = 0,
  });

  CollectionModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
    int? itemCount,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_name': iconName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CollectionModel.fromMap(Map<String, dynamic> map, {int itemCount = 0}) {
    return CollectionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? '#E06D53',
      iconName: map['icon_name'] as String? ?? 'bookmarkSimple',
      createdAt: DateTime.parse(map['created_at'] as String),
      itemCount: itemCount,
    );
  }

  @override
  List<Object?> get props => [id, name, colorHex, iconName, createdAt, itemCount];
}
