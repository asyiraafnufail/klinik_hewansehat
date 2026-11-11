# Technical Architecture & UI/UX Design
## Klinik Hewan Sehat (Flutter + Supabase — 2 Roles)

---

## 1. Struktur Folder MVVM
Menggunakan pola **MVVM (Model - View - ViewModel)** dengan `provider` agar mudah dipahami dan dipelihara.

```text
lib/
├── core/
│   ├── config/          # Supabase init, constants, AppTheme (Material 3)
│   ├── network/         # HTTP client untuk Public Breeds API
│   ├── router/          # GoRouter + Auth & Role Redirect Guards
│   └── storage/         # Local file helper (path_provider)
├── data/
│   ├── models/          # Data classes + fromJson/toJson (Profile, Pet, Vet, Service, Appointment, MedicalRecord)
│   └── repositories/    # Supabase PostgREST, Auth, Storage, & External REST API calls
├── viewmodels/          # ChangeNotifier per domain (AuthVM, PetVM, AppointmentVM, RecordVM, ServiceVM, VetVM)
└── views/
    ├── auth/            # Splash, Login, Register
    ├── owner/           # Dashboard Pengunjung/Pemilik, Kelola Hewan, Booking Janji, Rekam Medis + Export Lokal
    ├── admin/           # Dashboard Admin, Kelola Antrean Janji, Input Rekam Medis, Kelola Layanan & Dokter
    └── shared/          # Katalog Layanan, Direktori Dokter, Berkas Lokal Tersimpan, Profil User
```

---

## 2. Alur Autentikasi & Role Guard (`admin` vs `pet_owner`)
1. **Login / Register:**
   - `supabase.auth.signInWithPassword` / `signUp`.
   - SDK menyimpan JWT `access_token` dan menjalankan `refresh_token` otomatis.
   - Semua pendaftar baru via aplikasi otomatis mendapat role `pet_owner` di tabel `profiles` (role `admin` di-assign di backend/SQL agar aman).
2. **Role Routing:**
   - Saat login berhasil, `AuthViewModel` mengambil data `profiles` user.
   - **`pet_owner` (Pengunjung / Pemilik Hewan):**
     - BottomNav: `Beranda` | `Hewan Saya` | `Janji Temu` | `Klinik` (Layanan & Dokter) | `Profil & Berkas`
   - **`admin` (Admin Klinik):**
     - BottomNav: `Dashboard` | `Janji Temu` | `Rekam Medis` | `Master` (Layanan, Dokter, Pasien) | `Profil`

---

## 3. Matriks Hak Akses (Role-Based UI)

| Fitur (CRUDS) | `pet_owner` (Pemilik / Pengunjung) | `admin` (Pengelola Klinik) |
|---|---|---|
| **Hewan Peliharaan (`pets`)** | CRUDS milik sendiri | CRUDS semua pasien hewan |
| **Janji Temu (`appointments`)** | Create, Read, Update (jadwal sendiri saat pending), Delete/Batal, Search | CRUDS semua janji & konfirmasi status |
| **Rekam Medis (`medical_records`)** | Read, Search, Simpan & Baca File Lokal | CRUDS penuh |
| **Layanan Klinik (`services`)** | Read, Search | CRUDS penuh |
| **Dokter Hewan (`veterinarians`)** | Read, Search | CRUDS penuh |

---

## 4. Integrasi Eksternal & Cloud/Local File Storage

### A. Public REST API (`http`)
- **Sumber:** `https://api.thecatapi.com/v1/breeds` & `https://dog.ceo/api/breeds/list/all`
- **Alur:** `PetFormView` memanggil `PetViewModel.loadBreeds(species)` -> `BreedApiRepository` fetch JSON -> parse ke `List<String>` -> tampil sebagai pilihan ras saat menambah hewan.

### B. Cloud Storage Utama (Supabase) & Fitur Unduh Lokal
- **Source of Truth (100% Cloud Supabase):** Seluruh data entitas tersimpan di Supabase PostgreSQL dan foto hewan disimpan di Supabase Storage Bucket `pet-avatars`.
- **Fitur Unduh & Baca Berkas Lokal (`path_provider` — Syarat Poin 9 Panduan):**
  - **Save:** User menekan tombol *"Unduh Bukti/Rekam Medis"* -> menyimpan salinan ringkasan dari Supabase ke `getApplicationDocumentsDirectory()/downloads/record_<id>.txt`.
  - **Read:** Halaman *"Berkas Unduhan"* membaca isi berkas yang sudah diunduh ke perangkat.

---

## 5. Standar UI/UX
- **Material 3 Theme:** Warna utama teal medis (`#0D9488`) + aksen hangat amber/coral.
- **Form Validation:** Validasi email, password minimal 6 karakter, input wajib tidak boleh kosong, berat hewan angka positif, tanggal booking minimal hari ini.
- **Feedback State:** `Loading` (CircularProgressIndicator), `Empty` (ikon + tombol aksi cepat), `Error` (pesan error + tombol Coba Lagi), `Success` (SnackBar).
