import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/clinic_viewmodel.dart';

class ClinicTabView extends StatefulWidget {
  const ClinicTabView({super.key});

  @override
  State<ClinicTabView> createState() => _ClinicTabViewState();
}

class _ClinicTabViewState extends State<ClinicTabView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _serviceSearchController = TextEditingController();
  final _vetSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicViewModel>().fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceSearchController.dispose();
    _vetSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicVM = context.watch<ClinicViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final padding = AppTheme.pagePadding(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Klinik & Tarif'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Layanan & Tarif', icon: Icon(Icons.medical_services_outlined)),
            Tab(text: 'Dokter Hewan', icon: Icon(Icons.people_outline)),
          ],
        ),
      ),
      floatingActionButton: authVM.isAdmin
          ? BouncyTap(
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.add_rounded),
                label: Text(_tabController.index == 0 ? 'Tambah Layanan' : 'Tambah Dokter'),
                onPressed: () {
                  if (_tabController.index == 0) {
                    context.push('/services/form');
                  } else {
                    context.push('/vets/form');
                  }
                },
              ),
            )
          : null,
      body: GlassBackground(
        child: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: SERVICES
          ResponsiveBody(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
                  child: GlassSearchBar(
                    controller: _serviceSearchController,
                    hintText: 'Cari layanan atau kategori...',
                    onChanged: (val) => clinicVM.searchServices(val),
                    onClear: () {
                      _serviceSearchController.clear();
                      clinicVM.fetchServices();
                    },
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    reverseDuration: Duration.zero,
                    switchInCurve: Curves.easeOutCubic,
                    child: Builder(
                      key: ValueKey('services_${clinicVM.isServicesLoading && clinicVM.services.isEmpty}_${clinicVM.services.isEmpty}'),
                      builder: (context) {
                        if (clinicVM.isServicesLoading && clinicVM.services.isEmpty) {
                          return const GlassSkeletonList();
                        }
                        if (clinicVM.services.isEmpty) {
                          return const GlassEmptyState(
                            icon: Icons.medical_services_outlined,
                            title: 'Tidak ada layanan yang sesuai',
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () =>
                              clinicVM.fetchServices(search: _serviceSearchController.text),
                          child: ListView.separated(
                            cacheExtent: 320,
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(padding, 4, padding, 88),
                            itemCount: clinicVM.services.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = clinicVM.services[index];
                              return FadeSlideIn(
                                    index: index,
                                    child: BouncyTap(
                                      child: Container(
                                        decoration: AppTheme.glassBoxDecoration(radius: 22),
                                        child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                currency.format(item.price),
                                                style: const TextStyle(
                                                  color: Color(0xFF0D9488),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${item.category} • Estimasi ${item.durationMinutes} menit',
                                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                                ),
                                              ),
                                              if (!item.isActive)
                                                const StatusPillBadge(
                                                  label: 'Nonaktif',
                                                  textColor: Color(0xFFB91C1C),
                                                  bgColor: Color(0xFFFEF2F2),
                                                  borderColor: Color(0xFFFECACA),
                                                ),
                                            ],
                                          ),
                                          if (item.description != null && item.description!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              item.description!,
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                          ],
                                          if (authVM.isAdmin) ...[
                                            const Divider(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                SoftIconButton(
                                                  icon: Icons.edit_outlined,
                                                  bgColor: const Color(0xFFF0FDFA),
                                                  borderColor: const Color(0xFF99F6E4),
                                                  iconColor: const Color(0xFF0F766E),
                                                  tooltip: 'Edit Layanan',
                                                  size: 34,
                                                  onPressed: () => context.push('/services/form', extra: item),
                                                ),
                                                const SizedBox(width: 8),
                                                SoftIconButton(
                                                  icon: Icons.delete_outline_rounded,
                                                  bgColor: const Color(0xFFFEF2F2),
                                                  borderColor: const Color(0xFFFECACA),
                                                  iconColor: const Color(0xFFB91C1C),
                                                  tooltip: 'Hapus Layanan',
                                                  size: 34,
                                                  onPressed: () => clinicVM.deleteService(item.id),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
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

          // TAB 2: VETERINARIANS
          ResponsiveBody(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
                  child: GlassSearchBar(
                    controller: _vetSearchController,
                    hintText: 'Cari dokter atau spesialisasi...',
                    onChanged: (val) => clinicVM.searchVets(val),
                    onClear: () {
                      _vetSearchController.clear();
                      clinicVM.fetchVets();
                    },
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    reverseDuration: Duration.zero,
                    switchInCurve: Curves.easeOutCubic,
                    child: Builder(
                      key: ValueKey('vets_${clinicVM.isVetsLoading && clinicVM.vets.isEmpty}_${clinicVM.vets.isEmpty}'),
                      builder: (context) {
                        if (clinicVM.isVetsLoading && clinicVM.vets.isEmpty) {
                          return const GlassSkeletonList();
                        }
                        if (clinicVM.vets.isEmpty) {
                          return const GlassEmptyState(
                            icon: Icons.people_outline,
                            title: 'Tidak ada data dokter hewan',
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () => clinicVM.fetchVets(search: _vetSearchController.text),
                          child: ListView.separated(
                            cacheExtent: 320,
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(padding, 4, padding, 88),
                            itemCount: clinicVM.vets.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final vet = clinicVM.vets[index];
                              return FadeSlideIn(
                                    index: index,
                                    child: BouncyTap(
                                      child: Container(
                                        decoration: AppTheme.glassBoxDecoration(radius: 22),
                                        child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                                            child: const Icon(Icons.person, color: Color(0xFF0D9488)),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        vet.fullName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    if (!vet.isAvailable)
                                                      const StatusPillBadge(
                                                        label: 'Libur',
                                                        textColor: Color(0xFFB45309),
                                                        bgColor: Color(0xFFFFFBEB),
                                                        borderColor: Color(0xFFFDE68A),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  vet.specialization,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0D9488),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'SIP: ${vet.licenseNumber}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                Text(
                                                  'Hari: ${vet.scheduleDays.join(", ")}',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                Text(
                                                  'Jam: ${vet.formattedHours}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                if (vet.bio != null && vet.bio!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    vet.bio!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade700,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (authVM.isAdmin)
                                            Column(
                                              children: [
                                                SoftIconButton(
                                                  icon: Icons.edit_outlined,
                                                  bgColor: const Color(0xFFF0FDFA),
                                                  borderColor: const Color(0xFF99F6E4),
                                                  iconColor: const Color(0xFF0F766E),
                                                  tooltip: 'Edit Dokter',
                                                  size: 34,
                                                  onPressed: () => context.push('/vets/form', extra: vet),
                                                ),
                                                const SizedBox(height: 8),
                                                SoftIconButton(
                                                  icon: Icons.delete_outline_rounded,
                                                  bgColor: const Color(0xFFFEF2F2),
                                                  borderColor: const Color(0xFFFECACA),
                                                  iconColor: const Color(0xFFB91C1C),
                                                  tooltip: 'Hapus Dokter',
                                                  size: 34,
                                                  onPressed: () => clinicVM.deleteVet(vet.id),
                                                ),
                                              ],
                                            ),
                                        ],
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
        ],
      ),
      ),
    );
  }
}
