import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_model.dart';

class PetRepository {
  final SupabaseClient? _injectedClient;

  PetRepository({SupabaseClient? client}) : _injectedClient = client;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<PetModel>> fetchPets({String search = ''}) async {
    final data = await _client
        .from('pets')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false);
    final list = (data as List<dynamic>)
        .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final clean = search.trim().toLowerCase();
    if (clean.isEmpty) return list;

    return list.where((p) {
      return p.name.toLowerCase().contains(clean) ||
          p.species.toLowerCase().contains(clean) ||
          (p.breed ?? '').toLowerCase().contains(clean) ||
          (p.ownerName ?? '').toLowerCase().contains(clean) ||
          (p.notes ?? '').toLowerCase().contains(clean);
    }).toList();
  }

  Future<void> createPet(PetModel pet) async {
    await _client.from('pets').insert(pet.toPayload());
  }

  Future<void> updatePet(PetModel pet) async {
    await _client.from('pets').update(pet.toPayload()).eq('id', pet.id);
  }

  Future<void> deletePet(String id) async {
    await _client.from('pets').delete().eq('id', id);
  }

  Future<String> uploadPetPhoto({
    required String ownerId,
    required Uint8List bytes,
    required String ext,
  }) async {
    final safeExt = ext.toLowerCase() == 'png' ? 'png' : 'jpg';
    final path = '$ownerId/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    await _client.storage.from('pet-avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: safeExt == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from('pet-avatars').getPublicUrl(path);
  }
}
