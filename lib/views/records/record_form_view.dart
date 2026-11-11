import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/medical_record_model.dart';
import '../../viewmodels/appointment_viewmodel.dart';
import '../../viewmodels/clinic_viewmodel.dart';
import '../../viewmodels/medical_record_viewmodel.dart';
import '../../viewmodels/pet_viewmodel.dart';

class RecordFormView extends StatefulWidget {
  final MedicalRecordModel? record;
  const RecordFormView({super.key, this.record});

  @override
  State<RecordFormView> createState() => _RecordFormViewState();
}

class _RecordFormViewState extends State<RecordFormView> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPetId;
  String? _selectedVetId;
  DateTime _recordDate = DateTime.now();

  bool get isEdit => widget.record != null && widget.record!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _selectedPetId = r.petId.isNotEmpty ? r.petId : null;
      _selectedVetId = r.vetId?.isNotEmpty == true ? r.vetId : null;
      _recordDate = r.recordDate;
      if (isEdit) {
        _diagnosisController.text = r.diagnosis;
        _treatmentController.text = r.treatment;
        _prescriptionController.text = r.prescription ?? '';
        _notesController.text = r.clinicalNotes ?? '';
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().fetchPets();
      context.read<ClinicViewModel>().fetchVets();
    });
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate.isAfter(now) ? now : _recordDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) setState(() => _recordDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih hewan pasien terlebih dahulu')),
      );
      return;
    }

    final vm = context.read<MedicalRecordViewModel>();
    final ok = await vm.saveRecord(
      id: isEdit ? widget.record!.id : null,
      appointmentId: widget.record?.appointmentId,
      petId: _selectedPetId!,
      vetId: _selectedVetId,
      diagnosis: _diagnosisController.text,
      treatment: _treatmentController.text,
      prescription: _prescriptionController.text,
      clinicalNotes: _notesController.text,
      recordDate: _recordDate,
    );

    if (!mounted) return;
    if (ok) {
      final apptId = widget.record?.appointmentId;
      if (apptId != null && apptId.isNotEmpty && context.mounted) {
        final apptVM = context.read<AppointmentViewModel>();
        final idx = apptVM.appointments.indexWhere((a) => a.id == apptId);
        if (idx == -1 || apptVM.appointments[idx].status != AppointmentStatus.completed) {
          await apptVM.updateStatus(
            id: apptId,
            status: AppointmentStatus.completed,
          );
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Rekam medis diperbarui' : 'Rekam medis tersimpan')),
      );
      context.pop();
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final petVM = context.watch<PetViewModel>();
    final clinicVM = context.watch<ClinicViewModel>();
    final recordVM = context.watch<MedicalRecordViewModel>();
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Rekam Medis' : 'Tambah Rekam Medis')),
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
                  DropdownButtonFormField<String>(
                    value: petVM.pets.any((p) => p.id == _selectedPetId) ? _selectedPetId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Hewan Pasien *'),
                    items: petVM.pets
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} (${p.species})${p.ownerName != null ? " - ${p.ownerName}" : ""}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPetId = val),
                    validator: (val) => val == null ? 'Wajib pilih pasien hewan' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: clinicVM.vets.any((v) => v.id == _selectedVetId) ? _selectedVetId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Dokter Pemeriksa'),
                    items: clinicVM.vets
                        .map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                v.fullName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedVetId = val),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pemeriksaan',
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        DateFormat('dd MMMM yyyy').format(_recordDate),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(labelText: 'Diagnosis *'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Diagnosis wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _treatmentController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Tindakan / Perawatan *'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Tindakan wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _prescriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Resep Obat'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Catatan Klinis Tambahan'),
                  ),
                  const SizedBox(height: 24),

                  BouncyTap(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: recordVM.isLoading ? null : _submit,
                        child: recordVM.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Rekam Medis'),
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
