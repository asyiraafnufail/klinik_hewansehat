import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';
import '../models/veterinarian_model.dart';

class ClinicRepository {
  final SupabaseClient? _injectedClient;

  ClinicRepository({SupabaseClient? client}) : _injectedClient = client;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  // === SERVICES CRUDS ===
  Future<List<ServiceModel>> fetchServices({String search = ''}) async {
    final data = await _client.from('services').select().order('name', ascending: true);
    final list = (data as List<dynamic>)
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final clean = search.trim().toLowerCase();
    if (clean.isEmpty) return list;

    return list.where((s) {
      return s.name.toLowerCase().contains(clean) ||
          s.category.toLowerCase().contains(clean) ||
          (s.description ?? '').toLowerCase().contains(clean);
    }).toList();
  }

  Future<void> createService(ServiceModel service) async {
    await _client.from('services').insert(service.toPayload());
  }

  Future<void> updateService(ServiceModel service) async {
    await _client
        .from('services')
        .update(service.toPayload())
        .eq('id', service.id);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').delete().eq('id', id);
  }

  // === VETERINARIANS CRUDS ===
  Future<List<VeterinarianModel>> fetchVeterinarians({String search = ''}) async {
    final data = await _client.from('veterinarians').select().order('full_name', ascending: true);
    final list = (data as List<dynamic>)
        .map((e) => VeterinarianModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final clean = search.trim().toLowerCase();
    if (clean.isEmpty) return list;

    return list.where((v) {
      return v.fullName.toLowerCase().contains(clean) ||
          v.specialization.toLowerCase().contains(clean) ||
          v.licenseNumber.toLowerCase().contains(clean) ||
          (v.bio ?? '').toLowerCase().contains(clean);
    }).toList();
  }

  Future<void> createVeterinarian(VeterinarianModel vet) async {
    await _client.from('veterinarians').insert(vet.toPayload());
  }

  Future<void> updateVeterinarian(VeterinarianModel vet) async {
    await _client
        .from('veterinarians')
        .update(vet.toPayload())
        .eq('id', vet.id);
  }

  Future<void> deleteVeterinarian(String id) async {
    await _client.from('veterinarians').delete().eq('id', id);
  }
}
