# Product Requirements Document (PRD)
## Aplikasi Mobile Klinik Hewan Sehat

- **Platform Target:** Flutter (Android/iOS)
- **Backend / Database:** Supabase (PostgreSQL Cloud) + REST API
- **Arsitektur:** MVVM (Model - View - ViewModel)
- **Role Pengguna:** 2 Role — `admin` (Pengelola Klinik) dan `pet_owner` (Pengunjung / Pemilik Hewan)
- **Acuan:** Final Project Guidelines Mobile App Development 2026

---

## 1. Ringkasan & Tujuan Proyek
Aplikasi manajemen layanan klinik hewan peliharaan (*Klinik Hewan Sehat*) yang menghubungkan **Pemilik Hewan / Pengunjung** dengan **Admin Klinik** untuk pendataan hewan peliharaan, reservasi janji temu dokter, melihat direktori dokter & tarif layanan, serta pengelolaan rekam medis digital.

---

## 2. Pemetaan 10 Kebutuhan Wajib (Guidelines 2026)

| No | Kategori | Ketentuan Panduan | Solusi Implementasi |
|---|---|---|---|
| 1 | **Authentication** | Login & register, Access Token (JWT), Refresh Token | Supabase Auth (Email & Password), otomatis mengelola JWT Access Token & Refresh Token rotasi aman. |
| 2 | **Authorization** | Role-based UI / hak akses terbatas | 2 Role: `pet_owner` dan `admin`. Tampilan tab navigasi dan tombol aksi (CRUD) menyesuaikan role user. |
| 3 | **Navigation & Routing** | Multi-page, MVVM | `go_router` + redirect guard berbasis session & role, arsitektur MVVM. |
| 4 | **State Management** | State terpisah dari UI | `provider` (`ChangeNotifier` ViewModels) memisahkan UI widget dari state & API calls. |
| 5 | **Table / Data** | Minimal 4 entitas utama berelasi dengan field dinamis | 6 Entitas: `profiles`, `pets`, `veterinarians`, `services`, `appointments`, `medical_records`. |
| 6 | **Features** | Minimal 5 fitur full CRUDS (Create, Read, Update, Delete, Search) | 1. Hewan Peliharaan (`pets`)<br>2. Janji Temu (`appointments`)<br>3. Rekam Medis (`medical_records`)<br>4. Layanan Klinik (`services`)<br>5. Data Dokter Hewan (`veterinarians`) |
| 7 | **REST API Integration** | Request & parse JSON dari REST API | - Supabase PostgREST API (JSON)<br>- Public Breeds API (`https://api.thecatapi.com/v1/breeds` / `https://dog.ceo/api/breeds/list/all`) untuk autocomplete ras hewan. |
| 8 | **Database** | Minimal MySQL / Postgres Cloud (Room dilarang) | **100% Supabase Cloud PostgreSQL**: Semua data utama (akun, hewan, janji, rekam medis, layanan, dokter) tersimpan di cloud database. |
| 9 | **File Storage** | Simpan dan baca file lokal | **Dual Storage (Cloud Utama + Fitur Unduh Lokal)**:<br>- **Cloud (Utama):** Foto hewan diunggah & disimpan di Supabase Storage (`pet-avatars`).<br>- **Lokal (Syarat Panduan):** Fitur unduh/ekspor bukti janji temu atau rekam medis ke penyimpanan HP (`path_provider`) dan membaca kembali berkas unduhan tersebut. |
| 10 | **UI/UX** | UI/UX matang & konsisten | Material 3, validasi form, loading indicator, empty/error states, dan feedback toast/snackbar. |

---

## 3. Rincian 5 Fitur CRUDS (Create, Read, Update, Delete, Search)

### Fitur 1: Manajemen Hewan Peliharaan (*Pets*)
- **Create:** Pemilik/Admin menambah hewan (nama, jenis/spesies, ras dari REST API, gender, tanggal lahir, berat, foto).
- **Read:** Pemilik melihat daftar hewan miliknya; Admin melihat seluruh pasien hewan di klinik.
- **Update:** Perbarui berat badan, foto, atau catatan kesehatan hewan.
- **Delete:** Hapus data hewan.
- **Search:** Cari hewan berdasarkan nama, spesies, atau ras.

### Fitur 2: Reservasi Janji Temu (*Appointments*)
- **Create:** Pemilik memilih hewan, layanan, dokter, tanggal & jam kunjungan.
- **Read:** Pemilik melihat antrean/riwayat janji miliknya; Admin melihat seluruh jadwal kunjungan harian.
- **Update:** Pemilik bisa ubah jadwal/keluhan saat masih `pending`; Admin ubah status (`pending` -> `confirmed` -> `completed` / `cancelled`).
- **Delete:** Batalkan / hapus reservasi janji temu.
- **Search:** Cari berdasarkan nama hewan, tanggal, atau filter status.

### Fitur 3: Rekam Medis Digital (*Medical Records*)
- **Create:** Admin menginput hasil pemeriksaan dokter (diagnosis, tindakan, resep obat, catatan klinis).
- **Read:** Pemilik membaca riwayat medis hewannya & mengekspor ke berkas lokal; Admin melihat seluruh rekam medis.
- **Update:** Admin memperbarui catatan diagnosis atau resep.
- **Delete:** Admin menghapus entri rekam medis yang salah input.
- **Search:** Cari riwayat medis berdasarkan kata kunci diagnosis atau nama hewan.

### Fitur 4: Katalog Layanan & Tarif Klinik (*Services*)
- **Create:** Admin menambah layanan baru (vaksinasi, grooming, konsultasi, bedah).
- **Read:** Pengunjung/Pemilik & Admin melihat katalog layanan, harga, dan durasi.
- **Update:** Admin mengubah tarif, deskripsi, atau status aktif layanan.
- **Delete:** Admin menghapus paket layanan.
- **Search:** Pencarian layanan berdasarkan nama atau kategori.

### Fitur 5: Direktori Dokter Hewan (*Veterinarians*)
- **Create:** Admin menambahkan data dokter hewan (nama, spesialisasi, nomor SIP, jadwal hari & jam praktek).
- **Read:** Pengunjung/Pemilik & Admin melihat profil dan jadwal praktek dokter.
- **Update:** Admin mengubah jadwal praktek atau status ketersediaan dokter.
- **Delete:** Admin menghapus data dokter.
- **Search:** Cari dokter berdasarkan nama atau spesialisasi.

---

## 4. Integrasi External REST API & Cloud/Local File Storage
- **External REST API:** Pengambilan data JSON ras kucing & anjing dari Public API pada form tambah/edit hewan (parse JSON -> list dropdown searchable).
- **Cloud Storage (Utama - Supabase):** Upload & simpan foto hewan di Supabase Storage Bucket `pet-avatars` (semua aset & data utama tersimpan penuh di cloud).
- **Local File Export (Syarat Wajib Poin 9):** Fitur *"Unduh Bukti / Rekam Medis"* menyimpan salinan dokumen (`.txt`/`.pdf`) dari data cloud ke perangkat lokal (`getApplicationDocumentsDirectory()`) lalu membukanya kembali lewat menu *"Berkas Unduhan"*. Bukan database lokal, melainkan fitur export/download dokumen agar lolos checklist panduan.

---

## 5. Ketentuan GitHub & Progres
- **Nama Repo:** `[4NIMBelakang]_[NamaProject]` (contoh: `1234_KlinikHewanSehat`).
- **Commit:** Minimal 30 commit bertahap selama pengerjaan (dilarang 1x push akhir).
- **Progress Report:** Catat kemajuan fitur mingguan di `README.md`.
