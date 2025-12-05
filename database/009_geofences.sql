-- =============================================================================
-- Migration 009: Geofences (Safe Zones & Danger Zones)
-- =============================================================================
-- Purpose: Define geographic boundaries for location-based alerts
-- Created: 2025-01-12
-- Dependencies: 001_initial_schema.sql (PostGIS enabled)
-- FREE Technology: PostGIS ST_DWithin, ST_Contains (built-in)
-- =============================================================================

-- Description:
-- Geofencing allows family members to define safe zones (home, school, hospital)
-- and danger zones (busy roads, unsafe areas). The system automatically alerts
-- when patients enter or exit these zones.
--
-- Use Cases:
-- - Home Zone: Alert if patient leaves home unexpectedly
-- - Hospital Zone: Confirm patient reached appointment
-- - Danger Zone: Alert if patient enters dangerous area
-- - School Zone: Track school attendance
--
-- Features:
-- - Circular geofences (center point + radius)
-- - Multiple geofences per patient
-- - Active/inactive status
-- - Priority levels
-- - Customizable alerts (enter/exit/both)

-- =============================================================================
-- 1. CREATE ENUM: Fence Type
-- =============================================================================

-- Drop type if exists (for re-running migration)
DROP TYPE IF EXISTS fence_type CASCADE;

-- Create geofence type enum
CREATE TYPE fence_type AS ENUM (
  'safe',      -- Safe zones (home, hospital, school)
  'danger',    -- Danger zones (busy roads, unsafe areas)
  'home',      -- Home location (special safe zone)
  'hospital',  -- Medical facility
  'school',    -- Educational institution
  'custom'     -- Custom user-defined zone
);

-- =============================================================================
-- 2. CREATE TABLE: geofences
-- =============================================================================

-- Drop table if exists (for development/testing)
DROP TABLE IF EXISTS public.geofences CASCADE;

-- Create geofences table
CREATE TABLE public.geofences (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign key to patient
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Geofence metadata
  name TEXT NOT NULL,
  description TEXT,
  fence_type fence_type NOT NULL DEFAULT 'custom',
  
  -- Geographic data (circular geofences)
  center_coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  radius_meters INTEGER NOT NULL CHECK (radius_meters > 0 AND radius_meters <= 10000), -- Max 10km radius
  
  -- Alert configuration
  is_active BOOLEAN DEFAULT TRUE,
  alert_on_enter BOOLEAN DEFAULT TRUE,
  alert_on_exit BOOLEAN DEFAULT TRUE,
  priority INTEGER DEFAULT 5 CHECK (priority >= 1 AND priority <= 10), -- 1 = highest, 10 = lowest
  
  -- Additional metadata
  address TEXT, -- Human-readable address
  metadata JSONB DEFAULT '{}'::jsonb, -- Flexible data storage
  -- Example metadata:
  -- {
  --   "color": "#FF0000",
  --   "icon": "home",
  --   "contact_phone": "+628123456789",
  --   "active_hours": "08:00-17:00",
  --   "active_days": ["monday", "tuesday", "wednesday"]
  -- }
  
  -- Created by (family member)
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 3. CREATE INDEXES
-- =============================================================================

-- Index for querying by patient (most common)
CREATE INDEX idx_geofences_patient 
  ON public.geofences(patient_id) 
  WHERE is_active = TRUE;

-- Spatial index for geographic queries (CRITICAL for performance)
CREATE INDEX idx_geofences_coordinates 
  ON public.geofences USING GIST(center_coordinates);

-- Index for fence type filtering
CREATE INDEX idx_geofences_type 
  ON public.geofences(fence_type) 
  WHERE is_active = TRUE;

-- Index for priority ordering
CREATE INDEX idx_geofences_priority 
  ON public.geofences(patient_id, priority) 
  WHERE is_active = TRUE;

-- =============================================================================
-- 4. CREATE FUNCTION: Check if Location is Inside Geofence
-- =============================================================================

-- Function to check if a point is inside a geofence
CREATE OR REPLACE FUNCTION is_location_inside_geofence(
  p_geofence_id UUID,
  p_location GEOGRAPHY(POINT, 4326)
)
RETURNS BOOLEAN AS $$
DECLARE
  v_geofence RECORD;
  v_distance REAL;
BEGIN
  -- Get geofence data
  SELECT 
    center_coordinates,
    radius_meters,
    is_active
  INTO v_geofence
  FROM public.geofences
  WHERE id = p_geofence_id;
  
  -- Return false if geofence not found or inactive
  IF v_geofence.center_coordinates IS NULL OR NOT v_geofence.is_active THEN
    RETURN FALSE;
  END IF;
  
  -- Calculate distance from center
  v_distance := ST_Distance(
    v_geofence.center_coordinates,
    p_location
  );
  
  -- Check if inside radius
  RETURN v_distance <= v_geofence.radius_meters;
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_location_inside_geofence(UUID, GEOGRAPHY) TO authenticated;

-- =============================================================================
-- 5. CREATE FUNCTION: Get Active Geofences for Patient
-- =============================================================================

-- Function to get all active geofences for a patient
CREATE OR REPLACE FUNCTION get_patient_geofences(p_patient_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  fence_type fence_type,
  center_lat DOUBLE PRECISION,
  center_lon DOUBLE PRECISION,
  radius_meters INTEGER,
  alert_on_enter BOOLEAN,
  alert_on_exit BOOLEAN,
  priority INTEGER,
  address TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.name,
    g.description,
    g.fence_type,
    ST_Y(g.center_coordinates::geometry) AS center_lat,
    ST_X(g.center_coordinates::geometry) AS center_lon,
    g.radius_meters,
    g.alert_on_enter,
    g.alert_on_exit,
    g.priority,
    g.address
  FROM public.geofences g
  WHERE g.patient_id = p_patient_id
    AND g.is_active = TRUE
  ORDER BY g.priority ASC, g.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_patient_geofences(UUID) TO authenticated;

-- =============================================================================
-- 6. CREATE FUNCTION: Check Which Geofences Contain Location
-- =============================================================================

-- Function to check which geofences contain a given location
-- Returns all matching geofences sorted by priority
CREATE OR REPLACE FUNCTION check_location_geofences(
  p_patient_id UUID,
  p_location GEOGRAPHY(POINT, 4326)
)
RETURNS TABLE (
  geofence_id UUID,
  geofence_name TEXT,
  fence_type fence_type,
  distance_from_center REAL,
  radius_meters INTEGER,
  alert_on_enter BOOLEAN,
  alert_on_exit BOOLEAN,
  priority INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id AS geofence_id,
    g.name AS geofence_name,
    g.fence_type,
    ST_Distance(g.center_coordinates, p_location) AS distance_from_center,
    g.radius_meters,
    g.alert_on_enter,
    g.alert_on_exit,
    g.priority
  FROM public.geofences g
  WHERE g.patient_id = p_patient_id
    AND g.is_active = TRUE
    AND ST_DWithin(g.center_coordinates, p_location, g.radius_meters)
  ORDER BY g.priority ASC, distance_from_center ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_location_geofences(UUID, GEOGRAPHY) TO authenticated;

-- =============================================================================
-- 7. CREATE FUNCTION: Get Nearest Geofence
-- =============================================================================

-- Function to find the nearest geofence to a location
-- Useful for "heading towards X" notifications
CREATE OR REPLACE FUNCTION get_nearest_geofence(
  p_patient_id UUID,
  p_location GEOGRAPHY(POINT, 4326),
  p_max_distance_meters REAL DEFAULT 5000.0
)
RETURNS TABLE (
  geofence_id UUID,
  geofence_name TEXT,
  fence_type fence_type,
  distance_meters REAL,
  is_inside BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  WITH distances AS (
    SELECT 
      g.id,
      g.name,
      g.fence_type,
      ST_Distance(g.center_coordinates, p_location) AS distance,
      g.radius_meters
    FROM public.geofences g
    WHERE g.patient_id = p_patient_id
      AND g.is_active = TRUE
  )
  SELECT 
    d.id AS geofence_id,
    d.name AS geofence_name,
    d.fence_type,
    d.distance AS distance_meters,
    (d.distance <= d.radius_meters) AS is_inside
  FROM distances d
  WHERE d.distance <= p_max_distance_meters
  ORDER BY d.distance ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_nearest_geofence(UUID, GEOGRAPHY, REAL) TO authenticated;

-- =============================================================================
-- 8. CREATE FUNCTION: Create Default Home Geofence
-- =============================================================================

-- Helper function to create a default home geofence
-- Called when patient first sets up account
CREATE OR REPLACE FUNCTION create_default_home_geofence(
  p_patient_id UUID,
  p_home_lat DOUBLE PRECISION,
  p_home_lon DOUBLE PRECISION,
  p_radius_meters INTEGER DEFAULT 100,
  p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_geofence_id UUID;
BEGIN
  -- Insert home geofence
  INSERT INTO public.geofences (
    patient_id,
    name,
    description,
    fence_type,
    center_coordinates,
    radius_meters,
    is_active,
    alert_on_enter,
    alert_on_exit,
    priority,
    created_by
  ) VALUES (
    p_patient_id,
    'Rumah',
    'Zona aman - Rumah pasien',
    'home',
    ST_Point(p_home_lon, p_home_lat)::geography,
    p_radius_meters,
    TRUE,
    FALSE, -- Don't alert when entering home
    TRUE,  -- Alert when leaving home
    1,     -- Highest priority
    COALESCE(p_created_by, p_patient_id)
  )
  RETURNING id INTO v_geofence_id;
  
  RETURN v_geofence_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_default_home_geofence(UUID, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, UUID) TO authenticated;

-- =============================================================================
-- 9. CREATE VIEW: Geofence Statistics
-- =============================================================================

-- View to monitor geofence usage and effectiveness
CREATE OR REPLACE VIEW public.geofence_stats AS
SELECT 
  p.id AS patient_id,
  p.full_name AS patient_name,
  COUNT(g.id) AS total_geofences,
  COUNT(CASE WHEN g.is_active THEN 1 END) AS active_geofences,
  COUNT(CASE WHEN g.fence_type = 'safe' THEN 1 END) AS safe_zones,
  COUNT(CASE WHEN g.fence_type = 'danger' THEN 1 END) AS danger_zones,
  COUNT(CASE WHEN g.fence_type = 'home' THEN 1 END) AS home_zones,
  AVG(g.radius_meters)::INTEGER AS avg_radius_meters,
  MIN(g.created_at) AS first_geofence_created,
  MAX(g.updated_at) AS last_geofence_updated
FROM public.profiles p
LEFT JOIN public.geofences g ON p.id = g.patient_id
WHERE p.user_role = 'patient'
GROUP BY p.id, p.full_name
ORDER BY total_geofences DESC;

-- Grant view access
GRANT SELECT ON public.geofence_stats TO authenticated;

-- =============================================================================
-- 10. CREATE TRIGGER: Update timestamp
-- =============================================================================

-- Create trigger function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_geofences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_update_geofences_updated_at
  BEFORE UPDATE ON public.geofences
  FOR EACH ROW
  EXECUTE FUNCTION update_geofences_updated_at();

-- =============================================================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS
ALTER TABLE public.geofences ENABLE ROW LEVEL SECURITY;

-- Policy: Patients can view their own geofences
CREATE POLICY "Patients can view own geofences"
  ON public.geofences
  FOR SELECT
  USING (auth.uid() = patient_id);

-- Policy: Family members can view linked patient's geofences
CREATE POLICY "Family can view patient geofences"
  ON public.geofences
  FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  );

-- Policy: Family members can create geofences for linked patients
CREATE POLICY "Family can create patient geofences"
  ON public.geofences
  FOR INSERT
  WITH CHECK (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  );

-- Policy: Family members can update linked patient's geofences
CREATE POLICY "Family can update patient geofences"
  ON public.geofences
  FOR UPDATE
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  )
  WITH CHECK (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  );

-- Policy: Family members can delete linked patient's geofences
CREATE POLICY "Family can delete patient geofences"
  ON public.geofences
  FOR DELETE
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  );

-- =============================================================================
-- 12. VERIFICATION QUERIES
-- =============================================================================

-- Verify table created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'geofences') THEN
    RAISE EXCEPTION 'geofences table was not created!';
  END IF;
  
  RAISE NOTICE '✅ geofences table created successfully';
END $$;

-- Verify enum created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fence_type') THEN
    RAISE EXCEPTION 'fence_type enum was not created!';
  END IF;
  
  RAISE NOTICE '✅ fence_type enum created successfully';
END $$;

-- Verify spatial index created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_geofences_coordinates') THEN
    RAISE EXCEPTION 'Spatial index was not created!';
  END IF;
  
  RAISE NOTICE '✅ Spatial index created successfully';
END $$;

-- Verify RLS enabled
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'geofences' 
    AND rowsecurity = TRUE
  ) THEN
    RAISE EXCEPTION 'RLS is not enabled on geofences table!';
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
✅ Migration 009: Geofences (Safe Zones & Danger Zones) - COMPLETE
================================================================================
Created:
  - Enum: fence_type (safe, danger, home, hospital, school, custom)
  - Table: geofences (with PostGIS GEOGRAPHY type)
  - Indexes: patient_id, spatial index (GIST), fence_type, priority
  - Functions:
    * is_location_inside_geofence(geofence_id, location)
    * get_patient_geofences(patient_id)
    * check_location_geofences(patient_id, location)
    * get_nearest_geofence(patient_id, location, max_distance)
    * create_default_home_geofence(patient_id, lat, lon, ...)
  - View: geofence_stats (monitoring dashboard)
  - RLS Policies: 5 policies for patient & family access
  - Trigger: auto-update updated_at

Geofence Types:
  - safe: Safe zones (home, hospital, school)
  - danger: Danger zones (busy roads, unsafe areas)
  - home: Home location (special safe zone)
  - hospital: Medical facility
  - school: Educational institution
  - custom: Custom user-defined zone

Usage Examples:
  -- Create home geofence
  SELECT create_default_home_geofence(
    ''patient-uuid'',
    -6.2088,  -- Latitude (Jakarta)
    106.8456, -- Longitude
    100       -- Radius in meters
  );

  -- Check which geofences contain a location
  SELECT * FROM check_location_geofences(
    ''patient-uuid'',
    ST_Point(106.8456, -6.2088)::geography
  );

  -- Get nearest geofence
  SELECT * FROM get_nearest_geofence(
    ''patient-uuid'',
    ST_Point(106.8456, -6.2088)::geography,
    5000.0  -- Max 5km
  );

  -- View statistics
  SELECT * FROM geofence_stats;

Cost: $0.00 (Uses built-in PostGIS functions)
================================================================================
';
END $$;
