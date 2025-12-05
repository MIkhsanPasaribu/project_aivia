-- =============================================================================
-- Migration 010: Geofence Events (Enter/Exit Detection)
-- =============================================================================
-- Purpose: Automatically detect and log when patients enter/exit geofences
-- Created: 2025-01-12
-- Dependencies: 009_geofences.sql, 001_initial_schema.sql (locations table)
-- FREE Technology: PostGIS + PostgreSQL triggers
-- =============================================================================

-- Description:
-- This migration creates automatic geofence violation detection system.
-- Every time a new location is inserted, triggers check if the patient
-- has entered or exited any geofences and log the events.
--
-- Event Types:
-- - ENTER: Patient entered a geofence
-- - EXIT: Patient exited a geofence
--
-- Use Cases:
-- - Alert family when patient leaves home
-- - Confirm patient arrived at hospital
-- - Warn when patient enters danger zone
-- - Track school attendance
--
-- Features:
-- - Automatic detection via triggers
-- - Event history/audit trail
-- - Notification status tracking
-- - Prevention of duplicate events

-- =============================================================================
-- 1. CREATE ENUM: Event Type
-- =============================================================================

-- Drop type if exists (for re-running migration)
DROP TYPE IF EXISTS geofence_event_type CASCADE;

-- Create event type enum
CREATE TYPE geofence_event_type AS ENUM (
  'enter',  -- Patient entered geofence
  'exit'    -- Patient exited geofence
);

-- =============================================================================
-- 2. CREATE TABLE: geofence_events
-- =============================================================================

-- Drop table if exists (for development/testing)
DROP TABLE IF EXISTS public.geofence_events CASCADE;

-- Create geofence events table
CREATE TABLE public.geofence_events (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign keys
  geofence_id UUID NOT NULL REFERENCES public.geofences(id) ON DELETE CASCADE,
  location_id BIGINT NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  
  -- Event data
  event_type geofence_event_type NOT NULL,
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE, -- Denormalized for performance
  
  -- Event metadata
  distance_from_center REAL, -- Distance from geofence center in meters
  
  -- Notification tracking
  notified BOOLEAN DEFAULT FALSE,
  notified_at TIMESTAMPTZ,
  notification_sent_to UUID[] DEFAULT ARRAY[]::UUID[], -- Array of family member IDs who were notified
  
  -- Additional metadata
  metadata JSONB DEFAULT '{}'::jsonb,
  -- Example metadata:
  -- {
  --   "notification_method": "fcm",
  --   "notification_ids": ["fcm_message_id_1", "fcm_message_id_2"],
  --   "patient_speed": 5.2,
  --   "patient_heading": 180.0,
  --   "weather": "sunny",
  --   "time_of_day": "morning"
  -- }
  
  -- Timestamps
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 3. CREATE INDEXES
-- =============================================================================

-- Index for querying by geofence
CREATE INDEX idx_geofence_events_geofence 
  ON public.geofence_events(geofence_id);

-- Index for querying by location
CREATE INDEX idx_geofence_events_location 
  ON public.geofence_events(location_id);

-- Index for querying by patient (most common)
CREATE INDEX idx_geofence_events_patient 
  ON public.geofence_events(patient_id, detected_at DESC);

-- Index for unnotified events (for notification worker)
CREATE INDEX idx_geofence_events_unnotified 
  ON public.geofence_events(detected_at) 
  WHERE notified = FALSE;

-- Compound index for patient + event type queries
CREATE INDEX idx_geofence_events_patient_type 
  ON public.geofence_events(patient_id, event_type, detected_at DESC);

-- =============================================================================
-- 4. CREATE FUNCTION: Get Patient's Current Geofence State
-- =============================================================================

-- Function to get which geofences patient is currently inside
-- Based on most recent location
CREATE OR REPLACE FUNCTION get_patient_current_geofence_state(p_patient_id UUID)
RETURNS TABLE (
  geofence_id UUID,
  geofence_name TEXT,
  fence_type fence_type,
  entered_at TIMESTAMPTZ,
  duration_minutes REAL
) AS $$
BEGIN
  RETURN QUERY
  WITH latest_location AS (
    SELECT coordinates, timestamp
    FROM public.locations
    WHERE patient_id = p_patient_id
    ORDER BY timestamp DESC
    LIMIT 1
  ),
  latest_events AS (
    SELECT DISTINCT ON (ge.geofence_id)
      ge.geofence_id,
      ge.event_type,
      ge.detected_at
    FROM public.geofence_events ge
    WHERE ge.patient_id = p_patient_id
    ORDER BY ge.geofence_id, ge.detected_at DESC
  )
  SELECT 
    g.id AS geofence_id,
    g.name AS geofence_name,
    g.fence_type,
    le.detected_at AS entered_at,
    EXTRACT(EPOCH FROM (NOW() - le.detected_at)) / 60.0 AS duration_minutes
  FROM public.geofences g
  INNER JOIN latest_events le ON g.id = le.geofence_id
  CROSS JOIN latest_location ll
  WHERE le.event_type = 'enter'
    AND g.patient_id = p_patient_id
    AND g.is_active = TRUE
    AND ST_DWithin(g.center_coordinates, ll.coordinates, g.radius_meters);
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_patient_current_geofence_state(UUID) TO authenticated;

-- =============================================================================
-- 5. CREATE FUNCTION: Detect Geofence Events (Main Logic)
-- =============================================================================

-- Main function to detect geofence enter/exit events
-- Called by trigger after location insert
CREATE OR REPLACE FUNCTION detect_geofence_events(
  p_location_id BIGINT,
  p_patient_id UUID,
  p_new_coordinates GEOGRAPHY(POINT, 4326)
)
RETURNS INTEGER AS $$
DECLARE
  v_events_created INTEGER := 0;
  v_geofence RECORD;
  v_previous_location RECORD;
  v_was_inside BOOLEAN;
  v_is_inside BOOLEAN;
  v_distance REAL;
  v_event_id UUID;
BEGIN
  -- Get previous location (before this one)
  SELECT 
    l.id,
    l.coordinates,
    l.timestamp
  INTO v_previous_location
  FROM public.locations l
  WHERE l.patient_id = p_patient_id
    AND l.id < p_location_id -- Previous location (smaller ID = older)
  ORDER BY l.timestamp DESC
  LIMIT 1;
  
  -- If no previous location, can't detect exit events, only enters
  -- Check all active geofences for this patient
  FOR v_geofence IN
    SELECT 
      g.id,
      g.name,
      g.fence_type,
      g.center_coordinates,
      g.radius_meters,
      g.alert_on_enter,
      g.alert_on_exit
    FROM public.geofences g
    WHERE g.patient_id = p_patient_id
      AND g.is_active = TRUE
  LOOP
    -- Check if current location is inside geofence
    v_distance := ST_Distance(v_geofence.center_coordinates, p_new_coordinates);
    v_is_inside := v_distance <= v_geofence.radius_meters;
    
    -- Check if previous location was inside geofence (if exists)
    IF v_previous_location.coordinates IS NOT NULL THEN
      v_was_inside := ST_DWithin(
        v_geofence.center_coordinates,
        v_previous_location.coordinates,
        v_geofence.radius_meters
      );
    ELSE
      v_was_inside := FALSE;
    END IF;
    
    -- Detect ENTER event
    IF v_is_inside AND NOT v_was_inside AND v_geofence.alert_on_enter THEN
      -- Check if there's already a recent ENTER event (prevent duplicates)
      IF NOT EXISTS (
        SELECT 1 FROM public.geofence_events
        WHERE geofence_id = v_geofence.id
          AND patient_id = p_patient_id
          AND event_type = 'enter'
          AND detected_at > NOW() - INTERVAL '5 minutes'
      ) THEN
        -- Insert ENTER event
        INSERT INTO public.geofence_events (
          geofence_id,
          location_id,
          event_type,
          patient_id,
          distance_from_center,
          notified,
          detected_at
        ) VALUES (
          v_geofence.id,
          p_location_id,
          'enter',
          p_patient_id,
          v_distance,
          FALSE,
          NOW()
        )
        RETURNING id INTO v_event_id;
        
        v_events_created := v_events_created + 1;
        
        RAISE NOTICE 'ENTER event detected: patient % entered geofence % (%) at distance %m',
          p_patient_id, v_geofence.name, v_geofence.fence_type, ROUND(v_distance, 2);
      END IF;
    END IF;
    
    -- Detect EXIT event
    IF NOT v_is_inside AND v_was_inside AND v_geofence.alert_on_exit THEN
      -- Check if there's already a recent EXIT event (prevent duplicates)
      IF NOT EXISTS (
        SELECT 1 FROM public.geofence_events
        WHERE geofence_id = v_geofence.id
          AND patient_id = p_patient_id
          AND event_type = 'exit'
          AND detected_at > NOW() - INTERVAL '5 minutes'
      ) THEN
        -- Insert EXIT event
        INSERT INTO public.geofence_events (
          geofence_id,
          location_id,
          event_type,
          patient_id,
          distance_from_center,
          notified,
          detected_at
        ) VALUES (
          v_geofence.id,
          p_location_id,
          'exit',
          p_patient_id,
          v_distance,
          FALSE,
          NOW()
        )
        RETURNING id INTO v_event_id;
        
        v_events_created := v_events_created + 1;
        
        RAISE NOTICE 'EXIT event detected: patient % exited geofence % (%) now at distance %m',
          p_patient_id, v_geofence.name, v_geofence.fence_type, ROUND(v_distance, 2);
      END IF;
    END IF;
  END LOOP;
  
  RETURN v_events_created;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION detect_geofence_events(BIGINT, UUID, GEOGRAPHY) TO authenticated;

-- =============================================================================
-- 6. CREATE TRIGGER FUNCTION: Auto-detect Geofence Events
-- =============================================================================

-- Trigger function that runs AFTER INSERT on locations table
-- Automatically detects geofence enter/exit events
CREATE OR REPLACE FUNCTION trigger_detect_geofence_events()
RETURNS TRIGGER AS $$
DECLARE
  v_events_created INTEGER;
BEGIN
  -- Call geofence detection function
  v_events_created := detect_geofence_events(
    NEW.id,
    NEW.patient_id,
    NEW.coordinates
  );
  
  -- Log if events were created
  IF v_events_created > 0 THEN
    RAISE DEBUG 'Created % geofence event(s) for location %', v_events_created, NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 7. CREATE TRIGGER: Apply Geofence Detection on Location Insert
-- =============================================================================

-- Drop trigger if exists (for re-running migration)
DROP TRIGGER IF EXISTS trigger_check_geofences_after_insert ON public.locations;

-- Create trigger
CREATE TRIGGER trigger_check_geofences_after_insert
  AFTER INSERT ON public.locations
  FOR EACH ROW
  EXECUTE FUNCTION trigger_detect_geofence_events();

-- =============================================================================
-- 8. CREATE FUNCTION: Mark Event as Notified
-- =============================================================================

-- Function to mark event as notified after sending notification
CREATE OR REPLACE FUNCTION mark_geofence_event_notified(
  p_event_id UUID,
  p_notified_to UUID[]
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.geofence_events
  SET 
    notified = TRUE,
    notified_at = NOW(),
    notification_sent_to = p_notified_to
  WHERE id = p_event_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION mark_geofence_event_notified(UUID, UUID[]) TO authenticated;

-- =============================================================================
-- 9. CREATE FUNCTION: Get Unnotified Events
-- =============================================================================

-- Function to get unnotified events (for notification worker)
CREATE OR REPLACE FUNCTION get_unnotified_geofence_events(p_limit INTEGER DEFAULT 100)
RETURNS TABLE (
  event_id UUID,
  geofence_id UUID,
  geofence_name TEXT,
  fence_type fence_type,
  event_type geofence_event_type,
  patient_id UUID,
  patient_name TEXT,
  location_lat DOUBLE PRECISION,
  location_lon DOUBLE PRECISION,
  distance_from_center REAL,
  detected_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ge.id AS event_id,
    g.id AS geofence_id,
    g.name AS geofence_name,
    g.fence_type,
    ge.event_type,
    ge.patient_id,
    p.full_name AS patient_name,
    ST_Y(l.coordinates::geometry) AS location_lat,
    ST_X(l.coordinates::geometry) AS location_lon,
    ge.distance_from_center,
    ge.detected_at
  FROM public.geofence_events ge
  INNER JOIN public.geofences g ON ge.geofence_id = g.id
  INNER JOIN public.profiles p ON ge.patient_id = p.id
  INNER JOIN public.locations l ON ge.location_id = l.id
  WHERE ge.notified = FALSE
    AND ge.detected_at > NOW() - INTERVAL '1 hour' -- Only recent events
  ORDER BY ge.detected_at ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role (for Edge Functions)
GRANT EXECUTE ON FUNCTION get_unnotified_geofence_events(INTEGER) TO service_role;

-- =============================================================================
-- 10. CREATE VIEW: Geofence Event Statistics
-- =============================================================================

-- View to monitor geofence event activity
CREATE OR REPLACE VIEW public.geofence_event_stats AS
SELECT 
  g.id AS geofence_id,
  g.name AS geofence_name,
  g.fence_type,
  g.patient_id,
  p.full_name AS patient_name,
  COUNT(ge.id) AS total_events,
  COUNT(CASE WHEN ge.event_type = 'enter' THEN 1 END) AS enter_events,
  COUNT(CASE WHEN ge.event_type = 'exit' THEN 1 END) AS exit_events,
  COUNT(CASE WHEN ge.notified THEN 1 END) AS notified_events,
  COUNT(CASE WHEN NOT ge.notified THEN 1 END) AS pending_notifications,
  MIN(ge.detected_at) AS first_event,
  MAX(ge.detected_at) AS last_event,
  AVG(ge.distance_from_center)::REAL AS avg_distance_from_center
FROM public.geofences g
LEFT JOIN public.geofence_events ge ON g.id = ge.geofence_id
LEFT JOIN public.profiles p ON g.patient_id = p.id
WHERE g.is_active = TRUE
GROUP BY g.id, g.name, g.fence_type, g.patient_id, p.full_name
ORDER BY total_events DESC;

-- Grant view access
GRANT SELECT ON public.geofence_event_stats TO authenticated;

-- =============================================================================
-- 11. CREATE VIEW: Recent Geofence Activity
-- =============================================================================

-- View for dashboard: recent geofence activity
CREATE OR REPLACE VIEW public.recent_geofence_activity AS
SELECT 
  ge.id AS event_id,
  ge.event_type,
  ge.detected_at,
  g.name AS geofence_name,
  g.fence_type,
  p.full_name AS patient_name,
  ge.patient_id,
  ge.distance_from_center,
  ge.notified,
  CASE 
    WHEN ge.event_type = 'enter' AND g.fence_type = 'home' THEN '🏠 Pasien tiba di rumah'
    WHEN ge.event_type = 'exit' AND g.fence_type = 'home' THEN '⚠️ Pasien meninggalkan rumah'
    WHEN ge.event_type = 'enter' AND g.fence_type = 'danger' THEN '🚨 Pasien masuk zona bahaya'
    WHEN ge.event_type = 'exit' AND g.fence_type = 'danger' THEN '✅ Pasien keluar dari zona bahaya'
    WHEN ge.event_type = 'enter' THEN '📍 Pasien masuk ' || g.name
    WHEN ge.event_type = 'exit' THEN '📍 Pasien keluar dari ' || g.name
  END AS event_description
FROM public.geofence_events ge
INNER JOIN public.geofences g ON ge.geofence_id = g.id
INNER JOIN public.profiles p ON ge.patient_id = p.id
WHERE ge.detected_at > NOW() - INTERVAL '24 hours'
ORDER BY ge.detected_at DESC
LIMIT 100;

-- Grant view access
GRANT SELECT ON public.recent_geofence_activity TO authenticated;

-- =============================================================================
-- 12. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS
ALTER TABLE public.geofence_events ENABLE ROW LEVEL SECURITY;

-- Policy: Patients can view their own events
CREATE POLICY "Patients can view own geofence events"
  ON public.geofence_events
  FOR SELECT
  USING (auth.uid() = patient_id);

-- Policy: Family members can view linked patient's events
CREATE POLICY "Family can view patient geofence events"
  ON public.geofence_events
  FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  );

-- Policy: Service role can manage all events (for Edge Functions)
CREATE POLICY "Service role can manage all geofence events"
  ON public.geofence_events
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- =============================================================================
-- 13. VERIFICATION QUERIES
-- =============================================================================

-- Verify table created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'geofence_events') THEN
    RAISE EXCEPTION 'geofence_events table was not created!';
  END IF;
  
  RAISE NOTICE '✅ geofence_events table created successfully';
END $$;

-- Verify trigger created
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_check_geofences_after_insert'
  ) THEN
    RAISE EXCEPTION 'Geofence detection trigger was not created!';
  END IF;
  
  RAISE NOTICE '✅ Geofence detection trigger created successfully';
END $$;

-- Verify RLS enabled
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'geofence_events' 
    AND rowsecurity = TRUE
  ) THEN
    RAISE EXCEPTION 'RLS is not enabled on geofence_events table!';
  END IF;
  
  RAISE NOTICE '✅ RLS enabled successfully';
END $$;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '
================================================================================
✅ Migration 010: Geofence Events (Enter/Exit Detection) - COMPLETE
================================================================================
Created:
  - Enum: geofence_event_type (enter, exit)
  - Table: geofence_events (event history with notification tracking)
  - Indexes: geofence_id, location_id, patient_id, unnotified events
  - Functions:
    * get_patient_current_geofence_state(patient_id)
    * detect_geofence_events(location_id, patient_id, coordinates)
    * mark_geofence_event_notified(event_id, notified_to)
    * get_unnotified_geofence_events(limit)
  - Trigger: trigger_check_geofences_after_insert (AFTER INSERT on locations)
  - Views:
    * geofence_event_stats (statistics dashboard)
    * recent_geofence_activity (last 24 hours activity)
  - RLS Policies: 3 policies for patient & family access

How It Works:
  1. New location inserted into locations table
  2. Trigger automatically calls detect_geofence_events()
  3. Function checks all active geofences for patient
  4. Compares current vs previous location
  5. Logs ENTER/EXIT events to geofence_events table
  6. Events marked as unnotified (notified = FALSE)
  7. Notification worker picks up unnotified events
  8. Sends FCM notifications to family members
  9. Marks events as notified

Usage Examples:
  -- Get patient current geofence state
  SELECT * FROM get_patient_current_geofence_state(''patient-uuid'');

  -- Get unnotified events (for notification worker)
  SELECT * FROM get_unnotified_geofence_events(100);

  -- Mark event as notified
  SELECT mark_geofence_event_notified(
    ''event-uuid'',
    ARRAY[''family-member-1-uuid'', ''family-member-2-uuid'']::UUID[]
  );

  -- View recent activity
  SELECT * FROM recent_geofence_activity;

  -- View statistics
  SELECT * FROM geofence_event_stats;

Cost: $0.00 (Uses PostgreSQL triggers + PostGIS)
================================================================================
';
END $$;
