import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/medical_record_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/medical_record_viewmodel.dart';

class RecordDetailView extends StatelessWidget {
  final MedicalRecordModel record;
  const RecordDetailView({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final recordVM = context.watch<MedicalRecordViewModel>();
    final padding = AppTheme.pagePadding(context);
    final idx = recordVM.records.indexWhere((r) => r.id == record.id);
    final currentRecord = idx != -1 ? recordVM.records[idx] : record;
    final dateStr = DateFormat('dd MMMM yyyy').format(currentRecord.recordDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Rekam Medis'),
        actions: [
          if (authVM.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/records/form', extra: currentRecord),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final ok = await recordVM.deleteRecord(currentRecord.id);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rekam medis dihapus')),
                  );
                  context.pop();
                }
              },
            ),
          ],
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
                  child: Container(
                    decoration: AppTheme.glassBoxDecoration(radius: 22),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFCCFBF1), Color(0xFFE0F2FE)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF99F6E4), width: 1.2),
                              ),
                              child: const Icon(Icons.assignment_rounded, size: 22, color: AppTheme.primaryDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentRecord.diagnosis,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tanggal: $dateStr',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _section('Pasien Hewan', '${currentRecord.petName ?? "-"} (${currentRecord.petSpecies ?? "-"})'),
                        _section('Dokter Pemeriksa', currentRecord.vetName ?? '-'),
                        _section('Tindakan / Perawatan', currentRecord.treatment),
                        _section(
                          'Resep Obat',
                          currentRecord.prescription?.isNotEmpty == true ? currentRecord.prescription! : '-',
                        ),
                        _section(
                          'Catatan Klinis',
                          currentRecord.clinicalNotes?.isNotEmpty == true ? currentRecord.clinicalNotes! : '-',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Simpan ke Berkas Lokal (Syarat Panduan Poin 9: Save and Read Local Files)
                FadeSlideIn(
                  index: 1,
                  child: BouncyTap(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Unduh Ringkasan (.txt)'),
                        onPressed: () async {
                          try {
                            final savedPath = await recordVM.exportToLocalFile(currentRecord);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tersimpan lokal: ${savedPath.split('/').last}'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
