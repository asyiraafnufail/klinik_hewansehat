import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/local_file_viewmodel.dart';

class LocalFilesView extends StatefulWidget {
  const LocalFilesView({super.key});

  @override
  State<LocalFilesView> createState() => _LocalFilesViewState();
}

class _LocalFilesViewState extends State<LocalFilesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalFileViewModel>().loadFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocalFileViewModel>();
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berkas Unduhan Lokal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vm.loadFiles(),
          ),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: ResponsiveBody(
            maxWidth: 520,
            child: Builder(
              builder: (context) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: ${vm.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (vm.files.isEmpty) {
                  return const GlassEmptyState(
                    icon: Icons.folder_open_rounded,
                    title: 'Belum ada berkas tersimpan di perangkat',
                    subtitle: 'Buka menu Rekam Medis lalu tekan tombol "Unduh Ringkasan" untuk menyimpan salinan offline.',
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 80),
                  itemCount: vm.files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entity = vm.files[index];
                    final filename = entity.path.split('/').last;
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
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primarySoft,
                                child: Icon(Icons.description_outlined, color: AppTheme.primaryDark),
                              ),
                              title: Text(
                                filename,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                entity.path,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              onTap: () => context.push('/files/viewer', extra: entity.path),
                              trailing: SoftIconButton(
                                icon: Icons.delete_outline_rounded,
                                bgColor: const Color(0xFFFEF2F2),
                                borderColor: const Color(0xFFFECACA),
                                iconColor: const Color(0xFFB91C1C),
                                tooltip: 'Hapus Berkas',
                                onPressed: () => vm.deleteFile(entity.path),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
