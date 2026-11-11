import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profile = authVM.profile;
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: GlassBackground(
        child: SafeArea(
          child: ResponsiveBody(
            maxWidth: 520,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
              children: [
                FadeSlideIn(
                  index: 0,
                  child: Container(
                    decoration: AppTheme.glassBoxDecoration(radius: 22),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFCCFBF1), Color(0xFFE0F2FE)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF99F6E4), width: 1.4),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.fullName.isNotEmpty == true
                                    ? profile!.fullName
                                    : 'Pengguna',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile?.email ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              StatusPillBadge(
                                label: authVM.isAdmin ? 'ADMIN KLINIK' : 'PEMILIK HEWAN',
                                textColor: authVM.isAdmin
                                    ? const Color(0xFF6B21A8)
                                    : const Color(0xFF0F766E),
                                bgColor: authVM.isAdmin
                                    ? const Color(0xFFFAF5FF)
                                    : const Color(0xFFF0FDFA),
                                borderColor: authVM.isAdmin
                                    ? const Color(0xFFE9D5FF)
                                    : const Color(0xFF99F6E4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Menu Berkas Lokal Tersimpan (Syarat File Storage Poin 9)
                FadeSlideIn(
                  index: 1,
                  child: BouncyTap(
                    child: Container(
                      decoration: AppTheme.glassBoxDecoration(radius: 22),
                      child: Material(
                        type: MaterialType.transparency,
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primarySoft,
                            child: Icon(Icons.folder_open_rounded, color: AppTheme.primaryDark),
                          ),
                          title: const Text(
                            'Berkas Unduhan Lokal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Baca salinan rekam medis tersimpan di HP'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryTeal),
                          onTap: () => context.push('/files'),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Card Bukti Syarat Panduan 2026: Access Token (JWT) & Refresh Token
                FadeSlideIn(
                  index: 2,
                  child: Container(
                    decoration: AppTheme.glassBoxDecoration(radius: 22),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security_rounded, size: 20, color: Color(0xFF0F172A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Status Token Sesi (Syarat Panduan 1)',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildTokenRow(
                          context,
                          title: 'Access Token (JWT):',
                          token: authVM.accessToken,
                        ),
                        const SizedBox(height: 12),
                        _buildTokenRow(
                          context,
                          title: 'Refresh Token:',
                          token: authVM.refreshToken,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                FadeSlideIn(
                  index: 3,
                  child: BouncyTap(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFB91C1C)),
                        label: const Text(
                          'Keluar (Sign Out)',
                          style: TextStyle(color: Color(0xFFB91C1C)),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
                          side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Konfirmasi Keluar'),
                              content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Keluar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await authVM.signOut();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenRow(BuildContext context, {required String title, String? token}) {
    final preview = token != null && token.isNotEmpty
        ? '${token.substring(0, token.length > 28 ? 28 : token.length)}...'
        : 'Tidak ada token aktif';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  preview,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
            if (token != null && token.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Salin Token',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token disalin ke clipboard')),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
