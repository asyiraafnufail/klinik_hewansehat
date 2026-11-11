import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/veterinarian_model.dart';
import '../../viewmodels/clinic_viewmodel.dart';

class VetFormView extends StatefulWidget {
  final VeterinarianModel? vet;
  const VetFormView({super.key, this.vet});

  @override
  State<VetFormView> createState() => _VetFormViewState();
}

class _VetFormViewState extends State<VetFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  final List<String> _allDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  late List<String> _selectedDays;
  bool _isAvailable = true;

  bool get isEdit => widget.vet != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final v = widget.vet!;
      _nameController.text = v.fullName;
      _specController.text = v.specialization;
      _licenseController.text = v.licenseNumber;
      _phoneController.text = v.phone ?? '';
      _bioController.text = v.bio ?? '';
      _selectedDays = List.from(v.scheduleDays);
      _isAvailable = v.isAvailable;
    } else {
      _selectedDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ClinicViewModel>();
    final vet = VeterinarianModel(
      id: widget.vet?.id ?? '',
      fullName: _nameController.text.trim(),
      specialization: _specController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      scheduleDays: _selectedDays,
      isAvailable: _isAvailable,
    );

    final ok = await vm.saveVet(vet);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Data dokter diperbarui' : 'Dokter ditambahkan')),
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
    final vm = context.watch<ClinicViewModel>();
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Dokter Hewan' : 'Tambah Dokter Hewan')),
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap & Gelar *'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specController,
                    decoration: const InputDecoration(labelText: 'Spesialisasi *'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Spesialisasi wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(labelText: 'Nomor SIP / Izin Praktek *'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Nomor SIP wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Hari Praktek:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _allDays.map((day) {
                      final selected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Bio Singkat'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sedang Aktif Praktek'),
                    value: _isAvailable,
                    onChanged: (val) => setState(() => _isAvailable = val),
                  ),
                  const SizedBox(height: 20),
                  BouncyTap(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: vm.isLoading ? null : _submit,
                        child: vm.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Data Dokter'),
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
