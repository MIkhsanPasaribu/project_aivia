# 📊 AIVIA Database SQL Scripts

## 📁 Structure

```
database/
├── 000_run_all_migrations.sql    # Master script (run this to setup all)
├── 001_initial_schema.sql        # Tables, indexes, constraints
├── 002_rls_policies.sql          # Row Level Security policies
├── 003_triggers_functions.sql    # Automation & helper functions
├── 004_realtime_config.sql       # Realtime subscriptions setup
├── 005_seed_data.sql             # Test data (optional, dev only)
└── README.md                     # This file
```

---

## 🚀 Quick Start

### Method 1: Run All at Once (Recommended)

1. Open [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to your project
3. Click **SQL Editor** (sidebar kiri)
4. Click **"New query"**
5. Copy semua isi file **`001_initial_schema.sql`**
6. Paste ke SQL Editor
7. Click **"Run"** atau tekan `Ctrl+Enter`
8. Tunggu hingga "Success. No rows returned"
9. Ulangi untuk file:
   - `002_rls_policies.sql`
   - `003_triggers_functions.sql`
   - `004_realtime_config.sql`
   - `005_seed_data.sql` (optional)

### Method 2: Run via Command Line (Advanced)

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to project
supabase link --project-ref your-project-ref

# Run migrations
psql $DATABASE_URL < database/001_initial_schema.sql
psql $DATABASE_URL < database/002_rls_policies.sql
psql $DATABASE_URL < database/003_triggers_functions.sql
psql $DATABASE_URL < database/004_realtime_config.sql

# Optional: Seed data
psql $DATABASE_URL < database/005_seed_data.sql
```

---

## 📄 File Descriptions

### `001_initial_schema.sql`

**Purpose**: Create all tables, indexes, and constraints

**Contents**:

- ✅ Enable extensions (uuid-ossp, vector, postgis)
- ✅ Create 10 tables:
  - `profiles` - User profiles
  - `patient_family_links` - Patient-family relationships
  - `activities` - Daily activity journal
  - `known_persons` - Face recognition database
  - `locations` - GPS tracking history
  - `emergency_contacts` - Emergency contact list
  - `emergency_alerts` - Emergency alert logs
  - `fcm_tokens` - Push notification tokens
  - `face_recognition_logs` - Recognition attempt logs
  - `notifications` - Notification delivery logs
- ✅ Create indexes for performance
- ✅ Create storage buckets (avatars, photos, etc)

**Run Time**: ~30 seconds

---

### `002_rls_policies.sql`

**Purpose**: Secure all tables with Row Level Security

**Contents**:

- ✅ Enable RLS on all tables
- ✅ Create 60+ RLS policies for:
  - Profile access control
  - Activity CRUD permissions
  - Location privacy
  - Emergency alert access
  - Family member permissions
  - Storage bucket policies
- ✅ Ensure users only see their own data
- ✅ Allow family to manage linked patients

**Run Time**: ~20 seconds

**Security Features**:

- 🔒 User can only view/edit their own profile
- 🔒 Family can only access linked patients
- 🔒 Patients can only insert their own location
- 🔒 Family can view patient location (if permitted)
- 🔒 Emergency contacts get alert notifications

---

### `003_triggers_functions.sql`

**Purpose**: Automate common operations

**Contents**:

- ✅ **Auto-create profile** on user signup
- ✅ **Auto-update timestamps** (updated_at)
- ✅ **Face recognition search** function
- ✅ **Update last_seen** when face recognized
- ✅ **Get latest location** helper
- ✅ **Calculate distance** between coordinates
- ✅ **Get nearby patients** for emergency
- ✅ **Activity statistics** calculator
- ✅ **Emergency notification** auto-creation
- ✅ **Activity reminder** notification
- ✅ **Dashboard stats** aggregation
- ✅ **Cleanup functions** for old data

**Run Time**: ~15 seconds

**Key Functions**:

- `handle_new_user()` - Auto-create profile
- `find_known_person()` - Face recognition search
- `get_latest_location()` - Get current position
- `calculate_distance()` - Distance in meters
- `get_activity_stats()` - Activity completion rate
- `get_patient_dashboard_stats()` - All stats in 1 query
- `get_family_dashboard_stats()` - Family overview

---

### `004_realtime_config.sql`

**Purpose**: Enable real-time data subscriptions

**Contents**:

- ✅ Create `supabase_realtime` publication
- ✅ Add all 10 tables to publication
- ✅ RLS automatically applies to Realtime
- ✅ Documentation for subscription patterns
- ✅ Performance optimization tips
- ✅ Error handling examples

**Run Time**: ~5 seconds

**Realtime Features**:

- 📡 **Activities**: See updates instantly
- 📡 **Locations**: Live GPS tracking
- 📡 **Emergency Alerts**: Instant notifications
- 📡 **Notifications**: Real-time delivery
- 📡 **Known Persons**: Database updates
- 📡 **Face Recognition**: Live recognition logs

---

### `005_seed_data.sql`

**Purpose**: Insert test data for development

⚠️ **WARNING: DEVELOPMENT ONLY! DO NOT RUN IN PRODUCTION!**

**Contents**:

- ✅ 5 test users (2 patients, 2 family, 1 admin)
- ✅ Patient-family links
- ✅ 13 sample activities
- ✅ 3 known persons with embeddings
- ✅ GPS location history
- ✅ Emergency contacts
- ✅ Sample emergency alert (resolved)
- ✅ Sample notifications
- ✅ Face recognition logs

**Run Time**: ~10 seconds

**Test Credentials**:

```
Email: budi@patient.com | Password: password123 (Patient)
Email: siti@patient.com | Password: password123 (Patient)
Email: ahmad@family.com | Password: password123 (Family)
Email: dewi@family.com | Password: password123 (Family)
Email: admin@aivia.com | Password: password123 (Admin)
```

---

## ✅ Verification

After running all migrations, verify with these queries:

### Check Tables

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected: 10 tables

### Check RLS Policies

```sql
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

Expected: 60+ policies

### Check Realtime Tables

```sql
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
```

Expected: 10 tables

### Check Functions

```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

Expected: 15+ functions

---

## 🔧 Troubleshooting

### Error: "extension does not exist"

**Solution**: Extensions mungkin tidak installed. Contact Supabase support atau enable di Settings > Database > Extensions.

### Error: "permission denied"

**Solution**: Pastikan Anda login sebagai owner project di Supabase Dashboard.

### Error: "relation already exists"

**Solution**: Tabel sudah dibuat sebelumnya. Drop tables dulu atau skip file yang error.

### Error: "function does not exist"

**Solution**: Pastikan run migrations sesuai urutan (001 → 002 → 003 → 004).

### Error: "cannot create RLS policy"

**Solution**: RLS mungkin sudah enabled. Drop existing policies atau ubah CREATE menjadi CREATE OR REPLACE.

---

## 🔄 Migration Management

### Adding New Migration

1. Create new file: `006_your_migration_name.sql`
2. Add rollback script: `006_your_migration_name_rollback.sql`
3. Test di development dulu
4. Document changes di README
5. Run di production

### Rollback Migration

```sql
-- Example rollback for new table
DROP TABLE IF EXISTS public.your_new_table CASCADE;
```

### Version Control

- ✅ Commit SQL files ke git
- ✅ Tag release versions
- ✅ Document breaking changes
- ❌ Never edit existing migration files
- ❌ Never delete migration files

---

## 📊 Database Schema Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                         AIVIA Database                          │
└─────────────────────────────────────────────────────────────────┘

auth.users (Supabase Auth)
    │
    ├─ 1:1 ─► profiles
    │             │
    │             ├─ 1:N ─► activities
    │             ├─ 1:N ─► known_persons
    │             ├─ 1:N ─► locations
    │             ├─ 1:N ─► fcm_tokens
    │             ├─ 1:N ─► face_recognition_logs
    │             ├─ 1:N ─► notifications
    │             │
    │             └─ M:N ─► patient_family_links ◄─ M:N ─┐
    │                                                       │
    └─────────────────────────────────────────────────────┘

emergency_contacts ─► profiles (contact_id)
emergency_alerts ─► profiles (patient_id)
```

---

## 📈 Performance Tips

1. **Indexes**: Semua foreign keys sudah di-index
2. **Partial Indexes**: Digunakan untuk queries spesifik
3. **BRIN Indexes**: Consider untuk timestamp columns jika data > 10M rows
4. **Partitioning**: Consider untuk `locations` table jika data > 50M rows
5. **Vacuum**: Run `VACUUM ANALYZE` setiap minggu

---

## 🔒 Security Checklist

- ✅ RLS enabled pada semua tabel
- ✅ RLS policies tested untuk setiap user role
- ✅ Storage buckets dengan proper policies
- ✅ Functions dengan SECURITY DEFINER hanya jika perlu
- ✅ Sensitive data encrypted (passwords, tokens)
- ✅ No hardcoded credentials
- ✅ Audit logging enabled (via Supabase Dashboard)

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [PostGIS Docs](https://postgis.net/documentation/)
- [pgvector Docs](https://github.com/pgvector/pgvector)

---

## 🆘 Support

Jika ada masalah:

1. Check [Supabase Status](https://status.supabase.com/)
2. Lihat logs di Dashboard > Logs > Database
3. Ask di [Supabase Discord](https://discord.supabase.com/)
4. Buka issue di repository

---

**Created**: 8 Oktober 2025  
**Version**: 1.0.0  
**For**: AIVIA Development Team  
**Status**: ✅ Production Ready
