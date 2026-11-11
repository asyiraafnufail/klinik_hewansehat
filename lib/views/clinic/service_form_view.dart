import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/service_model.dart';
import '../../viewmodels/clinic_viewmodel.dart';

class ServiceFormView extends StatefulWidget {
  final ServiceModel? service;
  const ServiceFormView({super.key, this.service});

  @override
  State<ServiceFormView> createState() => _ServiceFormViewState();
}

class _ServiceFormViewState extends State<ServiceFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descController = TextEditingController();
  bool _isActive = true;

  bool get isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final s = widget.service!;
      _nameController.text = s.name;
      _categoryController.text = s.category;
      _priceController.text = s.price.toStringAsFixed(0);
      _durationController.text = s.durationMinutes.toString();
      _descController.text = s.description ?? '';
      _isActive = s.isActive;
    } else {
      _categoryController.text = 'Konsultasi';
      _durationController.text = '30';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ClinicViewModel>();
    final service = ServiceModel(
      id: widget.service?.id ?? '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      durationMinutes: int.parse(_durationController.text.trim()),
      description: _descController.text.trim(),
      isActive: _isActive,
    );

    final ok = await vm.saveService(service);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Layanan diperbarui' : 'Layanan ditambahkan')),
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
    final isVeryNarrow = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Layanan' : 'Tambah Layanan Klinik')),
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
                    decoration: const InputDecoration(labelText: 'Nama Layanan *'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori *',
                      hintText: 'Konsultasi, Vaksinasi, Grooming, Bedah',
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Kategori wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  if (isVeryNarrow) ...[
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarif (Rp) *'),
                      validator: (val) {
                        final n = double.tryParse(val?.trim() ?? '');
                        if (n == null || n < 0) return 'Tarif tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Durasi (menit) *'),
                      validator: (val) {
                        final n = int.tryParse(val?.trim() ?? '');
                        if (n == null || n <= 0) return 'Durasi tidak valid';
                        return null;
                      },
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Tarif (Rp) *'),
                            validator: (val) {
                              final n = double.tryParse(val?.trim() ?? '');
                              if (n == null || n < 0) return 'Tarif tidak valid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Durasi (menit) *'),
                            validator: (val) {
                              final n = int.tryParse(val?.trim() ?? '');
                              if (n == null || n <= 0) return 'Durasi tidak valid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Deskripsi Layanan'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Layanan Tersedia / Aktif'),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
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
                            : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Layanan'),
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
