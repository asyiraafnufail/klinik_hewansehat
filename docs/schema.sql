-- ============================================================================
-- KLINIK HEWAN SEHAT - SUPABASE POSTGRESQL SCHEMA
-- Roles: 'pet_owner' (Pengunjung/Pemilik Hewan) & 'admin' (Pengelola Klinik)
-- Acuan: Final Project Guidelines Mobile App Development 2026
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 2. ENUMS
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('pet_owner', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE appointment_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. PROFILES TABLE (Sync dengan Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    role user_role NOT NULL DEFAULT 'pet_owner',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. VETERINARIANS TABLE (Data Master Dokter Hewan - Dikelola Admin)
CREATE TABLE IF NOT EXISTS public.veterinarians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    specialization TEXT NOT NULL,
    license_number TEXT NOT NULL,
    phone TEXT,
    photo_url TEXT,
    bio TEXT,
    schedule_days TEXT[] DEFAULT ARRAY['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
    start_time TIME NOT NULL DEFAULT '09:00:00',
    end_time TIME NOT NULL DEFAULT '17:00:00',
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. SERVICES TABLE (Katalog Layanan & Tarif Klinik - Dikelola Admin)
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Umum',
    description TEXT,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK (duration_minutes > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. PETS TABLE (Entitas Hewan Peliharaan)
CREATE TABLE IF NOT EXISTS public.pets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    species TEXT NOT NULL, -- Kucing, Anjing, Kelinci, Burung, dll
    breed TEXT,
    gender TEXT CHECK (gender IN ('Jantan', 'Betina')),
    birth_date DATE,
    weight_kg NUMERIC(5, 2) CHECK (weight_kg > 0),
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 7. APPOINTMENTS TABLE (Reservasi Janji Temu)
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    vet_id UUID REFERENCES public.veterinarians(id) ON DELETE SET NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status appointment_status NOT NULL DEFAULT 'pending',
    reason TEXT NOT NULL,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 8. MEDICAL_RECORDS TABLE (Rekam Medis Digital - Input oleh Admin)
CREATE TABLE IF NOT EXISTS public.medical_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    vet_id UUID REFERENCES public.veterinarians(id) ON DELETE SET NULL,
    diagnosis TEXT NOT NULL,
    treatment TEXT NOT NULL,
    prescription TEXT,
    clinical_notes TEXT,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- INDEXES FOR FAST SEARCH (CRUDS Search Requirement)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_vets_name_search ON public.veterinarians USING gin (full_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_vets_spec_search ON public.veterinarians USING gin (specialization gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_services_name_search ON public.services USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_services_category ON public.services(category);

CREATE INDEX IF NOT EXISTS idx_pets_name_search ON public.pets USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_pets_species ON public.pets(species);
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON public.pets(owner_id);

CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(appointment_date, status);
CREATE INDEX IF NOT EXISTS idx_appointments_owner ON public.appointments(owner_id);

CREATE INDEX IF NOT EXISTS idx_medical_records_diagnosis ON public.medical_records USING gin (diagnosis gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_medical_records_pet ON public.medical_records(pet_id);

-- ============================================================================
-- TRIGGERS: AUTO UPDATE TIMESTAMP & AUTH USER SYNC
-- ============================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_vets_updated_at ON public.veterinarians;
CREATE TRIGGER trg_vets_updated_at BEFORE UPDATE ON public.veterinarians FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_services_updated_at ON public.services;
CREATE TRIGGER trg_services_updated_at BEFORE UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_pets_updated_at ON public.pets;
CREATE TRIGGER trg_pets_updated_at BEFORE UPDATE ON public.pets FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_appointments_updated_at ON public.appointments;
CREATE TRIGGER trg_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_medical_records_updated_at ON public.medical_records;
CREATE TRIGGER trg_medical_records_updated_at BEFORE UPDATE ON public.medical_records FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-insert profile saat register (role dikunci ke 'pet_owner' demi keamanan)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        'pet_owner'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES (2 Roles: pet_owner vs admin)
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.veterinarians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_records ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
$$ LANGUAGE sql SECURITY DEFINER;

-- Profiles: user baca/update milik sendiri, admin bisa baca semua
CREATE POLICY "Users view own profile or admin views all"
    ON public.profiles FOR SELECT TO authenticated
    USING (auth.uid() = id OR public.is_admin());
CREATE POLICY "Users update own profile"
    ON public.profiles FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Veterinarians: semua user login baca, admin CRUDS penuh
CREATE POLICY "Veterinarians readable by authenticated users"
    ON public.veterinarians FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin manages veterinarians"
    ON public.veterinarians FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Services: semua user login baca, admin CRUDS penuh
CREATE POLICY "Services readable by authenticated users"
    ON public.services FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin manages services"
    ON public.services FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Pets: pemilik kelola hewan sendiri, admin CRUDS semua
CREATE POLICY "Owners and admin manage pets"
    ON public.pets FOR ALL TO authenticated
    USING (owner_id = auth.uid() OR public.is_admin())
    WITH CHECK (owner_id = auth.uid() OR public.is_admin());

-- Appointments: pemilik kelola janji sendiri, admin CRUDS semua
CREATE POLICY "Users view own appointments or admin all"
    ON public.appointments FOR SELECT TO authenticated
    USING (owner_id = auth.uid() OR public.is_admin());
CREATE POLICY "Owners or admin create appointments"
    ON public.appointments FOR INSERT TO authenticated
    WITH CHECK (owner_id = auth.uid() OR public.is_admin());
CREATE POLICY "Owners or admin update appointments"
    ON public.appointments FOR UPDATE TO authenticated
    USING (owner_id = auth.uid() OR public.is_admin())
    WITH CHECK (owner_id = auth.uid() OR public.is_admin());
CREATE POLICY "Owners or admin delete appointments"
    ON public.appointments FOR DELETE TO authenticated
    USING (owner_id = auth.uid() OR public.is_admin());

-- Medical Records: pemilik hanya baca rekam medis hewannya, admin CRUDS penuh
CREATE POLICY "Owners view own pets medical records"
    ON public.medical_records FOR SELECT TO authenticated
    USING (
        public.is_admin()
        OR EXISTS (
            SELECT 1 FROM public.pets
            WHERE pets.id = medical_records.pet_id AND pets.owner_id = auth.uid()
        )
    );
CREATE POLICY "Admin manages medical records"
    ON public.medical_records FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================================
-- SEED DATA (LAYANAN & DOKTER DUMMY)
-- ============================================================================
INSERT INTO public.services (name, category, description, price, duration_minutes) VALUES
('Pemeriksaan Umum & Konsultasi', 'Konsultasi', 'Pemeriksaan fisik lengkap hewan kesayangan oleh dokter hewan.', 75000, 30),
('Vaksinasi Rabies', 'Vaksinasi', 'Vaksinasi pencegahan rabies untuk anjing dan kucing usia > 3 bulan.', 120000, 20),
('Vaksinasi Tricat Kucing', 'Vaksinasi', 'Imunisasi primer komprehensif untuk kucing.', 180000, 20),
('Grooming Medis & Anti Kutu', 'Perawatan', 'Mandi terapeutik dengan sampo anti-jamur dan pembasmi kutu.', 95000, 60),
('Sterilisasi Kucing Jantan', 'Bedah', 'Tindakan bedah kastrasi kucing jantan dengan anestesi aman.', 350000, 45)
ON CONFLICT DO NOTHING;

INSERT INTO public.veterinarians (full_name, specialization, license_number, phone, bio, schedule_days) VALUES
('drh. Nadia Putri, M.Vet', 'Penyakit Dalam & Vaksinasi', 'SIP-2024-001', '081234567801', 'Berpengalaman 7 tahun menangani kesehatan kucing dan anjing.', ARRAY['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat']),
('drh. Bima Pratama', 'Bedah & Ortopedi Hewan', 'SIP-2024-002', '081234567802', 'Spesialis tindakan bedah minor hingga mayor serta sterilisasi.', ARRAY['Selasa', 'Kamis', 'Sabtu']),
('drh. Sari Kusuma', 'Dermatologi & Hewan Eksotis', 'SIP-2024-003', '081234567803', 'Menangani kelinci, hamster, burung, serta penyakit kulit hewan.', ARRAY['Senin', 'Rabu', 'Jumat', 'Sabtu'])
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SUPABASE CLOUD STORAGE BUCKET (Foto Profil Hewan)
-- ============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('pet-avatars', 'pet-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Kebijakan akses bucket: publik bisa baca URL gambar
DO $$ BEGIN
    CREATE POLICY "Public read pet avatars"
        ON storage.objects FOR SELECT TO public
        USING (bucket_id = 'pet-avatars');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Kebijakan upload/update/hapus: user hanya kelola folder <uid>/... atau admin semua
DO $$ BEGIN
    CREATE POLICY "Users manage own pet avatar folder"
        ON storage.objects FOR ALL TO authenticated
        USING (
            bucket_id = 'pet-avatars'
            AND ((storage.foldername(name))[1] = auth.uid()::text OR public.is_admin())
        )
        WITH CHECK (
            bucket_id = 'pet-avatars'
            AND ((storage.foldername(name))[1] = auth.uid()::text OR public.is_admin())
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- 9. REALTIME REPLICATION (Sinkronisasi Otomatis Admin & Pemilik Hewan)
-- ============================================================================
-- Aktifkan replikasi real-time agar perubahan jadwal, rekam medis, pasien,
-- dan katalog klinik langsung terupdate secara instan di semua perangkat.
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.pets;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN undefined_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN undefined_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.medical_records;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN undefined_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.services;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN undefined_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.veterinarians;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN undefined_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN undefined_object THEN null;
END $$;

-- ============================================================================
-- CARA PROMOSI AKUN JADI ADMIN (Jalankan setelah register 1 akun di aplikasi)
-- ============================================================================
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@klinikhewan.com';
