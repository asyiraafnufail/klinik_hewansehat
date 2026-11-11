import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/veterinarian_model.dart';
import '../../viewmodels/appointment_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/clinic_viewmodel.dart';
import '../../viewmodels/pet_viewmodel.dart';

class AppointmentFormView extends StatefulWidget {
  final AppointmentModel? appointment;
  final String? initialPetId;
  const AppointmentFormView({super.key, this.appointment, this.initialPetId});

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedPetId;
  String? _selectedServiceId;
  String? _selectedVetId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  bool get isEdit => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final a = widget.appointment!;
      _selectedPetId = a.petId;
      _selectedServiceId = a.serviceId;
      _selectedVetId = a.vetId;
      _selectedDate = a.appointmentDate;
      _reasonController.text = a.reason;
      final parts = a.appointmentTime.split(':');
      if (parts.length >= 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    } else {
      _selectedPetId = widget.initialPetId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().fetchPets();
      context.read<ClinicViewModel>().fetchAll();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _selectedDate.isBefore(today) ? today : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  static const _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih hewan terlebih dahulu')),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final apptVM = context.read<AppointmentViewModel>();
    final petVM = context.read<PetViewModel>();

    final selectedPet = petVM.pets.cast<PetModel?>().firstWhere(
          (p) => p?.id == _selectedPetId,
          orElse: () => null,
        );
    final ownerId = widget.appointment?.ownerId ?? selectedPet?.ownerId ?? authVM.currentUserId;
    if (ownerId == null) return;

    final ok = await apptVM.saveAppointment(
      id: widget.appointment?.id,
      petId: _selectedPetId!,
      ownerId: ownerId,
      vetId: _selectedVetId,
      serviceId: _selectedServiceId,
      date: _selectedDate,
      time: _formatTimeOfDay(_selectedTime),
      reason: _reasonController.text,
      status: widget.appointment?.status ?? AppointmentStatus.pending,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Jadwal janji temu diperbarui' : 'Janji temu berhasil dibuat!'),
        ),
      );
      context.pop();
    } else if (apptVM.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apptVM.errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final petVM = context.watch<PetViewModel>();
    final clinicVM = context.watch<ClinicViewModel>();
    final apptVM = context.watch<AppointmentViewModel>();
    final padding = AppTheme.pagePadding(context);
    final isVeryNarrow = MediaQuery.sizeOf(context).width < 340;

    final petItems = petVM.pets;
    final serviceItems = clinicVM.services
        .where((s) => s.isActive || s.id == _selectedServiceId)
        .toList();
    final vetItems = clinicVM.vets
        .where((v) => v.isAvailable || v.id == _selectedVetId)
        .toList();
    final selectedVet = vetItems.cast<VeterinarianModel?>().firstWhere(
          (v) => v?.id == _selectedVetId,
          orElse: () => null,
        );
    final selectedDayName = _weekdays[_selectedDate.weekday - 1];
    final isDayOff = selectedVet != null &&
        selectedVet.scheduleDays.isNotEmpty &&
        !selectedVet.scheduleDays.contains(selectedDayName);

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Ubah Janji Temu' : 'Buat Janji Temu')),
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
            child: ResponsiveBody(
              maxWidth: 520,
              child: FadeSlideIn(
                child: Container(
                  decoration: AppTheme.glassBoxDecoration(radius: 24),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // Pilih Hewan
                  DropdownButtonFormField<String>(
                    value: petItems.any((p) => p.id == _selectedPetId) ? _selectedPetId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pilih Hewan Pasien *'),
                    items: petItems
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} (${p.species})${authVM.isAdmin && p.ownerName != null ? " - ${p.ownerName}" : ""}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPetId = val),
                    validator: (val) => val == null ? 'Wajib memilih hewan' : null,
                  ),
                  const SizedBox(height: 16),

                  // Pilih Layanan
                  DropdownButtonFormField<String>(
                    value: serviceItems.any((s) => s.id == _selectedServiceId)
                        ? _selectedServiceId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pilih Layanan Klinik'),
                    items: serviceItems
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.name} - Rp ${s.price.toStringAsFixed(0)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedServiceId = val),
                  ),
                  const SizedBox(height: 16),

                  // Pilih Dokter
                  DropdownButtonFormField<String>(
                    value: vetItems.any((v) => v.id == _selectedVetId) ? _selectedVetId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pilih Dokter Hewan (Opsional)'),
                    items: vetItems
                        .map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                '${v.fullName} (${v.specialization})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedVetId = val),
                  ),
                  if (selectedVet != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Jadwal praktek: ${selectedVet.scheduleDays.join(", ")} (${selectedVet.formattedHours})',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  const SizedBox(height: 16),

                  if (isVeryNarrow) ...[
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Kunjungan',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Jam Kunjungan',
                          suffixIcon: Icon(Icons.access_time, size: 18),
                        ),
                        child: Text(
                          '${_selectedTime.hour.toString().padLeft(2, "0")}:${_selectedTime.minute.toString().padLeft(2, "0")}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Kunjungan',
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Jam Kunjungan',
                                suffixIcon: Icon(Icons.access_time, size: 18),
                              ),
                              child: Text(
                                '${_selectedTime.hour.toString().padLeft(2, "0")}:${_selectedTime.minute.toString().padLeft(2, "0")}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isDayOff)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Catatan: Hari $selectedDayName biasanya bukan jadwal praktek ${selectedVet.fullName}. Janji tetap dapat diajukan untuk jadwal khusus.',
                                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Keluhan / Alasan Kunjungan *',
                      hintText: 'Misal: Kucing lemas, tidak mau makan 2 hari',
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Keluhan wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),

                  BouncyTap(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: apptVM.isLoading ? null : _submit,
                        child: apptVM.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEdit ? 'Simpan Perubahan' : 'Konfirmasi Booking'),
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
