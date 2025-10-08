-- =====================================================
-- AIVIA Database - Seed Data (Optional)
-- Version: 1.0.0
-- Date: 8 Oktober 2025
-- Description: Data dummy untuk testing dan development
-- WARNING: Hanya untuk development, JANGAN run di production!
-- =====================================================

-- =====================================================
-- IMPORTANT: Only for Development
-- =====================================================
-- File ini berisi data dummy untuk:
-- 1. Testing aplikasi tanpa harus register manual
-- 2. Demo kepada client
-- 3. Development dengan data realistis
--
-- JANGAN JALANKAN DI PRODUCTION!
-- =====================================================

-- =====================================================
-- STEP 1: Insert Test Users ke auth.users
-- =====================================================

-- Note: Dalam production, users akan dibuat via Supabase Auth API
-- Untuk testing, kita insert langsung dengan encrypted password

-- Password untuk semua test users: "password123"
-- Hashed dengan bcrypt

DO $$
DECLARE
  patient1_id UUID := 'a0000000-0000-0000-0000-000000000001';
  patient2_id UUID := 'a0000000-0000-0000-0000-000000000002';
  family1_id UUID := 'b0000000-0000-0000-0000-000000000001';
  family2_id UUID := 'b0000000-0000-0000-0000-000000000002';
  admin_id UUID := 'c0000000-0000-0000-0000-000000000001';
BEGIN
  -- Insert Patient 1: Budi Santoso
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud
  ) VALUES (
    patient1_id,
    '00000000-0000-0000-0000-000000000000',
    'budi@patient.com',
    '$2a$10$IzQKvABfEd7h7L0KvKvZ6OUoQWZm4p9WhW4L3aEuFm0s1Zf4vJwNS', -- "password123"
    NOW(),
    '{"full_name": "Budi Santoso", "user_role": "patient"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ) ON CONFLICT (id) DO NOTHING;

  -- Insert Patient 2: Siti Rahayu
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud
  ) VALUES (
    patient2_id,
    '00000000-0000-0000-0000-000000000000',
    'siti@patient.com',
    '$2a$10$IzQKvABfEd7h7L0KvKvZ6OUoQWZm4p9WhW4L3aEuFm0s1Zf4vJwNS',
    NOW(),
    '{"full_name": "Siti Rahayu", "user_role": "patient"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ) ON CONFLICT (id) DO NOTHING;

  -- Insert Family 1: Ahmad (Anak Budi)
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud
  ) VALUES (
    family1_id,
    '00000000-0000-0000-0000-000000000000',
    'ahmad@family.com',
    '$2a$10$IzQKvABfEd7h7L0KvKvZ6OUoQWZm4p9WhW4L3aEuFm0s1Zf4vJwNS',
    NOW(),
    '{"full_name": "Ahmad Santoso", "user_role": "family"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ) ON CONFLICT (id) DO NOTHING;

  -- Insert Family 2: Dewi (Anak Siti)
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud
  ) VALUES (
    family2_id,
    '00000000-0000-0000-0000-000000000000',
    'dewi@family.com',
    '$2a$10$IzQKvABfEd7h7L0KvKvZ6OUoQWZm4p9WhW4L3aEuFm0s1Zf4vJwNS',
    NOW(),
    '{"full_name": "Dewi Rahayu", "user_role": "family"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ) ON CONFLICT (id) DO NOTHING;

  -- Insert Admin
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud
  ) VALUES (
    admin_id,
    '00000000-0000-0000-0000-000000000000',
    'admin@aivia.com',
    '$2a$10$IzQKvABfEd7h7L0KvKvZ6OUoQWZm4p9WhW4L3aEuFm0s1Zf4vJwNS',
    NOW(),
    '{"full_name": "Admin AIVIA", "user_role": "admin"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ) ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE '✅ Test users created:';
  RAISE NOTICE '   - budi@patient.com (Patient)';
  RAISE NOTICE '   - siti@patient.com (Patient)';
  RAISE NOTICE '   - ahmad@family.com (Family)';
  RAISE NOTICE '   - dewi@family.com (Family)';
  RAISE NOTICE '   - admin@aivia.com (Admin)';
  RAISE NOTICE '   Password untuk semua: password123';
END $$;

-- =====================================================
-- STEP 2: Profiles akan auto-created via trigger
-- =====================================================
-- Trigger handle_new_user() akan otomatis create profiles

-- Tapi kita update dengan data lebih lengkap
UPDATE public.profiles SET
  phone_number = '081234567890',
  date_of_birth = '1950-05-15',
  address = 'Jl. Merdeka No. 123, Jakarta Pusat'
WHERE email = 'budi@patient.com';

UPDATE public.profiles SET
  phone_number = '081234567891',
  date_of_birth = '1948-08-20',
  address = 'Jl. Sudirman No. 45, Bandung'
WHERE email = 'siti@patient.com';

UPDATE public.profiles SET
  phone_number = '081234567892',
  date_of_birth = '1975-03-10',
  address = 'Jl. Gatot Subroto No. 78, Jakarta Selatan'
WHERE email = 'ahmad@family.com';

UPDATE public.profiles SET
  phone_number = '081234567893',
  date_of_birth = '1978-11-25',
  address = 'Jl. Asia Afrika No. 90, Bandung'
WHERE email = 'dewi@family.com';

-- =====================================================
-- STEP 3: Patient-Family Links
-- =====================================================

INSERT INTO public.patient_family_links (
  patient_id,
  family_member_id,
  relationship_type,
  is_primary_caregiver,
  can_edit_activities,
  can_view_location
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com'),
    'Anak',
    TRUE,
    TRUE,
    TRUE
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'siti@patient.com'),
    (SELECT id FROM public.profiles WHERE email = 'dewi@family.com'),
    'Anak',
    TRUE,
    TRUE,
    TRUE
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 4: Activities untuk Budi
-- =====================================================
-- Note: Semua activities dibuat untuk masa depan (sesuai constraint)
-- Untuk demo completed activities, bisa complete manual di aplikasi

INSERT INTO public.activities (
  patient_id,
  title,
  description,
  activity_time,
  reminder_minutes_before,
  is_completed,
  created_by
) VALUES
  -- Activities hari ini
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Makan Pagi',
    'Sarapan dengan telur rebus dan roti gandum. Jangan lupa minum obat diabetes.',
    NOW() + INTERVAL '1 hour',
    15,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Minum Obat Pagi',
    'Metformin 500mg dan Aspirin 100mg setelah makan.',
    NOW() + INTERVAL '1.5 hours',
    10,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Jalan Pagi di Taman',
    'Jalan santai 30 menit di Taman Suropati. Ahmad akan menemani.',
    NOW() + INTERVAL '2 hours',
    20,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Makan Siang',
    'Nasi dengan sayur dan ikan. Porsi sedang.',
    NOW() + INTERVAL '5 hours',
    15,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Tidur Siang',
    'Istirahat 1-2 jam setelah makan siang.',
    NOW() + INTERVAL '6 hours',
    10,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Terapi Fisik',
    'Sesi terapi fisik dengan Pak Budi (terapis) di rumah. Durasi 1 jam.',
    NOW() + INTERVAL '8 hours',
    30,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Makan Malam',
    'Sup ayam dengan sayuran. Hindari makanan pedas.',
    NOW() + INTERVAL '12 hours',
    15,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Minum Obat Malam',
    'Metformin 500mg setelah makan malam.',
    NOW() + INTERVAL '12.5 hours',
    10,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  -- Activities besok
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Pertemuan Keluarga',
    'Kumpul keluarga besar di rumah. Ahmad, Ratna, dan cucu-cucu akan datang.',
    NOW() + INTERVAL '1 day' + INTERVAL '3 hours',
    30,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Senam Lansia',
    'Senam bersama di balai RW. Diantar oleh Ahmad.',
    NOW() + INTERVAL '2 days' + INTERVAL '1 hour',
    20,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Kontrol Dokter Bulanan',
    'Kontrol rutin ke Dr. Wijaya. Jangan lupa bawa hasil lab.',
    NOW() + INTERVAL '3 days' + INTERVAL '2 hours',
    60,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com')
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 5: Activities untuk Siti
-- =====================================================

INSERT INTO public.activities (
  patient_id,
  title,
  description,
  activity_time,
  reminder_minutes_before,
  is_completed,
  created_by
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'siti@patient.com'),
    'Senam Pagi',
    'Senam ringan untuk lansia. Durasi 30 menit.',
    NOW() + INTERVAL '1 hour',
    20,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'dewi@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'siti@patient.com'),
    'Makan Siang Bersama',
    'Makan siang bersama Dewi di restoran favorit.',
    NOW() + INTERVAL '4 hours',
    30,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'dewi@family.com')
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'siti@patient.com'),
    'Kontrol ke Dokter',
    'Kontrol rutin bulanan di RS. Dewi akan mengantarkan.',
    NOW() + INTERVAL '2 days',
    60,
    FALSE,
    (SELECT id FROM public.profiles WHERE email = 'dewi@family.com')
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 6: Known Persons untuk Budi
-- =====================================================

-- Note: face_embedding akan di-generate saat upload foto di aplikasi
-- Untuk seed data, kita buat dummy embedding (random vector)

INSERT INTO public.known_persons (
  owner_id,
  full_name,
  relationship,
  bio,
  photo_url,
  face_embedding
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Ahmad Santoso',
    'Anak',
    'Anak pertama Bapak. Bekerja sebagai dokter di RS Siloam. Sering mengunjungi setiap akhir pekan.',
    'https://placeholder.com/ahmad.jpg',
    (SELECT array_agg(random())::vector FROM generate_series(1, 512))
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Ratna Santoso',
    'Istri',
    'Istri tercinta. Sudah menikah 45 tahun. Suka memasak dan berkebun bersama.',
    'https://placeholder.com/ratna.jpg',
    (SELECT array_agg(random())::vector FROM generate_series(1, 512))
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'Dr. Wijaya',
    'Dokter',
    'Dokter keluarga yang sudah merawat selama 10 tahun. Ramah dan sabar.',
    'https://placeholder.com/dokter.jpg',
    (SELECT array_agg(random())::vector FROM generate_series(1, 512))
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 7: Locations untuk Budi (simulasi tracking)
-- =====================================================

-- Jakarta coordinates: -6.2088, 106.8456 (Monas area)
INSERT INTO public.locations (
  patient_id,
  coordinates,
  accuracy,
  battery_level,
  timestamp
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    ST_SetSRID(ST_MakePoint(106.8456, -6.2088), 4326)::geography,
    10.5,
    85,
    NOW() - INTERVAL '1 minute'
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    ST_SetSRID(ST_MakePoint(106.8457, -6.2089), 4326)::geography,
    12.3,
    85,
    NOW() - INTERVAL '5 minutes'
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    ST_SetSRID(ST_MakePoint(106.8458, -6.2090), 4326)::geography,
    8.7,
    84,
    NOW() - INTERVAL '10 minutes'
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 8: Emergency Contacts
-- =====================================================

INSERT INTO public.emergency_contacts (
  patient_id,
  contact_id,
  priority,
  notification_enabled
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com'),
    1,
    TRUE
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'siti@patient.com'),
    (SELECT id FROM public.profiles WHERE email = 'dewi@family.com'),
    1,
    TRUE
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 9: Sample Emergency Alert (Resolved)
-- =====================================================

INSERT INTO public.emergency_alerts (
  patient_id,
  location,
  message,
  alert_type,
  status,
  severity,
  notes,
  resolved_by,
  created_at,
  acknowledged_at,
  resolved_at
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    ST_SetSRID(ST_MakePoint(106.8456, -6.2088), 4326)::geography,
    'Test Emergency Alert - False Alarm',
    'panic_button',
    'resolved',
    'medium',
    'Ternyata tidak ada apa-apa. Pak Budi tidak sengaja menekan tombol.',
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com'),
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days' + INTERVAL '2 minutes',
    NOW() - INTERVAL '2 days' + INTERVAL '15 minutes'
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 10: Sample Notifications
-- =====================================================

INSERT INTO public.notifications (
  user_id,
  notification_type,
  title,
  body,
  data,
  is_read,
  is_sent,
  sent_at,
  created_at
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    'activity_reminder',
    '⏰ Pengingat Aktivitas',
    'Jangan lupa: Makan Pagi dalam 15 menit',
    '{"activity_id": "dummy-id"}'::jsonb,
    FALSE,
    TRUE,
    NOW() - INTERVAL '5 minutes',
    NOW() - INTERVAL '5 minutes'
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'ahmad@family.com'),
    'activity_created',
    '✅ Aktivitas Berhasil Dibuat',
    'Aktivitas "Makan Pagi" berhasil ditambahkan untuk Budi',
    '{"patient_id": "dummy-id"}'::jsonb,
    TRUE,
    TRUE,
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day'
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 11: Sample Face Recognition Log
-- =====================================================

INSERT INTO public.face_recognition_logs (
  patient_id,
  recognized_person_id,
  similarity_score,
  is_recognized,
  timestamp
) VALUES
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    (SELECT id FROM public.known_persons WHERE full_name = 'Ahmad Santoso' LIMIT 1),
    0.92,
    TRUE,
    NOW() - INTERVAL '2 hours'
  ),
  (
    (SELECT id FROM public.profiles WHERE email = 'budi@patient.com'),
    (SELECT id FROM public.known_persons WHERE full_name = 'Ratna Santoso' LIMIT 1),
    0.88,
    TRUE,
    NOW() - INTERVAL '5 hours'
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
DECLARE
  users_count INTEGER;
  activities_count INTEGER;
  known_persons_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO users_count FROM public.profiles;
  SELECT COUNT(*) INTO activities_count FROM public.activities;
  SELECT COUNT(*) INTO known_persons_count FROM public.known_persons;
  
  RAISE NOTICE '✅ Seed data created successfully!';
  RAISE NOTICE '👥 Users: %', users_count;
  RAISE NOTICE '📝 Activities: %', activities_count;
  RAISE NOTICE '👤 Known Persons: %', known_persons_count;
  RAISE NOTICE '';
  RAISE NOTICE '🔐 Test Login Credentials:';
  RAISE NOTICE '   Email: budi@patient.com | Password: password123 (Patient)';
  RAISE NOTICE '   Email: siti@patient.com | Password: password123 (Patient)';
  RAISE NOTICE '   Email: ahmad@family.com | Password: password123 (Family)';
  RAISE NOTICE '   Email: dewi@family.com | Password: password123 (Family)';
  RAISE NOTICE '   Email: admin@aivia.com | Password: password123 (Admin)';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Database setup COMPLETE! Ready untuk development.';
END $$;
