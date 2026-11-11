class VeterinarianModel {
  final String id;
  final String fullName;
  final String specialization;
  final String licenseNumber;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final List<String> scheduleDays;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  VeterinarianModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.licenseNumber,
    this.phone,
    this.photoUrl,
    this.bio,
    this.scheduleDays = const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
    this.startTime = '09:00:00',
    this.endTime = '17:00:00',
    this.isAvailable = true,
  });

  String get formattedHours {
    final s = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final e = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$s - $e';
  }

  factory VeterinarianModel.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['schedule_days'] as List<dynamic>?;
    return VeterinarianModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      scheduleDays: daysRaw?.map((e) => e.toString()).toList() ?? const [],
      startTime: json['start_time'] as String? ?? '09:00:00',
      endTime: json['end_time'] as String? ?? '17:00:00',
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'full_name': fullName,
      'specialization': specialization,
      'license_number': licenseNumber,
      'phone': phone,
      'photo_url': photoUrl,
      'bio': bio,
      'schedule_days': scheduleDays,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };
  }
}
