import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pet_viewmodel.dart';

class PetListView extends StatefulWidget {
  const PetListView({super.key});

  @override
  State<PetListView> createState() => _PetListViewState();
}

class _PetListViewState extends State<PetListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().fetchPets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petVM = context.watch<PetViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(authVM.isAdmin ? 'Data Semua Pasien Hewan' : 'Hewan Peliharaan Saya'),
      ),
      floatingActionButton: BouncyTap(
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah Hewan'),
          onPressed: () => context.push('/pets/form'),
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
                  hintText: 'Cari nama, spesies, atau ras hewan...',
                  onChanged: (val) => petVM.setSearch(val),
                  onClear: () {
                    _searchController.clear();
                    petVM.fetchPets(clearFirst: true);
                  },
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  reverseDuration: Duration.zero,
                  switchInCurve: Curves.easeOutCubic,
                  child: Builder(
                    key: ValueKey('pets_${petVM.isLoading && petVM.pets.isEmpty}_${petVM.pets.isEmpty}'),
                    builder: (context) {
                      if (petVM.isLoading && petVM.pets.isEmpty) {
                        return const GlassSkeletonList();
                      }
                      if (petVM.errorMessage != null && petVM.pets.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: ${petVM.errorMessage}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => petVM.fetchPets(clearFirst: true),
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (petVM.pets.isEmpty) {
                        return const GlassEmptyState(
                          icon: Icons.pets_rounded,
                          title: 'Belum ada data hewan peliharaan',
                          subtitle: 'Tekan tombol di bawah untuk mendaftarkan hewan.',
                        );
                      }

                    return RefreshIndicator(
                      onRefresh: () => petVM.fetchPets(search: _searchController.text),
                      child: ListView.separated(
                        cacheExtent: 320,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(padding, 4, padding, 88),
                        itemCount: petVM.pets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final pet = petVM.pets[index];
                          final hasPhoto = pet.photoUrl != null && pet.photoUrl!.isNotEmpty;
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
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                                backgroundImage: hasPhoto
                                    ? ResizeImage.resizeIfNeeded(
                                        156,
                                        156,
                                        NetworkImage(pet.photoUrl!),
                                      )
                                    : null,
                                onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                                child: !hasPhoto
                                    ? const Icon(Icons.pets, color: Color(0xFF0D9488))
                                    : null,
                              ),
                            title: Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${pet.species} • ${pet.breed ?? "Campuran"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (authVM.isAdmin && pet.ownerName != null)
                                  Text(
                                    'Pemilik: ${pet.ownerName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryTeal),
                            onTap: () => context.push('/pets/detail', extra: pet),
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
