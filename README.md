# Klinik Hewan Sehat (Flutter + Supabase)

Aplikasi manajemen klinik hewan berbasis mobile (Flutter) dengan pola arsitektur **MVVM** dan backend **Supabase Cloud** (PostgreSQL + Auth + Cloud Storage), disusun sebagai referensi proyek akhir sesuai panduan *Final Project Guidelines 2026*.

## Fitur Utama & Pemenuhan Syarat Panduan
1. **Authentication (JWT & Refresh Token):** Login & Register via Supabase Auth + tampilan status token di halaman Akun.
2. **Authorization (RBAC 2 Role):** Role `pet_owner` (Pengunjung/Pemilik Hewan) dan `admin` (Pengelola Klinik) dengan navigasi & aksi terpisah.
3. **Navigation & Architecture:** `go_router` dengan route guard + pola **MVVM** (`provider` ChangeNotifier).
4. **5+ Entitas Terhubung:** `profiles`, `pets`, `veterinarians`, `services`, `appointments`, `medical_records`.
5. **5 Fitur Full CRUDS (Create, Read, Update, Delete, Search):**
   - Manajemen Hewan Peliharaan (`pets`)
   - Reservasi Janji Temu (`appointments`)
   - Rekam Medis Digital (`medical_records`)
   - Katalog Layanan & Tarif (`services`)
   - Direktori Dokter Hewan (`veterinarians`)
6. **Public REST API Integration:** Pengambilan & parsing JSON daftar ras kucing/anjing (TheCatAPI & Dog CEO API) pada form tambah hewan.
7. **Database Cloud:** 100% Supabase Cloud PostgreSQL + Row Level Security (RLS).
8. **File Storage:**
   - Cloud Storage (`pet-avatars`) untuk foto hewan.
   - Local Storage (`path_provider`) untuk unduh & baca ringkasan rekam medis offline.

## Progress Report (Tracking Panduan)
| Minggu | Tanggal | Fitur / Progres | Status |
|---|---|---|---|
| 1 | 2026-11-11 | Perancangan PRD, Design MVVM, Schema SQL Supabase (`docs/`), Setup Auth, 5 Fitur CRUDS, REST API, File Storage, dan Unit Tests | Selesai |

## Dokumentasi Lengkap
Lihat folder [`docs/`](./docs/README.md) untuk PRD, rancangan arsitektur, dan skrip SQL (`docs/schema.sql`).
