import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/medical_record_viewmodel.dart';

class RecordListView extends StatefulWidget {
  const RecordListView({super.key});

  @override
  State<RecordListView> createState() => _RecordListViewState();
}

class _RecordListViewState extends State<RecordListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalRecordViewModel>().fetchRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordVM = context.watch<MedicalRecordViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(authVM.isAdmin ? 'Kelola Rekam Medis Pasien' : 'Riwayat Rekam Medis'),
      ),
      floatingActionButton: authVM.isAdmin
          ? BouncyTap(
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Input Rekam Medis'),
                onPressed: () => context.push('/records/form'),
              ),
            )
          : null,
      body: GlassBackground(
        child: ResponsiveBody(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
                child: GlassSearchBar(
                  controller: _searchController,
                  hintText: 'Cari diagnosis, tindakan, atau nama hewan...',
                  onChanged: (val) => recordVM.setSearch(val),
                  onClear: () {
                    _searchController.clear();
                    recordVM.fetchRecords(clearFirst: true);
                  },
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  reverseDuration: Duration.zero,
                  switchInCurve: Curves.easeOutCubic,
                  child: Builder(
                    key: ValueKey('records_${recordVM.isLoading && recordVM.records.isEmpty}_${recordVM.records.isEmpty}'),
                    builder: (context) {
                      if (recordVM.isLoading && recordVM.records.isEmpty) {
                        return const GlassSkeletonList();
                      }
                      if (recordVM.errorMessage != null && recordVM.records.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Error: ${recordVM.errorMessage}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                      if (recordVM.records.isEmpty) {
                        return const GlassEmptyState(
                          icon: Icons.medical_services_outlined,
                          title: 'Belum ada riwayat rekam medis',
                          subtitle: 'Catatan pemeriksaan dan resep dokter akan tampil di sini.',
                        );
                      }

                    return RefreshIndicator(
                      onRefresh: () => recordVM.fetchRecords(search: _searchController.text),
                      child: ListView.separated(
                        cacheExtent: 320,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(padding, 4, padding, 88),
                      itemCount: recordVM.records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = recordVM.records[index];
                        final dateStr = DateFormat('dd MMM yyyy').format(item.recordDate);

                        return FadeSlideIn(
                          index: index,
                          child: BouncyTap(
                            child: Container(
                              decoration: AppTheme.glassBoxDecoration(radius: 22),
                              child: Material(
                                type: MaterialType.transparency,
                                borderRadius: BorderRadius.circular(22),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                              child: const Icon(Icons.assignment_outlined, color: Color(0xFF0D9488)),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.diagnosis,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Pasien: ${item.petName ?? "Hewan"} (${item.petSpecies ?? "-"})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (item.vetName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Dokter: ${item.vetName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tindakan: ${item.treatment}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryTeal),
                            onTap: () => context.push('/records/detail', extra: item),
                          ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
