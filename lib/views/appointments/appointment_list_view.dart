import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/medical_record_model.dart';
import '../../viewmodels/appointment_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/medical_record_viewmodel.dart';

class AppointmentListView extends StatefulWidget {
  const AppointmentListView({super.key});

  @override
  State<AppointmentListView> createState() => _AppointmentListViewState();
}

class _AppointmentListViewState extends State<AppointmentListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentViewModel>().fetchAppointments();
      context.read<MedicalRecordViewModel>().fetchRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return const Color(0xFFB45309);
      case AppointmentStatus.confirmed:
        return const Color(0xFF1D4ED8);
      case AppointmentStatus.completed:
        return const Color(0xFF047857);
      case AppointmentStatus.cancelled:
        return const Color(0xFFB91C1C);
    }
  }

  Color _statusBgColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return const Color(0xFFFFFBEB);
      case AppointmentStatus.confirmed:
        return const Color(0xFFEFF6FF);
      case AppointmentStatus.completed:
        return const Color(0xFFECFDF5);
      case AppointmentStatus.cancelled:
        return const Color(0xFFFEF2F2);
    }
  }

  Color _statusAccentColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return const Color(0xFFD97706);
      case AppointmentStatus.confirmed:
        return const Color(0xFF2563EB);
      case AppointmentStatus.completed:
        return const Color(0xFF059669);
      case AppointmentStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    AppointmentModel item,
    bool isAdmin,
  ) async {
    final controller = TextEditingController(
      text: isAdmin ? 'Dibatalkan oleh klinik' : 'Dibatalkan oleh pemilik',
    );
    final bool? confirm;
    final String reasonText;
    try {
      confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Batalkan Janji Temu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Batalkan janji temu pasien "${item.petName ?? "hewan"}"?'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Alasan Pembatalan *',
                  hintText: 'Misal: Jadwal bentrok, dokter berhalangan',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Kembali'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      );
      reasonText = controller.text.trim();
    } finally {
      controller.dispose();
    }

    if (confirm == true && context.mounted) {
      final reason = reasonText.isEmpty
          ? (isAdmin ? 'Dibatalkan oleh klinik' : 'Dibatalkan oleh pemilik')
          : reasonText;
      final ok = await context.read<AppointmentViewModel>().updateStatus(
            id: item.id,
            status: AppointmentStatus.cancelled,
            cancellationReason: reason,
          );
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Janji temu telah dibatalkan')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppointmentModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Janji Temu'),
        content: Text(
          'Hapus permanen jadwal "${item.petName ?? "hewan"}" pada tanggal ${DateFormat("dd MMM yyyy").format(item.appointmentDate)}?',
        ),
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
      await context.read<AppointmentViewModel>().deleteAppointment(item.id);
    }
  }

  Widget _deleteIconButton(BuildContext context, AppointmentModel item) {
    return BouncyTap(
      child: SizedBox(
        width: 38,
        height: 38,
        child: Material(
          color: const Color(0xFFFEF2F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFECACA), width: 1.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _confirmDelete(context, item),
            child: const Tooltip(
              message: 'Hapus Janji',
              child: Icon(Icons.delete_outline_rounded, color: Color(0xFFB91C1C), size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _softActionButton({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onPressed,
    IconData? icon,
    double height = 38,
  }) {
    return BouncyTap(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Material(
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor, width: 1.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: textColor),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final activeBg = accentColor ?? AppTheme.primaryTeal;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: BouncyTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeBg : const Color(0xEBFFFFFF),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: selected ? activeBg : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeBg.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (accentColor != null && !selected) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apptVM = context.watch<AppointmentViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final recordVM = context.watch<MedicalRecordViewModel>();
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(authVM.isAdmin ? 'Kelola Semua Janji Temu' : 'Janji Temu Saya'),
      ),
      floatingActionButton: BouncyTap(
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat Janji'),
          onPressed: () => context.push('/appointments/form'),
        ),
      ),
      body: GlassBackground(
        child: ResponsiveBody(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
                child: GlassSearchBar(
                  controller: _searchController,
                  hintText: 'Cari nama hewan, dokter, atau keluhan...',
                  onChanged: (val) => apptVM.setSearch(val),
                  onClear: () {
                    _searchController.clear();
                    apptVM.setSearch('');
                  },
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(padding, 4, padding, 8),
              child: Row(
                children: [
                  _buildFilterPill(
                    label: 'Semua',
                    selected: apptVM.statusFilter == null,
                    onTap: () => apptVM.setFilter(null),
                  ),
                  ...AppointmentStatus.values.map(
                    (st) => _buildFilterPill(
                      label: st.label,
                      selected: apptVM.statusFilter == st,
                      accentColor: _statusAccentColor(st),
                      onTap: () => apptVM.setFilter(st),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                reverseDuration: Duration.zero,
                switchInCurve: Curves.easeOutCubic,
                child: Builder(
                  key: ValueKey('${apptVM.statusFilter?.name ?? "all"}_${apptVM.isLoading && apptVM.appointments.isEmpty}_${apptVM.appointments.isEmpty}'),
                  builder: (context) {
                  if (apptVM.isLoading && apptVM.appointments.isEmpty) {
                    return const GlassSkeletonList();
                  }
                  if (apptVM.errorMessage != null && apptVM.appointments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error: ${apptVM.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  if (apptVM.appointments.isEmpty) {
                    return const GlassEmptyState(
                      icon: Icons.calendar_today_rounded,
                      title: 'Tidak ada data janji temu',
                      subtitle: 'Jadwal konsultasi dokter akan tampil di sini.',
                    );
                  }

                  final recordByApptId = {
                    for (final r in recordVM.records)
                      if (r.appointmentId != null) r.appointmentId!: r,
                  };

                  return RefreshIndicator(
                    onRefresh: () => Future.wait([
                      apptVM.fetchAppointments(),
                      recordVM.fetchRecords(),
                    ]),
                    child: ListView.separated(
                      cacheExtent: 320,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(padding, 6, padding, 88),
                      itemCount: apptVM.appointments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = apptVM.appointments[index];
                        final dateStr = DateFormat('EEE, dd MMM yyyy').format(item.appointmentDate);
                        final linkedRecord = recordByApptId[item.id];
                        final hasOwnerActions = !authVM.isAdmin &&
                            (item.status == AppointmentStatus.pending ||
                                item.status == AppointmentStatus.confirmed ||
                                (item.status == AppointmentStatus.completed && linkedRecord != null));
                        final hasActions = authVM.isAdmin || hasOwnerActions;

                        return FadeSlideIn(
                          index: index,
                          child: Container(
                            decoration: AppTheme.glassBoxDecoration(radius: 22),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFFCCFBF1), Color(0xFFE0F2FE)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF99F6E4), width: 1),
                                      ),
                                      child: const Icon(Icons.pets_rounded, size: 20, color: Color(0xFF0F766E)),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.petName ?? 'Hewan',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        if (authVM.isAdmin && item.ownerName != null)
                                          Text(
                                            'Pemilik: ${item.ownerName}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _statusBgColor(item.status),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: _statusColor(item.status).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _statusColor(item.status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.status.label,
                                          style: TextStyle(
                                            color: _statusColor(item.status),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Tanggal & Jam
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$dateStr • Jam ${item.formattedTime}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                              if (item.serviceName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Layanan: ${item.serviceName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item.vetName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_pin_circle_outlined, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Dokter: ${item.vetName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 8),

                              // Keluhan Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0x66F1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Keluhan: ${item.reason.isNotEmpty ? item.reason : "-"}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (item.status == AppointmentStatus.cancelled &&
                                  item.cancellationReason?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.red.shade800),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Alasan Batal: ${item.cancellationReason}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (hasActions) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                const SizedBox(height: 12),

                                // Tombol Aksi Terstruktur & Simetris
                                if (authVM.isAdmin) ...[
                                  if (item.status == AppointmentStatus.pending) ...[
                                    BouncyTap(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.check_circle_outline, size: 18),
                                          label: const Text('Konfirmasi Jadwal'),
                                          onPressed: () => apptVM.updateStatus(
                                            id: item.id,
                                            status: AppointmentStatus.confirmed,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _softActionButton(
                                            label: 'Ubah',
                                            bgColor: const Color(0xFFF0FDFA),
                                            borderColor: const Color(0xFF99F6E4),
                                            textColor: const Color(0xFF0F766E),
                                            onPressed: () => context.push('/appointments/form', extra: item),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _softActionButton(
                                            label: 'Tolak',
                                            bgColor: const Color(0xFFFEF2F2),
                                            borderColor: const Color(0xFFFECACA),
                                            textColor: const Color(0xFFB91C1C),
                                            onPressed: () => _showCancelDialog(context, item, true),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _deleteIconButton(context, item),
                                      ],
                                    ),
                                  ],
                                  if (item.status == AppointmentStatus.confirmed) ...[
                                    BouncyTap(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.medical_services_outlined, size: 18),
                                          label: const Text('Periksa & Rekam Medis'),
                                          onPressed: () => context.push(
                                            '/records/form',
                                            extra: MedicalRecordModel(
                                              id: '',
                                              appointmentId: item.id,
                                              petId: item.petId,
                                              vetId: item.vetId,
                                              diagnosis: '',
                                              treatment: '',
                                              recordDate: item.appointmentDate,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _softActionButton(
                                            label: 'Selesai',
                                            bgColor: const Color(0xFFECFDF5),
                                            borderColor: const Color(0xFFA7F3D0),
                                            textColor: const Color(0xFF047857),
                                            onPressed: () => apptVM.updateStatus(
                                              id: item.id,
                                              status: AppointmentStatus.completed,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _softActionButton(
                                            label: 'Ubah',
                                            bgColor: const Color(0xFFF0FDFA),
                                            borderColor: const Color(0xFF99F6E4),
                                            textColor: const Color(0xFF0F766E),
                                            onPressed: () => context.push('/appointments/form', extra: item),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _softActionButton(
                                            label: 'Batal',
                                            bgColor: const Color(0xFFFEF2F2),
                                            borderColor: const Color(0xFFFECACA),
                                            textColor: const Color(0xFFB91C1C),
                                            onPressed: () => _showCancelDialog(context, item, true),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _deleteIconButton(context, item),
                                      ],
                                    ),
                                  ],
                                  if (item.status == AppointmentStatus.completed) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: BouncyTap(
                                            child: SizedBox(
                                              height: 40,
                                              child: ElevatedButton.icon(
                                                icon: Icon(
                                                  linkedRecord != null
                                                      ? Icons.assignment_outlined
                                                      : Icons.note_add_outlined,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  linkedRecord != null
                                                      ? 'Lihat Rekam Medis'
                                                      : 'Catat Rekam Medis',
                                                ),
                                                onPressed: () {
                                                  if (linkedRecord != null) {
                                                    context.push('/records/detail', extra: linkedRecord);
                                                  } else {
                                                    context.push(
                                                      '/records/form',
                                                      extra: MedicalRecordModel(
                                                        id: '',
                                                        appointmentId: item.id,
                                                        petId: item.petId,
                                                        vetId: item.vetId,
                                                        diagnosis: '',
                                                        treatment: '',
                                                        recordDate: item.appointmentDate,
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _deleteIconButton(context, item),
                                      ],
                                    ),
                                  ],
                                  if (item.status == AppointmentStatus.cancelled) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _deleteIconButton(context, item),
                                      ],
                                    ),
                                  ],
                                ],
                                if (!authVM.isAdmin) ...[
                                  if (item.status == AppointmentStatus.pending) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _softActionButton(
                                            icon: Icons.edit_outlined,
                                            label: 'Ubah Jadwal',
                                            height: 40,
                                            bgColor: const Color(0xFFF0FDFA),
                                            borderColor: const Color(0xFF99F6E4),
                                            textColor: const Color(0xFF0F766E),
                                            onPressed: () => context.push('/appointments/form', extra: item),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _softActionButton(
                                            icon: Icons.close_rounded,
                                            label: 'Batalkan',
                                            height: 40,
                                            bgColor: const Color(0xFFFEF2F2),
                                            borderColor: const Color(0xFFFECACA),
                                            textColor: const Color(0xFFB91C1C),
                                            onPressed: () => _showCancelDialog(context, item, false),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (item.status == AppointmentStatus.confirmed) ...[
                                    _softActionButton(
                                      icon: Icons.close_rounded,
                                      label: 'Batalkan Janji Temu',
                                      height: 40,
                                      bgColor: const Color(0xFFFEF2F2),
                                      borderColor: const Color(0xFFFECACA),
                                      textColor: const Color(0xFFB91C1C),
                                      onPressed: () => _showCancelDialog(context, item, false),
                                    ),
                                  ],
                                  if (item.status == AppointmentStatus.completed && linkedRecord != null) ...[
                                    BouncyTap(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.assignment_outlined, size: 18),
                                          label: const Text('Lihat Rekam Medis'),
                                          onPressed: () => context.push('/records/detail', extra: linkedRecord),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ],
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
