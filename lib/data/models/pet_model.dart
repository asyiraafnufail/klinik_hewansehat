class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final DateTime? birthDate;
  final double? weightKg;
  final String? photoUrl;
  final String? notes;
  final String? ownerName;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.birthDate,
    this.weightKg,
    this.photoUrl,
    this.notes,
    this.ownerName,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    final profileMap = json['profiles'] as Map<String, dynamic>?;
    final rawWeight = json['weight_kg'];
    return PetModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      breed: json['breed'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'].toString())
          : null,
      weightKg: rawWeight == null
          ? null
          : (rawWeight is num
              ? rawWeight.toDouble()
              : double.tryParse(rawWeight.toString())),
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      ownerName: profileMap?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'owner_id': ownerId,
      'name': name.trim(),
      'species': species.trim(),
      'breed': breed?.trim().isNotEmpty == true ? breed!.trim() : null,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'weight_kg': weightKg,
      'photo_url': photoUrl?.trim().isNotEmpty == true ? photoUrl!.trim() : null,
      'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
    };
  }
}
