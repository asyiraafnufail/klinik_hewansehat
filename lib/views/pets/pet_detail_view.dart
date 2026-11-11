import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/medical_record_model.dart';
import '../../data/models/pet_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/medical_record_viewmodel.dart';
import '../../viewmodels/pet_viewmodel.dart';

class PetDetailView extends StatelessWidget {
  final PetModel pet;
  const PetDetailView({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final petVM = context.watch<PetViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final recordVM = context.watch<MedicalRecordViewModel>();
    final padding = AppTheme.pagePadding(context);
    final idx = petVM.pets.indexWhere((p) => p.id == pet.id);
    final currentPet = idx != -1 ? petVM.pets[idx] : pet;
    final petRecords = recordVM.records.where((r) => r.petId == currentPet.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/pets/form', extra: currentPet),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Data Hewan'),
                  content: Text('Yakin ingin menghapus data "${currentPet.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                final ok = await petVM.deletePet(currentPet.id);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data hewan dihapus')),
                  );
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: ResponsiveBody(
            maxWidth: 520,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
              children: [
                FadeSlideIn(
                  index: 0,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF99F6E4), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x140D9488),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: AppTheme.primarySoft,
                            backgroundImage: currentPet.photoUrl != null && currentPet.photoUrl!.isNotEmpty
                                ? NetworkImage(currentPet.photoUrl!)
                                : null,
                            onBackgroundImageError: currentPet.photoUrl != null && currentPet.photoUrl!.isNotEmpty
                                ? (_, __) {}
                                : null,
                            child: currentPet.photoUrl == null || currentPet.photoUrl!.isEmpty
                                ? const Icon(Icons.pets_rounded, size: 48, color: AppTheme.primaryDark)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        currentPet.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentPet.species} • ${currentPet.breed ?? "Campuran"}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  index: 1,
                  child: Container(
                    decoration: AppTheme.glassBoxDecoration(radius: 22),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _infoRow('Jenis Kelamin', currentPet.gender ?? '-'),
                        const Divider(height: 16),
                        _infoRow(
                          'Tanggal Lahir',
                          currentPet.birthDate != null
                              ? DateFormat('dd MMMM yyyy').format(currentPet.birthDate!)
                              : '-',
                        ),
                        const Divider(height: 16),
                        _infoRow('Berat Badan', currentPet.weightKg != null ? '${currentPet.weightKg} kg' : '-'),
                        if (currentPet.ownerName != null) ...[
                          const Divider(height: 16),
                          _infoRow('Pemilik', currentPet.ownerName!),
                        ],
                        const Divider(height: 16),
                        _infoRow('Catatan', currentPet.notes?.isNotEmpty == true ? currentPet.notes! : '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BouncyTap(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: const Text('Buat Janji Temu Dokter'),
                            onPressed: () => context.push('/appointments/form', extra: currentPet.id),
                          ),
                        ),
                      ),
                      if (authVM.isAdmin) ...[
                        const SizedBox(height: 10),
                        BouncyTap(
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('Input Rekam Medis Pasien Ini'),
                              onPressed: () => context.push(
                                '/records/form',
                                extra: MedicalRecordModel(
                                  id: '',
                                  petId: currentPet.id,
                                  diagnosis: '',
                                  treatment: '',
                                  recordDate: DateTime.now(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  index: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Rekam Medis (${petRecords.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (petRecords.isEmpty)
                  FadeSlideIn(
                    index: 4,
                    child: Container(
                      decoration: AppTheme.glassBoxDecoration(radius: 18),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Belum ada catatan rekam medis untuk ${currentPet.name}.',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...petRecords.asMap().entries.map(
                    (entry) {
                      final idx = entry.key;
                      final rec = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FadeSlideIn(
                          index: 4 + idx,
                          child: BouncyTap(
                            child: Container(
                              decoration: AppTheme.glassBoxDecoration(radius: 20),
                              child: Material(
                                type: MaterialType.transparency,
                                borderRadius: BorderRadius.circular(20),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: const CircleAvatar(
                                    backgroundColor: AppTheme.primarySoft,
                                    child: Icon(Icons.assignment_outlined, color: AppTheme.primaryDark, size: 20),
                                  ),
                                  title: Text(
                                    rec.diagnosis,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${DateFormat("dd MMM yyyy").format(rec.recordDate)}${rec.vetName != null ? " • ${rec.vetName}" : ""}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.primaryTeal),
                                  onTap: () => context.push('/records/detail', extra: rec),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
