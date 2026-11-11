import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/network/breed_api_service.dart';
import '../data/models/pet_model.dart';
import '../data/repositories/pet_repository.dart';

class PetViewModel extends ChangeNotifier {
  final PetRepository _repo;
  final BreedApiService _breedApi;

  List<PetModel> _pets = [];
  List<String> _breeds = [];
  bool _isLoading = false;
  bool _isBreedLoading = false;
  bool _isBreedFromFallback = false;
  String? _errorMessage;
  int _fetchSeq = 0;
  Timer? _searchDebounce;

  PetViewModel({PetRepository? repo, BreedApiService? breedApi})
      : _repo = repo ?? PetRepository(),
        _breedApi = breedApi ?? BreedApiService();

  List<PetModel> get pets => _pets;
  List<String> get breeds => _breeds;
  bool get isLoading => _isLoading;
  bool get isBreedLoading => _isBreedLoading;
  bool get isBreedFromFallback => _isBreedFromFallback;
  String? get errorMessage => _errorMessage;

  void setSearch(String query) {
    _searchDebounce?.cancel();
    _pets = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      fetchPets(search: query);
    });
  }

  Future<void> fetchPets({String search = '', bool clearFirst = false}) async {
    final seq = ++_fetchSeq;
    if (clearFirst) {
      _pets = [];
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repo.fetchPets(search: search);
      if (seq != _fetchSeq) return;
      _pets = results;
    } catch (e) {
      if (seq != _fetchSeq) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (seq == _fetchSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Integrasi Public REST API (TheCatAPI / Dog CEO API)
  Future<void> loadBreeds(String species) async {
    _isBreedLoading = true;
    _isBreedFromFallback = false;
    // Tampilkan ras dasar sambil menunggu response REST API
    _breeds = BreedApiService.fallbackBreedsFor(species);
    notifyListeners();

    try {
      final remoteList = await _breedApi.fetchBreedsBySpecies(species);
      if (remoteList.isNotEmpty) {
        _breeds = remoteList;
        _isBreedFromFallback = false;
      }
    } catch (e) {
      // Fallback tetap aktif jika API publik terblokir/offline/timeout
      _isBreedFromFallback = true;
      debugPrint('Breed API fetch failed: $e, using local fallback.');
    } finally {
      _isBreedLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePet({
    required String? id,
    required String ownerId,
    required String name,
    required String species,
    String? breed,
    String? gender,
    DateTime? birthDate,
    double? weightKg,
    String? notes,
    Uint8List? photoBytes,
    String? photoExt,
    String? existingPhotoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? photoUrl = existingPhotoUrl;
      if (photoBytes != null && photoExt != null) {
        photoUrl = await _repo.uploadPetPhoto(
          ownerId: ownerId,
          bytes: photoBytes,
          ext: photoExt,
        );
      }

      final pet = PetModel(
        id: id ?? '',
        ownerId: ownerId,
        name: name.trim(),
        species: species.trim(),
        breed: breed?.trim(),
        gender: gender,
        birthDate: birthDate,
        weightKg: weightKg,
        photoUrl: photoUrl,
        notes: notes?.trim(),
      );

      if (id == null || id.isEmpty) {
        await _repo.createPet(pet);
      } else {
        await _repo.updatePet(pet);
      }

      await fetchPets();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePet(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deletePet(id);
      _pets.removeWhere((p) => p.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _searchDebounce?.cancel();
    _fetchSeq++;
    _pets = [];
    _breeds = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
