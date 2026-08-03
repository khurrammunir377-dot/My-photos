class PersonModel {
  final int? id;
  final String name;
  final String coverPhotoId; // photo_manager AssetEntity id used as the group's thumbnail
  final List<String> photoIds; // AssetEntity ids assigned to this person
  final DateTime createdAt;

  PersonModel({
    this.id,
    required this.name,
    required this.coverPhotoId,
    required this.photoIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coverPhotoId': coverPhotoId,
      'photoIds': photoIds.join(','),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    final idsRaw = map['photoIds'] as String? ?? '';
    return PersonModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      coverPhotoId: map['coverPhotoId'] as String,
      photoIds: idsRaw.isEmpty ? [] : idsRaw.split(','),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  PersonModel copyWith({String? name, List<String>? photoIds}) {
    return PersonModel(
      id: id,
      name: name ?? this.name,
      coverPhotoId: coverPhotoId,
      photoIds: photoIds ?? this.photoIds,
      createdAt: createdAt,
    );
  }
}

/// A single detected face, found during a People scan but not yet assigned
/// to a named person.
class DetectedFace {
  final String assetId; // which photo this face was found in
  final double boundingLeft, boundingTop, boundingWidth, boundingHeight;

  DetectedFace({
    required this.assetId,
    required this.boundingLeft,
    required this.boundingTop,
    required this.boundingWidth,
    required this.boundingHeight,
  });
}
