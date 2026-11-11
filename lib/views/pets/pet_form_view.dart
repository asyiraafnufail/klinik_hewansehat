import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/pet_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pet_viewmodel.dart';

class PetFormView extends StatefulWidget {
  final PetModel? pet;
  const PetFormView({super.key, this.pet});

  @override
  State<PetFormView> createState() => _PetFormViewState();
}

class _PetFormViewState extends State<PetFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _speciesOptions = ['Kucing', 'Anjing', 'Kelinci', 'Burung', 'Lainnya'];
  String _selectedSpecies = 'Kucing';
  String _selectedGender = 'Jantan';
  String? _selectedOwnerId;
  DateTime? _birthDate;
  Uint8List? _pickedPhotoBytes;
  String? _pickedPhotoExt;

  bool get isEdit => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewModel>();
    if (isEdit) {
      final p = widget.pet!;
      _nameController.text = p.name;
      _selectedSpecies = _speciesOptions.contains(p.species) ? p.species : 'Lainnya';
      _breedController.text = p.breed ?? '';
      _selectedGender = p.gender ?? 'Jantan';
      _selectedOwnerId = p.ownerId;
      _birthDate = p.birthDate;
      if (p.weightKg != null) _weightController.text = p.weightKg.toString();
      _notesController.text = p.notes ?? '';
    } else {
      _selectedOwnerId = authVM.currentUserId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().loadBreeds(_selectedSpecies);
      if (authVM.isAdmin) {
        context.read<AuthViewModel>().fetchProfiles();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last;
    setState(() {
      _pickedPhotoBytes = bytes;
      _pickedPhotoExt = ext;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authVM = context.read<AuthViewModel>();
    final petVM = context.read<PetViewModel>();
    final ownerId = (authVM.isAdmin ? _selectedOwnerId : null) ??
        widget.pet?.ownerId ??
        authVM.currentUserId;
    if (ownerId == null) return;

    final weight = _weightController.text.trim().isEmpty
        ? null
        : double.tryParse(_weightController.text.trim());

    final ok = await petVM.savePet(
      id: widget.pet?.id,
      ownerId: ownerId,
      name: _nameController.text,
      species: _selectedSpecies,
      breed: _breedController.text,
      gender: _selectedGender,
      birthDate: _birthDate,
      weightKg: weight,
      notes: _notesController.text,
      photoBytes: _pickedPhotoBytes,
      photoExt: _pickedPhotoExt,
      existingPhotoUrl: widget.pet?.photoUrl,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Data hewan diperbarui' : 'Hewan berhasil ditambahkan')),
      );
      context.pop();
    } else if (petVM.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(petVM.errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final petVM = context.watch<PetViewModel>();
    final padding = AppTheme.pagePadding(context);
    final isVeryNarrow = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Data Hewan' : 'Tambah Hewan Peliharaan')),
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
            child: ResponsiveBody(
              maxWidth: 520,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: Column(
                        children: [
                          // Foto Hewan (Supabase Cloud Storage)
                          Center(
                            child: BouncyTap(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF99F6E4), width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x140D9488),
                                          blurRadius: 16,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: AppTheme.primarySoft,
                                      backgroundImage: _pickedPhotoBytes != null
                                          ? MemoryImage(_pickedPhotoBytes!)
                                          : (widget.pet?.photoUrl != null
                                              ? NetworkImage(widget.pet!.photoUrl!) as ImageProvider
                                              : null),
                                      child: _pickedPhotoBytes == null && widget.pet?.photoUrl == null
                                          ? const Icon(Icons.pets_rounded, size: 40, color: AppTheme.primaryDark)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryTeal,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ketuk foto untuk upload ke Cloud Storage',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      index: 1,
                      child: Container(
                        decoration: AppTheme.glassBoxDecoration(radius: 24),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                  if (authVM.isAdmin) ...[
                    DropdownButtonFormField<String>(
                      value: authVM.profiles.any((p) => p.id == _selectedOwnerId)
                          ? _selectedOwnerId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pemilik Hewan *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: authVM.profiles
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.fullName} (${p.email})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedOwnerId = val),
                      validator: (val) => val == null ? 'Wajib memilih pemilik hewan' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama Hewan *'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Nama hewan wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedSpecies,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Jenis / Spesies *'),
                    items: _speciesOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _selectedSpecies = val);
                      _breedController.clear();
                      petVM.loadBreeds(val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Autocomplete Ras Hewan dari Public REST API (Kategori 7 Panduan)
                  Autocomplete<String>(
                    key: ValueKey(_selectedSpecies),
                    initialValue: TextEditingValue(text: _breedController.text),
                    optionsBuilder: (textEditingValue) {
                      final list = petVM.breeds;
                      if (textEditingValue.text.isEmpty) return list;
                      final query = textEditingValue.text.toLowerCase();
                      return list.where((b) => b.toLowerCase().contains(query));
                    },
                    onSelected: (selection) => _breedController.text = selection,
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (val) => _breedController.text = val,
                        decoration: InputDecoration(
                          labelText: 'Ras / Breed (via REST API)',
                          suffixIcon: petVM.isBreedLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.refresh, size: 18),
                                  tooltip: 'Muat ulang data ras dari API',
                                  onPressed: () => petVM.loadBreeds(_selectedSpecies),
                                ),
                          helperText: petVM.isBreedLoading
                              ? 'Memuat ras dari REST API...'
                              : (petVM.isBreedFromFallback
                                  ? 'Mode offline/lokal: ${petVM.breeds.length} ras tersedia'
                                  : 'REST API: ${petVM.breeds.length} ras tersedia'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                    items: const [
                      DropdownMenuItem(value: 'Jantan', child: Text('Jantan')),
                      DropdownMenuItem(value: 'Betina', child: Text('Betina')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGender = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  if (isVeryNarrow) ...[
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Berat (kg)'),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Berat harus > 0';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Lahir',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          _birthDate != null
                              ? DateFormat('dd MMM yyyy').format(_birthDate!)
                              : 'Pilih tanggal',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Berat (kg)'),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                final parsed = double.tryParse(val.trim());
                                if (parsed == null || parsed <= 0) {
                                  return 'Berat harus > 0';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickBirthDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Lahir',
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(
                                _birthDate != null
                                    ? DateFormat('dd MMM yyyy').format(_birthDate!)
                                    : 'Pilih tanggal',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Catatan Khusus / Alergi'),
                  ),
                  const SizedBox(height: 24),

                  BouncyTap(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: petVM.isLoading ? null : _submit,
                        child: petVM.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEdit ? 'Simpan Perubahan' : 'Daftarkan Hewan'),
                      ),
                    ),
                  ),
                          ],
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
    );
  }
}
