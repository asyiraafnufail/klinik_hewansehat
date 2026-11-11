import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_record_model.dart';

class MedicalRecordRepository {
  final SupabaseClient? _injectedClient;

  MedicalRecordRepository({SupabaseClient? client}) : _injectedClient = client;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<MedicalRecordModel>> fetchRecords({String search = ''}) async {
    final data = await _client
        .from('medical_records')
        .select('*, pets(name, species), veterinarians(full_name)')
        .order('record_date', ascending: false);

    final list = (data as List<dynamic>)
        .map((e) => MedicalRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final clean = search.trim().toLowerCase();
    if (clean.isEmpty) return list;

    return list.where((r) {
      return r.diagnosis.toLowerCase().contains(clean) ||
          r.treatment.toLowerCase().contains(clean) ||
          (r.petName ?? '').toLowerCase().contains(clean) ||
          (r.vetName ?? '').toLowerCase().contains(clean);
    }).toList();
  }

  Future<void> createRecord(MedicalRecordModel record) async {
    await _client.from('medical_records').insert(record.toPayload());
  }

  Future<void> updateRecord(MedicalRecordModel record) async {
    await _client
        .from('medical_records')
        .update(record.toPayload())
        .eq('id', record.id);
  }

  Future<void> deleteRecord(String id) async {
    await _client.from('medical_records').delete().eq('id', id);
  }
}
