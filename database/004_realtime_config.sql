-- =====================================================
-- AIVIA Database - Realtime Configuration
-- Version: 1.0.0
-- Date: 8 Oktober 2025
-- Description: Enable Realtime subscriptions untuk real-time updates
-- =====================================================

-- =====================================================
-- IMPORTANT: Realtime Overview
-- =====================================================
-- Supabase Realtime menggunakan PostgreSQL's LISTEN/NOTIFY
-- untuk broadcast changes ke semua connected clients.
-- 
-- Benefits:
-- - UI auto-update saat data berubah
-- - No manual refresh needed
-- - Real-time collaboration
-- - Instant notifications
-- =====================================================

-- =====================================================
-- STEP 1: Enable Realtime pada Publication
-- =====================================================

-- Drop existing publication if exists
DROP PUBLICATION IF EXISTS supabase_realtime;

-- Create publication untuk Realtime
CREATE PUBLICATION supabase_realtime;

-- =====================================================
-- STEP 2: Add Tables to Realtime Publication
-- =====================================================

-- Enable Realtime untuk profiles
-- Use case: See when user profile updated (avatar, name, etc)
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- Enable Realtime untuk patient_family_links
-- Use case: See when new family member linked/unlinked
ALTER PUBLICATION supabase_realtime ADD TABLE public.patient_family_links;

-- Enable Realtime untuk activities
-- Use case: See when activities created/updated/completed in real-time
-- This is CRITICAL for patient-family coordination
ALTER PUBLICATION supabase_realtime ADD TABLE public.activities;

-- Enable Realtime untuk known_persons
-- Use case: See when new person added to known persons database
ALTER PUBLICATION supabase_realtime ADD TABLE public.known_persons;

-- Enable Realtime untuk locations
-- Use case: Real-time location tracking for family members
-- VERY IMPORTANT for safety monitoring
ALTER PUBLICATION supabase_realtime ADD TABLE public.locations;

-- Enable Realtime untuk emergency_contacts
-- Use case: See when emergency contacts updated
ALTER PUBLICATION supabase_realtime ADD TABLE public.emergency_contacts;

-- Enable Realtime untuk emergency_alerts
-- Use case: INSTANT notification saat emergency button dipicu
-- CRITICAL for emergency response
ALTER PUBLICATION supabase_realtime ADD TABLE public.emergency_alerts;

-- Enable Realtime untuk fcm_tokens
-- Use case: Track active devices
ALTER PUBLICATION supabase_realtime ADD TABLE public.fcm_tokens;

-- Enable Realtime untuk face_recognition_logs
-- Use case: See recognition attempts in real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.face_recognition_logs;

-- Enable Realtime untuk notifications
-- Use case: Real-time notification delivery to UI
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- =====================================================
-- STEP 3: Configure Realtime Filters (via Supabase Dashboard)
-- =====================================================

-- Note: RLS policies automatically apply to Realtime subscriptions
-- Clients will only receive updates for rows they have access to
-- based on RLS policies defined in 002_rls_policies.sql

-- =====================================================
-- STEP 4: Example Subscription Patterns (for Documentation)
-- =====================================================

-- Pattern 1: Subscribe to own activities (Patient)
-- Dart code:
/*
final activitiesStream = supabase
  .from('activities')
  .stream(primaryKey: ['id'])
  .eq('patient_id', userId)
  .order('activity_time');
*/

-- Pattern 2: Subscribe to linked patients' activities (Family)
-- Dart code:
/*
final linkedPatientsIds = await getLinkedPatientIds();
final activitiesStream = supabase
  .from('activities')
  .stream(primaryKey: ['id'])
  .inFilter('patient_id', linkedPatientsIds)
  .order('activity_time');
*/

-- Pattern 3: Subscribe to emergency alerts (Family)
-- Dart code:
/*
final alertsStream = supabase
  .from('emergency_alerts')
  .stream(primaryKey: ['id'])
  .eq('status', 'active')
  .order('created_at', ascending: false);
*/

-- Pattern 4: Subscribe to real-time location (Family)
-- Dart code:
/*
final locationStream = supabase
  .from('locations')
  .stream(primaryKey: ['id'])
  .eq('patient_id', patientId)
  .order('timestamp', ascending: false)
  .limit(1);
*/

-- Pattern 5: Subscribe to notifications
-- Dart code:
/*
final notificationsStream = supabase
  .from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .eq('is_read', false)
  .order('created_at', ascending: false);
*/

-- =====================================================
-- STEP 5: Realtime Event Types
-- =====================================================

-- Supabase Realtime supports 4 event types:
-- 1. INSERT - When new row is inserted
-- 2. UPDATE - When existing row is updated
-- 3. DELETE - When row is deleted
-- 4. * (ALL) - All events

-- Example: Listen to specific events
/*
supabase
  .channel('activities-changes')
  .on('postgres_changes', 
    {
      event: 'INSERT',
      schema: 'public',
      table: 'activities',
      filter: 'patient_id=eq.$userId'
    },
    (payload) {
      print('New activity: ${payload.new}');
    }
  )
  .subscribe();
*/

-- =====================================================
-- STEP 6: Realtime Performance Optimization
-- =====================================================

-- For high-frequency updates (like locations), consider:
-- 1. Client-side throttling/debouncing
-- 2. Only subscribe when screen is active
-- 3. Use .limit() to reduce payload size

-- Example: Throttled location updates
/*
final locationStream = supabase
  .from('locations')
  .stream(primaryKey: ['id'])
  .eq('patient_id', patientId)
  .order('timestamp', ascending: false)
  .limit(1);

// In widget:
StreamBuilder(
  stream: locationStream.throttleTime(Duration(seconds: 5)),
  builder: (context, snapshot) { ... }
)
*/

-- =====================================================
-- STEP 7: Realtime Connection Management
-- =====================================================

-- Best practices:
-- 1. Unsubscribe when widget disposed
-- 2. Use StreamBuilder for automatic management
-- 3. Handle connection errors gracefully
-- 4. Reconnect on app resume

-- Example:
/*
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = supabase
      .from('activities')
      .stream(primaryKey: ['id'])
      .listen((data) {
        // Handle updates
      });
  }
  
  @override
  void dispose() {
    _subscription.cancel(); // Important!
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) { ... }
}
*/

-- =====================================================
-- STEP 8: Realtime Monitoring
-- =====================================================

-- Monitor Realtime connections in Supabase Dashboard:
-- 1. Go to Database > Replication
-- 2. Check publication: supabase_realtime
-- 3. View connected clients
-- 4. Monitor message throughput

-- =====================================================
-- STEP 9: Realtime Channels (Advanced)
-- =====================================================

-- For presence and broadcast features (future):
/*
// Presence: Track online users
final channel = supabase.channel('room:$roomId')
  .onPresenceSync((presences) {
    print('Online users: $presences');
  })
  .subscribe();

// Broadcast: Send messages between clients
channel.send(
  type: 'broadcast',
  event: 'cursor-pos',
  payload: {'x': 100, 'y': 200}
);
*/

-- =====================================================
-- STEP 10: Realtime Error Handling
-- =====================================================

-- Common errors and solutions:
-- 1. "403 Forbidden" - Check RLS policies
-- 2. "Too many connections" - Implement connection pooling
-- 3. "Timeout" - Check network, increase timeout
-- 4. "Invalid filter" - Verify column names and types

-- Example with error handling:
/*
final stream = supabase
  .from('activities')
  .stream(primaryKey: ['id'])
  .handleError((error) {
    print('Stream error: $error');
    // Optionally reconnect
  });
*/

-- =====================================================
-- STEP 11: Create Realtime Notification Function
-- =====================================================

-- Function untuk notify clients via pg_notify (optional, for custom events)
CREATE OR REPLACE FUNCTION public.notify_realtime_channel(
  channel_name TEXT,
  payload JSON
)
RETURNS VOID
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM pg_notify(channel_name, payload::text);
END;
$$;

COMMENT ON FUNCTION public.notify_realtime_channel IS 'Send custom notification via PostgreSQL NOTIFY';

-- Example trigger using pg_notify:
CREATE OR REPLACE FUNCTION public.notify_on_critical_alert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.severity = 'critical' THEN
    PERFORM pg_notify(
      'critical_alerts',
      json_build_object(
        'alert_id', NEW.id,
        'patient_id', NEW.patient_id,
        'timestamp', NEW.created_at
      )::text
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_critical_alert ON public.emergency_alerts;
CREATE TRIGGER notify_critical_alert
  AFTER INSERT ON public.emergency_alerts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_critical_alert();

-- =====================================================
-- STEP 12: Verify Realtime Setup
-- =====================================================

-- Query to check which tables are in publication
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY schemaname, tablename;

-- Expected output:
-- public | activities
-- public | emergency_alerts
-- public | face_recognition_logs
-- public | fcm_tokens
-- public | known_persons
-- public | locations
-- public | notifications
-- public | patient_family_links
-- public | profiles
-- public | emergency_contacts

-- =====================================================
-- STEP 13: Realtime Testing Checklist
-- =====================================================

-- Test Realtime dari 2 devices/browser tabs:
-- 
-- TEST 1: Activity CRUD
-- - Tab A: Subscribe to activities stream
-- - Tab B: Insert new activity
-- - Tab A: Should auto-update with new activity ✅
--
-- TEST 2: Emergency Alert
-- - Tab A (Family): Subscribe to emergency_alerts
-- - Tab B (Patient): Insert emergency alert
-- - Tab A: Should receive alert instantly ✅
--
-- TEST 3: Location Tracking
-- - Tab A (Family): Subscribe to locations
-- - Tab B (Patient): Insert new location
-- - Tab A: Map should update instantly ✅
--
-- TEST 4: Face Recognition
-- - Tab A (Patient): Subscribe to known_persons
-- - Tab B (Family): Add new known person
-- - Tab A: Should see new person instantly ✅
--
-- TEST 5: Notifications
-- - Tab A: Subscribe to notifications
-- - Tab B: Trigger action that creates notification
-- - Tab A: Should see notification instantly ✅

-- =====================================================
-- STEP 14: Realtime Scaling Considerations
-- =====================================================

-- For production with many concurrent users:
--
-- 1. Connection Pooling:
--    - Use Supavisor (Supabase's connection pooler)
--    - Configure max_connections in database
--
-- 2. Rate Limiting:
--    - Limit subscription frequency per client
--    - Implement exponential backoff on reconnect
--
-- 3. Payload Size:
--    - Only select necessary columns
--    - Use pagination for large datasets
--
-- 4. Geographic Distribution:
--    - Use Supabase Edge Network
--    - Deploy closer to users
--
-- 5. Monitoring:
--    - Track connection count
--    - Monitor bandwidth usage
--    - Set up alerts for anomalies

-- =====================================================
-- STEP 15: Realtime Security Best Practices
-- =====================================================

-- Security checklist:
-- ✅ RLS enabled on all tables
-- ✅ RLS policies tested thoroughly
-- ✅ Only necessary columns exposed
-- ✅ Sensitive data encrypted
-- ✅ Connection authenticated via JWT
-- ✅ Rate limiting enabled
-- ✅ Monitoring and logging active

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
DECLARE
  table_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO table_count
  FROM pg_publication_tables
  WHERE pubname = 'supabase_realtime';
  
  RAISE NOTICE '✅ Realtime configuration completed successfully!';
  RAISE NOTICE '📡 Realtime enabled for % tables', table_count;
  RAISE NOTICE '🔄 Real-time subscriptions ready:';
  RAISE NOTICE '   - profiles (user updates)';
  RAISE NOTICE '   - activities (activity CRUD)';
  RAISE NOTICE '   - locations (live tracking)';
  RAISE NOTICE '   - emergency_alerts (instant alerts)';
  RAISE NOTICE '   - notifications (push notifications)';
  RAISE NOTICE '   - face_recognition_logs (recognition events)';
  RAISE NOTICE '   - known_persons (database updates)';
  RAISE NOTICE '   - patient_family_links (relationship changes)';
  RAISE NOTICE '   - emergency_contacts (contact updates)';
  RAISE NOTICE '   - fcm_tokens (device tracking)';
  RAISE NOTICE '🔒 RLS policies automatically apply to Realtime';
  RAISE NOTICE '📝 Next: Run 005_seed_data.sql for test data (optional)';
END $$;
