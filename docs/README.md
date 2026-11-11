# Dokumentasi Proyek Final: Klinik Hewan Sehat

Dokumentasi rancangan sistem dan arsitektur aplikasi mobile *Klinik Hewan Sehat* berbasis Flutter dan Supabase (2 Role: **Admin** dan **Pemilik Hewan / Pengunjung**).

## Berkas Dokumentasi
- **[`prd.md`](./prd.md):** Product Requirements Document, pemetaan 10 syarat wajib panduan, spesifikasi 5 fitur CRUDS, dan scope 2 role.
- **[`design.md`](./design.md):** Desain arsitektur teknis MVVM, navigasi & RBAC (Admin vs Pet Owner), local file storage, dan integrasi REST API publik.
- **[`schema.sql`](./schema.sql):** Skrip DDL PostgreSQL untuk Supabase (tabel entitas, relasi FK, enum, RLS policies 2 role, trigger auth aman, indeks pencarian, seed data).

## Checklist Kepatuhan Panduan 2026
- [x] **Autentikasi:** Supabase Auth (JWT Access Token + Refresh Token).
- [x] **Otorisasi (RBAC):** 2 Role (`pet_owner` & `admin`).
- [x] **Arsitektur & Navigasi:** MVVM + `go_router`.
- [x] **State Management:** Terpisah dari UI (`provider`).
- [x] **Entitas Data:** 6 tabel saling berelasi (`profiles`, `veterinarians`, `services`, `pets`, `appointments`, `medical_records`).
- [x] **5 Fitur CRUDS:** Pets, Appointments, Medical Records, Services, Veterinarians.
- [x] **REST API:** Supabase PostgREST + Public Breeds API (TheCatAPI / Dog CEO API).
- [x] **Database:** 100% Supabase Cloud PostgreSQL (Room/SQLite lokal tidak digunakan).
- [x] **File Storage:** Supabase Cloud Storage (`pet-avatars` untuk foto hewan) + fitur unduh & baca berkas lokal (`path_provider`) untuk bukti/rekam medis agar memenuhi poin 9 panduan.
- [x] **Ketentuan Git:** Minimal 30 commit bertahap, repo `4NIMBelakang_NamaProject`, progress mingguan di `README.md`.
