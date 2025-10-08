-- =====================================================
-- AIVIA Database - Triggers & Functions
-- Version: 1.0.0
-- Date: 8 Oktober 2025
-- Description: Automation triggers dan helper functions
-- =====================================================

-- =====================================================
-- STEP 1: Function untuk Auto-Create Profile
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    user_role
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'user_role', 'patient')
  );
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Ignore duplicate, profile already exists
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user IS 'Auto-create profile saat user signup';

-- Trigger untuk handle_new_user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- STEP 2: Function untuk Update Timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.update_updated_at_column IS 'Auto-update updated_at timestamp';

-- Trigger untuk profiles
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger untuk activities
DROP TRIGGER IF EXISTS update_activities_updated_at ON public.activities;
CREATE TRIGGER update_activities_updated_at
  BEFORE UPDATE ON public.activities
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger untuk known_persons
DROP TRIGGER IF EXISTS update_known_persons_updated_at ON public.known_persons;
CREATE TRIGGER update_known_persons_updated_at
  BEFORE UPDATE ON public.known_persons
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger untuk fcm_tokens
DROP TRIGGER IF EXISTS update_fcm_tokens_updated_at ON public.fcm_tokens;
CREATE TRIGGER update_fcm_tokens_updated_at
  BEFORE UPDATE ON public.fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- STEP 3: Function untuk Face Recognition Search
-- =====================================================

CREATE OR REPLACE FUNCTION public.find_known_person(
  query_embedding vector(512),
  patient_id UUID,
  similarity_threshold FLOAT DEFAULT 0.85
)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  relationship TEXT,
  bio TEXT,
  photo_url TEXT,
  similarity FLOAT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    kp.id,
    kp.full_name,
    kp.relationship,
    kp.bio,
    kp.photo_url,
    1 - (kp.face_embedding <=> query_embedding) AS similarity
  FROM public.known_persons kp
  WHERE kp.owner_id = patient_id
    AND (1 - (kp.face_embedding <=> query_embedding)) >= similarity_threshold
  ORDER BY kp.face_embedding <=> query_embedding
  LIMIT 1;
END;
$$;

COMMENT ON FUNCTION public.find_known_person IS 'Cari wajah paling mirip dari database known_persons menggunakan cosine similarity';

-- =====================================================
-- STEP 4: Function untuk Update Last Seen Known Person
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_known_person_last_seen()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_recognized = TRUE AND NEW.recognized_person_id IS NOT NULL THEN
    UPDATE public.known_persons
    SET 
      last_seen_at = NEW.timestamp,
      recognition_count = recognition_count + 1
    WHERE id = NEW.recognized_person_id;
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.update_known_person_last_seen IS 'Update last_seen_at dan recognition_count saat wajah berhasil dikenali';

-- Trigger untuk face_recognition_logs
DROP TRIGGER IF EXISTS update_known_person_on_recognition ON public.face_recognition_logs;
CREATE TRIGGER update_known_person_on_recognition
  AFTER INSERT ON public.face_recognition_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_known_person_last_seen();

-- =====================================================
-- STEP 5: Function untuk Get Latest Location
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_latest_location(patient_id_param UUID)
RETURNS TABLE (
  latitude FLOAT,
  longitude FLOAT,
  accuracy FLOAT,
  location_timestamp TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ST_Y(coordinates::geometry) AS latitude,
    ST_X(coordinates::geometry) AS longitude,
    locations.accuracy,
    locations.timestamp AS location_timestamp
  FROM public.locations
  WHERE locations.patient_id = patient_id_param
  ORDER BY locations.timestamp DESC
  LIMIT 1;
END;
$$;

COMMENT ON FUNCTION public.get_latest_location IS 'Dapatkan lokasi terbaru pasien dengan format latitude/longitude';

-- =====================================================
-- STEP 6: Function untuk Calculate Distance
-- =====================================================

CREATE OR REPLACE FUNCTION public.calculate_distance(
  lat1 FLOAT,
  lon1 FLOAT,
  lat2 FLOAT,
  lon2 FLOAT
)
RETURNS FLOAT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  point1 GEOGRAPHY;
  point2 GEOGRAPHY;
BEGIN
  point1 := ST_SetSRID(ST_MakePoint(lon1, lat1), 4326)::geography;
  point2 := ST_SetSRID(ST_MakePoint(lon2, lat2), 4326)::geography;
  
  -- Return distance in meters
  RETURN ST_Distance(point1, point2);
END;
$$;

COMMENT ON FUNCTION public.calculate_distance IS 'Hitung jarak antara 2 koordinat dalam meter menggunakan PostGIS';

-- =====================================================
-- STEP 7: Function untuk Get Nearby Patients
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_nearby_patients(
  center_lat FLOAT,
  center_lon FLOAT,
  radius_meters FLOAT DEFAULT 1000
)
RETURNS TABLE (
  patient_id UUID,
  patient_name TEXT,
  latitude FLOAT,
  longitude FLOAT,
  distance_meters FLOAT,
  last_update TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  center_point GEOGRAPHY;
BEGIN
  center_point := ST_SetSRID(ST_MakePoint(center_lon, center_lat), 4326)::geography;
  
  RETURN QUERY
  SELECT
    l.patient_id,
    p.full_name AS patient_name,
    ST_Y(l.coordinates::geometry) AS latitude,
    ST_X(l.coordinates::geometry) AS longitude,
    ST_Distance(l.coordinates, center_point) AS distance_meters,
    l.timestamp AS last_update
  FROM public.locations l
  JOIN public.profiles p ON p.id = l.patient_id
  WHERE l.id IN (
    -- Get only latest location per patient
    SELECT DISTINCT ON (patient_id) id
    FROM public.locations
    ORDER BY patient_id, timestamp DESC
  )
  AND ST_DWithin(l.coordinates, center_point, radius_meters)
  ORDER BY distance_meters;
END;
$$;

COMMENT ON FUNCTION public.get_nearby_patients IS 'Cari pasien dalam radius tertentu dari koordinat center (untuk emergency response)';

-- =====================================================
-- STEP 8: Function untuk Get Activity Stats
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_activity_stats(
  patient_id_param UUID,
  days_back INTEGER DEFAULT 7
)
RETURNS TABLE (
  total_activities INTEGER,
  completed_activities INTEGER,
  pending_activities INTEGER,
  completion_rate FLOAT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  total_count INTEGER;
  completed_count INTEGER;
BEGIN
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE is_completed = TRUE)
  INTO total_count, completed_count
  FROM public.activities
  WHERE patient_id = patient_id_param
    AND activity_time >= NOW() - INTERVAL '1 day' * days_back;
  
  RETURN QUERY
  SELECT
    total_count,
    completed_count,
    total_count - completed_count,
    CASE 
      WHEN total_count > 0 THEN (completed_count::FLOAT / total_count::FLOAT) * 100
      ELSE 0
    END;
END;
$$;

COMMENT ON FUNCTION public.get_activity_stats IS 'Statistik aktivitas pasien dalam N hari terakhir';

-- =====================================================
-- STEP 9: Function untuk Delete Old Locations
-- =====================================================

CREATE OR REPLACE FUNCTION public.delete_old_locations(
  days_to_keep INTEGER DEFAULT 30
)
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  WITH deleted AS (
    DELETE FROM public.locations
    WHERE timestamp < NOW() - INTERVAL '1 day' * days_to_keep
    RETURNING *
  )
  SELECT COUNT(*) INTO deleted_count FROM deleted;
  
  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION public.delete_old_locations IS 'Hapus data lokasi yang lebih lama dari N hari (untuk cleanup)';

-- =====================================================
-- STEP 10: Function untuk Emergency Alert Notification
-- =====================================================

CREATE OR REPLACE FUNCTION public.notify_emergency_contacts()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  contact_record RECORD;
BEGIN
  -- Insert notifications untuk semua emergency contacts
  FOR contact_record IN
    SELECT ec.contact_id, ec.priority
    FROM public.emergency_contacts ec
    WHERE ec.patient_id = NEW.patient_id
      AND ec.notification_enabled = TRUE
    ORDER BY ec.priority
  LOOP
    INSERT INTO public.notifications (
      user_id,
      notification_type,
      title,
      body,
      data,
      related_alert_id
    ) VALUES (
      contact_record.contact_id,
      'emergency_alert',
      '🚨 PERINGATAN DARURAT!',
      'Pasien membutuhkan bantuan segera. Klik untuk melihat lokasi.',
      jsonb_build_object(
        'alert_id', NEW.id,
        'patient_id', NEW.patient_id,
        'alert_type', NEW.alert_type,
        'severity', NEW.severity,
        'priority', contact_record.priority
      ),
      NEW.id
    );
  END LOOP;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_emergency_contacts IS 'Auto-create notifications untuk emergency contacts saat alert dipicu';

-- Trigger untuk emergency_alerts
DROP TRIGGER IF EXISTS notify_on_emergency_alert ON public.emergency_alerts;
CREATE TRIGGER notify_on_emergency_alert
  AFTER INSERT ON public.emergency_alerts
  FOR EACH ROW
  WHEN (NEW.status = 'active')
  EXECUTE FUNCTION public.notify_emergency_contacts();

-- =====================================================
-- STEP 11: Function untuk Activity Reminder Notification
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_activity_reminder_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Create notification untuk patient saat activity dibuat
  INSERT INTO public.notifications (
    user_id,
    notification_type,
    title,
    body,
    data,
    related_activity_id
  ) VALUES (
    NEW.patient_id,
    'activity_created',
    '📝 Aktivitas Baru',
    NEW.title || ' dijadwalkan pada ' || TO_CHAR(NEW.activity_time, 'DD Mon YYYY HH24:MI'),
    jsonb_build_object(
      'activity_id', NEW.id,
      'activity_time', NEW.activity_time
    ),
    NEW.id
  );
  
  -- Create notification untuk family members yang membuat activity (jika bukan patient sendiri)
  IF NEW.created_by IS NOT NULL AND NEW.created_by != NEW.patient_id THEN
    INSERT INTO public.notifications (
      user_id,
      notification_type,
      title,
      body,
      data,
      related_activity_id
    ) VALUES (
      NEW.created_by,
      'activity_created',
      '✅ Aktivitas Berhasil Dibuat',
      'Aktivitas "' || NEW.title || '" berhasil ditambahkan untuk pasien',
      jsonb_build_object(
        'activity_id', NEW.id,
        'patient_id', NEW.patient_id
      ),
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.create_activity_reminder_notification IS 'Auto-create notification saat activity baru dibuat';

-- Trigger untuk activities
DROP TRIGGER IF EXISTS notify_on_activity_created ON public.activities;
CREATE TRIGGER notify_on_activity_created
  AFTER INSERT ON public.activities
  FOR EACH ROW
  EXECUTE FUNCTION public.create_activity_reminder_notification();

-- =====================================================
-- STEP 12: Function untuk Mark Notification as Sent
-- =====================================================

CREATE OR REPLACE FUNCTION public.mark_notification_sent(notification_id UUID)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.notifications
  SET 
    is_sent = TRUE,
    sent_at = NOW()
  WHERE id = notification_id;
END;
$$;

COMMENT ON FUNCTION public.mark_notification_sent IS 'Mark notification sebagai sudah terkirim (dipanggil dari Edge Function)';

-- =====================================================
-- STEP 13: Function untuk Cleanup Old Notifications
-- =====================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_notifications(
  days_to_keep INTEGER DEFAULT 30
)
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  WITH deleted AS (
    DELETE FROM public.notifications
    WHERE created_at < NOW() - INTERVAL '1 day' * days_to_keep
      AND is_read = TRUE
    RETURNING *
  )
  SELECT COUNT(*) INTO deleted_count FROM deleted;
  
  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION public.cleanup_old_notifications IS 'Hapus notifikasi lama yang sudah dibaca (untuk cleanup)';

-- =====================================================
-- STEP 14: Function untuk Get Patient Dashboard Stats
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_patient_dashboard_stats(patient_id_param UUID)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_activities', (
      SELECT COUNT(*) FROM public.activities
      WHERE patient_id = patient_id_param
        AND activity_time >= CURRENT_DATE
        AND activity_time < CURRENT_DATE + INTERVAL '1 day'
    ),
    'completed_today', (
      SELECT COUNT(*) FROM public.activities
      WHERE patient_id = patient_id_param
        AND is_completed = TRUE
        AND completed_at >= CURRENT_DATE
    ),
    'pending_activities', (
      SELECT COUNT(*) FROM public.activities
      WHERE patient_id = patient_id_param
        AND is_completed = FALSE
        AND activity_time >= NOW()
    ),
    'known_persons_count', (
      SELECT COUNT(*) FROM public.known_persons
      WHERE owner_id = patient_id_param
    ),
    'family_members_count', (
      SELECT COUNT(*) FROM public.patient_family_links
      WHERE patient_id = patient_id_param
    ),
    'last_recognition', (
      SELECT json_build_object(
        'person_name', kp.full_name,
        'timestamp', frl.timestamp
      )
      FROM public.face_recognition_logs frl
      JOIN public.known_persons kp ON kp.id = frl.recognized_person_id
      WHERE frl.patient_id = patient_id_param
        AND frl.is_recognized = TRUE
      ORDER BY frl.timestamp DESC
      LIMIT 1
    ),
    'unread_notifications', (
      SELECT COUNT(*) FROM public.notifications
      WHERE user_id = patient_id_param
        AND is_read = FALSE
    )
  ) INTO result;
  
  RETURN result;
END;
$$;

COMMENT ON FUNCTION public.get_patient_dashboard_stats IS 'Dapatkan semua stats untuk dashboard pasien dalam 1 query';

-- =====================================================
-- STEP 15: Function untuk Get Family Dashboard Stats
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_family_dashboard_stats(family_member_id_param UUID)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'linked_patients', (
      SELECT json_agg(json_build_object(
        'patient_id', p.id,
        'patient_name', p.full_name,
        'relationship', pfl.relationship_type,
        'pending_activities', (
          SELECT COUNT(*) FROM public.activities a
          WHERE a.patient_id = p.id
            AND a.is_completed = FALSE
            AND a.activity_time >= NOW()
        ),
        'last_location', (
          SELECT json_build_object(
            'latitude', ST_Y(l.coordinates::geometry),
            'longitude', ST_X(l.coordinates::geometry),
            'timestamp', l.timestamp
          )
          FROM public.locations l
          WHERE l.patient_id = p.id
          ORDER BY l.timestamp DESC
          LIMIT 1
        )
      ))
      FROM public.patient_family_links pfl
      JOIN public.profiles p ON p.id = pfl.patient_id
      WHERE pfl.family_member_id = family_member_id_param
    ),
    'active_alerts', (
      SELECT COUNT(*) FROM public.emergency_alerts ea
      JOIN public.patient_family_links pfl ON pfl.patient_id = ea.patient_id
      WHERE pfl.family_member_id = family_member_id_param
        AND ea.status = 'active'
    ),
    'unread_notifications', (
      SELECT COUNT(*) FROM public.notifications
      WHERE user_id = family_member_id_param
        AND is_read = FALSE
    )
  ) INTO result;
  
  RETURN result;
END;
$$;

COMMENT ON FUNCTION public.get_family_dashboard_stats IS 'Dapatkan semua stats untuk dashboard family member dalam 1 query';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Triggers and Functions created successfully!';
  RAISE NOTICE '🔄 Auto-triggers configured:';
  RAISE NOTICE '   - Auto-create profile on signup';
  RAISE NOTICE '   - Auto-update timestamps';
  RAISE NOTICE '   - Auto-notify on emergency alert';
  RAISE NOTICE '   - Auto-notify on activity created';
  RAISE NOTICE '   - Auto-update face recognition stats';
  RAISE NOTICE '🛠️  Helper functions available:';
  RAISE NOTICE '   - find_known_person()';
  RAISE NOTICE '   - get_latest_location()';
  RAISE NOTICE '   - calculate_distance()';
  RAISE NOTICE '   - get_activity_stats()';
  RAISE NOTICE '   - get_patient_dashboard_stats()';
  RAISE NOTICE '   - get_family_dashboard_stats()';
  RAISE NOTICE '📝 Next: Run 004_realtime_config.sql for Realtime setup';
END $$;
