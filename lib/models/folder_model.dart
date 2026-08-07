class FolderModel {
  final int? id;
  final String name;
  final String albumName; // actual name used in device gallery (prefixed, sanitized)
  final DateTime createdAt;
  final int photoCount;
  final int? parentId; // null = top-level folder, otherwise the id of the parent folder
  final bool isVault; // true = only visible inside the PIN-locked Vault, hidden from the normal folder list

  FolderModel({
    this.id,
    required this.name,
    required this.albumName,
    required this.createdAt,
    this.photoCount = 0,
    this.parentId,
    this.isVault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'albumName': albumName,
      'createdAt': createdAt.toIso8601String(),
      'photoCount': photoCount,
      'parentId': parentId,
      'isVault': isVault ? 1 : 0,
    };
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      albumName: map['albumName'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      photoCount: map['photoCount'] as int? ?? 0,
      parentId: map['parentId'] as int?,
      isVault: (map['isVault'] as int? ?? 0) == 1,
    );
  }

  FolderModel copyWith({int? photoCount}) {
    return FolderModel(
      id: id,
      name: name,
      albumName: albumName,
      createdAt: createdAt,
      photoCount: photoCount ?? this.photoCount,
      parentId: parentId,
      isVault: isVault,
    );
  }
}
