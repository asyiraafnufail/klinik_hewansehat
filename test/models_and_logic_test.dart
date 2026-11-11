import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_hewansehat/core/network/breed_api_service.dart';
import 'package:klinik_hewansehat/data/models/appointment_model.dart';
import 'package:klinik_hewansehat/data/models/medical_record_model.dart';
import 'package:klinik_hewansehat/data/models/pet_model.dart';
import 'package:klinik_hewansehat/data/models/profile_model.dart';
import 'package:klinik_hewansehat/data/models/service_model.dart';
import 'package:klinik_hewansehat/data/models/veterinarian_model.dart';

void main() {
  group('ProfileModel & RBAC Tests', () {
    test('parses admin role correctly', () {
      final model = ProfileModel.fromJson({
        'id': 'user-123',
        'email': 'admin@klinik.com',
        'full_name': 'Admin Klinik',
        'role': 'admin',
      });

      expect(model.isAdmin, isTrue);
      expect(model.isPetOwner, isFalse);
      expect(model.role, UserRole.admin);
    });

    test('parses pet_owner role correctly', () {
      final model = ProfileModel.fromJson({
        'id': 'user-456',
        'email': 'owner@gmail.com',
        'full_name': 'Budi Santoso',
        'role': 'pet_owner',
      });

      expect(model.isAdmin, isFalse);
      expect(model.isPetOwner, isTrue);
      expect(model.role, UserRole.petOwner);
    });
  });

  group('PetModel Tests', () {
    test('serialization to payload matches schema', () {
      final pet = PetModel(
        id: 'pet-1',
        ownerId: 'owner-1',
        name: 'Milo',
        species: 'Kucing',
        breed: 'Persia',
        gender: 'Jantan',
        birthDate: DateTime(2022, 5, 10),
        weightKg: 4.2,
        notes: 'Alergi seafood',
      );

      final payload = pet.toPayload();
      expect(payload['name'], 'Milo');
      expect(payload['species'], 'Kucing');
      expect(payload['weight_kg'], 4.2);
      expect(payload['birth_date'], '2022-05-10');
    });

    test('parses string numeric weight_kg and sanitizes empty fields to null', () {
      final parsed = PetModel.fromJson({
        'id': 'pet-2',
        'owner_id': 'owner-2',
        'name': 'Luna',
        'species': 'Kucing',
        'weight_kg': '3.75',
        'profiles': {'full_name': 'Siti'},
      });

      expect(parsed.weightKg, 3.75);
      expect(parsed.ownerName, 'Siti');

      final emptyPet = PetModel(
        id: 'pet-2',
        ownerId: 'owner-2',
        name: 'Luna',
        species: 'Kucing',
        breed: ' ',
        notes: '',
      );
      expect(emptyPet.toPayload()['breed'], isNull);
      expect(emptyPet.toPayload()['notes'], isNull);
    });
  });

  group('AppointmentModel Tests', () {
    test('parses status and sanitizes empty FK UUIDs to null', () {
      expect(AppointmentStatus.fromString('pending'), AppointmentStatus.pending);
      expect(AppointmentStatus.fromString('confirmed'), AppointmentStatus.confirmed);
      expect(AppointmentStatus.fromString('completed'), AppointmentStatus.completed);
      expect(AppointmentStatus.fromString('cancelled'), AppointmentStatus.cancelled);
      expect(AppointmentStatus.fromString('unknown'), AppointmentStatus.pending);

      final appt = AppointmentModel(
        id: 'appt-1',
        petId: 'pet-1',
        ownerId: 'owner-1',
        vetId: '',
        serviceId: '',
        appointmentDate: DateTime(2026, 4, 1),
        appointmentTime: '10:00:00',
        status: AppointmentStatus.pending,
        reason: 'Cek rutin',
      );
      final payload = appt.toPayload();
      expect(payload['vet_id'], isNull);
      expect(payload['service_id'], isNull);
    });
  });

  group('MedicalRecordModel Local Export Tests (Requirement 9)', () {
    test('generates expected export text for local file storage', () {
      final record = MedicalRecordModel(
        id: 'rec-001',
        petId: 'pet-1',
        petName: 'Milo',
        petSpecies: 'Kucing',
        vetName: 'drh. Nadia',
        diagnosis: 'Flu Kucing (Feline Rhinotracheitis)',
        treatment: 'Injeksi antibiotik & vitamin',
        prescription: 'Amoxicillin 2x1 drop selama 5 hari',
        recordDate: DateTime(2026, 3, 15),
      );

      final text = record.toExportText();
      expect(text, contains('KLINIK HEWAN SEHAT - REKAM MEDIS'));
      expect(text, contains('Milo (Kucing)'));
      expect(text, contains('drh. Nadia'));
      expect(text, contains('Flu Kucing'));
      expect(text, contains('Amoxicillin 2x1 drop'));
    });
  });

  group('BreedApiService JSON Parsing Tests (Requirement 7)', () {
    test('parses cat breeds JSON from TheCatAPI', () {
      const rawJson = '''
      [
        {"id": "abys", "name": "Abyssinian"},
        {"id": "beng", "name": "Bengal"},
        {"id": "pers", "name": "Persian"}
      ]
      ''';

      final list = BreedApiService.parseCatBreedsJson(rawJson);
      expect(list.length, 3);
      expect(list, contains('Abyssinian'));
      expect(list, contains('Bengal'));
      expect(list, contains('Persian'));
    });

    test('parses dog breeds JSON from Dog CEO API', () {
      const rawJson = '''
      {
        "message": {
          "beagle": [],
          "bulldog": ["english", "french"]
        },
        "status": "success"
      }
      ''';

      final list = BreedApiService.parseDogBreedsJson(rawJson);
      expect(list, contains('Beagle'));
      expect(list, contains('Bulldog (English)'));
      expect(list, contains('Bulldog (French)'));
    });

    test('returns rich fallback breeds when offline or API fails', () {
      final catBreeds = BreedApiService.fallbackBreedsFor('Kucing');
      expect(catBreeds, contains('Persia'));
      expect(catBreeds, contains('Anggora'));
      expect(catBreeds, contains('British Shorthair'));

      final dogBreeds = BreedApiService.fallbackBreedsFor('Anjing');
      expect(dogBreeds, contains('Golden Retriever'));
      expect(dogBreeds, contains('Siberian Husky'));
    });
  });

  group('Clinic Master Models Tests (Supabase Sync)', () {
    test('ServiceModel parses numeric and string prices', () {
      final s1 = ServiceModel.fromJson({
        'id': 'svc-1',
        'name': 'Vaksinasi Rabies',
        'category': 'Vaksinasi',
        'price': '120000.00',
        'duration_minutes': '20',
        'is_active': true,
      });
      expect(s1.price, 120000.0);
      expect(s1.durationMinutes, 20);
      expect(s1.isActive, isTrue);
    });

    test('VeterinarianModel parses schedule days and formatted hours', () {
      final vet = VeterinarianModel.fromJson({
        'id': 'vet-1',
        'full_name': 'drh. Nadia',
        'specialization': 'Penyakit Dalam',
        'license_number': 'SIP-001',
        'schedule_days': ['Senin', 'Rabu'],
        'start_time': '09:00:00',
        'end_time': '17:00:00',
        'is_available': true,
      });
      expect(vet.scheduleDays, ['Senin', 'Rabu']);
      expect(vet.formattedHours, '09:00 - 17:00');
    });
  });
}
