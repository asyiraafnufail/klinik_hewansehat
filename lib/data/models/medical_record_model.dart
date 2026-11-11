class MedicalRecordModel {
  final String id;
  final String? appointmentId;
  final String petId;
  final String? vetId;
  final String diagnosis;
  final String treatment;
  final String? prescription;
  final String? clinicalNotes;
  final DateTime recordDate;

  // Relasi join dari Supabase
  final String? petName;
  final String? petSpecies;
  final String? vetName;

  MedicalRecordModel({
    required this.id,
    this.appointmentId,
    required this.petId,
    this.vetId,
    required this.diagnosis,
    required this.treatment,
    this.prescription,
    this.clinicalNotes,
    required this.recordDate,
    this.petName,
    this.petSpecies,
    this.vetName,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    final pet = json['pets'] as Map<String, dynamic>?;
    final vet = json['veterinarians'] as Map<String, dynamic>?;

    return MedicalRecordModel(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String?,
      petId: json['pet_id'] as String,
      vetId: json['vet_id'] as String?,
      diagnosis: json['diagnosis'] as String? ?? '',
      treatment: json['treatment'] as String? ?? '',
      prescription: json['prescription'] as String?,
      clinicalNotes: json['clinical_notes'] as String?,
      recordDate: DateTime.tryParse(json['record_date'].toString()) ?? DateTime.now(),
      petName: pet?['name'] as String?,
      petSpecies: pet?['species'] as String?,
      vetName: vet?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'appointment_id': appointmentId?.isNotEmpty == true ? appointmentId : null,
      'pet_id': petId,
      'vet_id': vetId?.isNotEmpty == true ? vetId : null,
      'diagnosis': diagnosis.trim(),
      'treatment': treatment.trim(),
      'prescription':
          prescription?.trim().isNotEmpty == true ? prescription!.trim() : null,
      'clinical_notes':
          clinicalNotes?.trim().isNotEmpty == true ? clinicalNotes!.trim() : null,
      'record_date': recordDate.toIso8601String().split('T').first,
    };
  }

  /// Format teks ringkasan untuk diekspor ke berkas lokal (Syarat File Storage Poin 9)
  String toExportText() {
    final dateStr = recordDate.toIso8601String().split('T').first;
    return '''
==========================================
        KLINIK HEWAN SEHAT - REKAM MEDIS
==========================================
ID Rekam Medis : $id
Tanggal        : $dateStr
Nama Hewan     : ${petName ?? '-'} (${petSpecies ?? '-'})
Dokter Hewan   : ${vetName ?? '-'}
------------------------------------------
DIAGNOSIS:
$diagnosis

TINDAKAN / PERAWATAN:
$treatment

RESEP OBAT:
${prescription?.isNotEmpty == true ? prescription : '-'}

CATATAN KLINIS:
${clinicalNotes?.isNotEmpty == true ? clinicalNotes : '-'}
==========================================
''';
  }
}
