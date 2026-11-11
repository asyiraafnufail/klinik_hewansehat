enum AppointmentStatus {
  pending('pending', 'Menunggu'),
  confirmed('confirmed', 'Dikonfirmasi'),
  completed('completed', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan');

  final String value;
  final String label;
  const AppointmentStatus(this.value, this.label);

  static AppointmentStatus fromString(String? val) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AppointmentStatus.pending,
    );
  }
}

class AppointmentModel {
  final String id;
  final String petId;
  final String ownerId;
  final String? vetId;
  final String? serviceId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final AppointmentStatus status;
  final String reason;
  final String? cancellationReason;

  // Relasi join dari Supabase
  final String? petName;
  final String? petSpecies;
  final String? ownerName;
  final String? vetName;
  final String? serviceName;
  final double? servicePrice;

  AppointmentModel({
    required this.id,
    required this.petId,
    required this.ownerId,
    this.vetId,
    this.serviceId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    required this.reason,
    this.cancellationReason,
    this.petName,
    this.petSpecies,
    this.ownerName,
    this.vetName,
    this.serviceName,
    this.servicePrice,
  });

  String get formattedTime =>
      appointmentTime.length >= 5 ? appointmentTime.substring(0, 5) : appointmentTime;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final pet = json['pets'] as Map<String, dynamic>?;
    final owner = json['profiles'] as Map<String, dynamic>?;
    final vet = json['veterinarians'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;
    final rawPrice = service?['price'];

    return AppointmentModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      ownerId: json['owner_id'] as String,
      vetId: json['vet_id'] as String?,
      serviceId: json['service_id'] as String?,
      appointmentDate:
          DateTime.tryParse(json['appointment_date'].toString()) ?? DateTime.now(),
      appointmentTime: json['appointment_time'] as String? ?? '09:00:00',
      status: AppointmentStatus.fromString(json['status'] as String?),
      reason: json['reason'] as String? ?? '',
      cancellationReason: json['cancellation_reason'] as String?,
      petName: pet?['name'] as String?,
      petSpecies: pet?['species'] as String?,
      ownerName: owner?['full_name'] as String?,
      vetName: vet?['full_name'] as String?,
      serviceName: service?['name'] as String?,
      servicePrice: rawPrice == null
          ? null
          : (rawPrice is num
              ? rawPrice.toDouble()
              : double.tryParse(rawPrice.toString())),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'pet_id': petId,
      'owner_id': ownerId,
      'vet_id': vetId?.isNotEmpty == true ? vetId : null,
      'service_id': serviceId?.isNotEmpty == true ? serviceId : null,
      'appointment_date': appointmentDate.toIso8601String().split('T').first,
      'appointment_time': appointmentTime,
      'status': status.value,
      'reason': reason.trim(),
      'cancellation_reason':
          cancellationReason?.isNotEmpty == true ? cancellationReason : null,
    };
  }
}
