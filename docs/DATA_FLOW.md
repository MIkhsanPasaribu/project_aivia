# 🔄 Data Flow Architecture - AIVIA

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               PRESENTATION LAYER                         │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │   │
│  │  │ Screens  │──│ Widgets  │──│ Providers │              │   │
│  │  │          │  │          │  │ (Riverpod)│              │   │
│  │  └──────────┘  └──────────┘  └─────┬─────┘              │   │
│  └─────────────────────────────────────┼─────────────────────┘   │
│                                         │                         │
│  ┌─────────────────────────────────────┼─────────────────────┐   │
│  │                DOMAIN LAYER          │                     │   │
│  │  ┌──────────┐                       │                     │   │
│  │  │ Use Cases│◄──────────────────────┘                     │   │
│  │  └────┬─────┘                                             │   │
│  └───────┼────────────────────────────────────────────────────┘   │
│          │                                                         │
│  ┌───────┼────────────────────────────────────────────────────┐   │
│  │       │        DATA LAYER                                  │   │
│  │  ┌────▼──────┐  ┌──────────────┐  ┌──────────────┐       │   │
│  │  │Repositories│──│   Models     │──│   Services   │       │   │
│  │  └────┬───────┘  └──────────────┘  └──────┬───────┘       │   │
│  └───────┼────────────────────────────────────┼────────────────┘   │
│          │                                     │                   │
│  ┌───────┼─────────────────────────────────────┼────────────────┐  │
│  │       │         CORE LAYER                  │                │  │
│  │  ┌────▼──────┐  ┌──────────┐  ┌────────────▼─────┐         │  │
│  │  │  Config   │  │Constants │  │     Utils        │         │  │
│  │  │(.env read)│  │(strings) │  │(validators, etc) │         │  │
│  │  └────┬──────┘  └──────────┘  └──────────────────┘         │  │
│  └───────┼──────────────────────────────────────────────────────┘  │
│          │                                                          │
└──────────┼──────────────────────────────────────────────────────────┘
           │
           │ HTTPS + RLS
           ▼
┌──────────────────────────────────────────────────────────────────┐
│                      SUPABASE BACKEND                             │
├──────────────────────────────────────────────────────────────────┤
│  ┌────────────┐  ┌──────────────┐  ┌─────────────┐             │
│  │   Auth     │  │  PostgreSQL  │  │  Storage    │             │
│  │ (JWT)      │  │  (with RLS)  │  │  (Files)    │             │
│  └────────────┘  └──────────────┘  └─────────────┘             │
│                                                                   │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────┐             │
│  │  Realtime  │  │ Edge Funcs   │  │   Webhooks  │             │
│  │(WebSocket) │  │   (Deno)     │  │             │             │
│  └────────────┘  └──────────────┘  └─────────────┘             │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Environment Variables Flow

```
┌────────────────┐
│   .env file    │  ← Kredensial asli (NOT COMMITTED)
└───────┬────────┘
        │
        │ flutter_dotenv.load()
        ▼
┌────────────────┐
│  dotenv.env    │  ← Loaded to memory
└───────┬────────┘
        │
        │ SupabaseConfig.supabaseUrl
        │ SupabaseConfig.supabaseAnonKey
        ▼
┌────────────────┐
│ Supabase.init  │  ← Initialize client
└───────┬────────┘
        │
        │ Supabase.instance.client
        ▼
┌────────────────┐
│  Repositories  │  ← Use client for database operations
└────────────────┘
```

**Security:**

- ✅ `.env` tidak di-commit (di `.gitignore`)
- ✅ Kredensial hanya di memory saat runtime
- ✅ RLS policies protect data access

---

## 🔄 Authentication Flow

```
┌──────────┐
│  User    │
└────┬─────┘
     │ 1. Submit register form
     ▼
┌──────────────────┐
│ RegisterScreen   │
└────┬─────────────┘
     │ 2. Validate input
     ▼
┌──────────────────┐
│   Validators     │
└────┬─────────────┘
     │ 3. Call signUp
     ▼
┌──────────────────┐
│ AuthRepository   │ (Future)
└────┬─────────────┘
     │ 4. supabase.auth.signUp()
     ▼
┌──────────────────────────────────┐
│      Supabase Auth Service       │
├──────────────────────────────────┤
│  • Create user in auth.users     │
│  • Trigger: handle_new_user()    │
│  • Create profile in profiles    │
│  • Return JWT token              │
└────┬─────────────────────────────┘
     │ 5. Auth state changed
     ▼
┌──────────────────┐
│ AuthProvider     │ (Future)
│  (Riverpod)      │
└────┬─────────────┘
     │ 6. Navigate to home
     ▼
┌──────────────────┐
│ PatientHomeScreen│
└──────────────────┘
```

**Advantages:**

- ✅ Auto-create profile via trigger
- ✅ JWT token for secure API calls
- ✅ RLS uses auth.uid() for policies

---

## 📝 Activity CRUD Flow

### READ (Get Activities)

```
┌──────────────────┐
│ActivityListScreen│
└────┬─────────────┘
     │ 1. Build widget
     ▼
┌──────────────────────┐
│ref.watch(            │
│ activitiesProvider)  │  ← Riverpod Provider (Future)
└────┬─────────────────┘
     │ 2. Subscribe to stream
     ▼
┌──────────────────────┐
│ ActivityRepository   │
│  .getActivities()    │
└────┬─────────────────┘
     │ 3. supabase.from('activities')
     │    .stream()
     │    .eq('patient_id', userId)
     ▼
┌─────────────────────────────────┐
│      Supabase Database          │
├─────────────────────────────────┤
│  SELECT * FROM activities       │
│  WHERE patient_id = auth.uid()  │  ← RLS Policy
│  ORDER BY activity_time         │
└────┬────────────────────────────┘
     │ 4. Stream<List<Activity>>
     ▼
┌──────────────────────┐
│ref.watch() updates   │
└────┬─────────────────┘
     │ 5. Widget rebuilds
     ▼
┌──────────────────────┐
│ UI shows activities  │
└──────────────────────┘
```

### CREATE (Add Activity)

```
┌──────────────────┐
│  User taps FAB   │
└────┬─────────────┘
     │ 1. Navigate to form
     ▼
┌──────────────────┐
│AddActivityScreen │
└────┬─────────────┘
     │ 2. Submit form
     ▼
┌──────────────────────┐
│ ActivityRepository   │
│  .addActivity()      │
└────┬─────────────────┘
     │ 3. supabase.from('activities')
     │    .insert(activity.toJson())
     ▼
┌─────────────────────────────────┐
│      Supabase Database          │
├─────────────────────────────────┤
│  INSERT INTO activities (...)   │
│  VALUES (...)                   │  ← RLS checks INSERT policy
└────┬────────────────────────────┘
     │ 4. Success response
     ▼
┌──────────────────────┐
│ Stream auto-updates  │  ← Real-time subscription
└────┬─────────────────┘
     │ 5. UI auto-refreshes
     ▼
┌──────────────────────┐
│ New activity appears │
└──────────────────────┘
```

**Advantages:**

- ✅ Real-time updates (no manual refresh)
- ✅ RLS validates user can insert
- ✅ Automatic timestamp (trigger)

---

## 🎨 Widget Tree Example (Patient Home)

```
MaterialApp
 └─ PatientHomeScreen
     └─ Scaffold
         ├─ AppBar
         │   └─ Text ("AIVIA")
         │
         ├─ Body: IndexedStack
         │   ├─ [0] ActivityListScreen
         │   │   └─ Consumer (ref.watch)
         │   │       └─ StreamBuilder
         │   │           └─ ListView.builder
         │   │               └─ ActivityCard (x N)
         │   │
         │   ├─ [1] RecognizeFaceScreen (Coming soon)
         │   └─ [2] ProfileScreen
         │
         └─ BottomNavigationBar
             ├─ Item: Beranda
             ├─ Item: Kenali Wajah
             └─ Item: Profil
```

---

## 🔄 State Management with Riverpod

### Provider Pattern

```dart
// 1. Define Provider
@riverpod
Stream<List<Activity>> activitiesStream(
  ActivitiesStreamRef ref,
  String patientId,
) {
  final supabase = Supabase.instance.client;
  return supabase
    .from('activities')
    .stream(primaryKey: ['id'])
    .eq('patient_id', patientId)
    .map((data) => data.map((json) => Activity.fromJson(json)).toList());
}

// 2. Consume in Widget
class ActivityListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider(userId));

    return activitiesAsync.when(
      data: (activities) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

**Flow:**

```
User Action
    │
    ▼
Widget calls ref.watch()
    │
    ▼
Provider executes logic
    │
    ▼
Data fetched from Supabase
    │
    ▼
Provider emits new state
    │
    ▼
Widget rebuilds with new data
```

---

## 📦 Dependency Injection Flow

```
main()
  │
  ├─ dotenv.load()                ← Load .env
  ├─ Supabase.initialize()        ← Init backend client
  ├─ AwesomeNotifications.init()  ← Init notifications (Future)
  │
  └─ runApp(ProviderScope(        ← Riverpod container
       child: MainApp()
     ))
```

**Provider Scope:**

- All providers accessible via `ref.watch()`, `ref.read()`
- Singleton pattern for services
- Automatic disposal

---

## 🔐 Row Level Security (RLS) in Action

### Example: User tries to read activities

```
┌────────────────────┐
│  Flutter App       │
│  userId = 'abc123' │
└────┬───────────────┘
     │ GET /rest/v1/activities
     │ Authorization: Bearer <anon-key>
     ▼
┌─────────────────────────────────┐
│      Supabase API Gateway       │
├─────────────────────────────────┤
│  1. Verify JWT token            │
│  2. Extract auth.uid() = abc123 │
└────┬────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│      PostgreSQL Query           │
├─────────────────────────────────┤
│  SELECT * FROM activities       │
│  WHERE patient_id = 'abc123'    │  ← Applied by RLS
│  AND (                          │
│    patient_id = auth.uid()      │  ← Policy check
│    OR EXISTS (                  │
│      SELECT 1 FROM              │
│      patient_family_links       │
│      WHERE family_member_id =   │
│        auth.uid()               │
│    )                            │
│  )                              │
└────┬────────────────────────────┘
     │ Only returns allowed rows
     ▼
┌────────────────────┐
│  Flutter App       │
│  Receives: [...]   │
└────────────────────┘
```

**Security Guarantees:**

- ✅ User can't access other users' data
- ✅ Enforced at database level (not client)
- ✅ Even if client is compromised, data is safe

---

## 📊 Real-time Updates Flow

```
┌────────────────────────────────────────┐
│         Database Change                │
│  INSERT INTO activities (...)          │
└────┬───────────────────────────────────┘
     │
     ▼
┌────────────────────────────────────────┐
│    Supabase Realtime (WebSocket)       │
│  Detects change in subscribed table    │
└────┬───────────────────────────────────┘
     │ Broadcast to all connected clients
     │
     ▼
┌────────────────────────────────────────┐
│    Flutter App (All instances)         │
│  Stream<List<Activity>> emits new data │
└────┬───────────────────────────────────┘
     │
     ▼
┌────────────────────────────────────────┐
│         Widget Rebuilds                │
│  UI automatically shows new activity   │
└────────────────────────────────────────┘
```

**Use Cases:**

- ✅ Family adds activity → Patient sees it instantly
- ✅ Activity completed → Family dashboard updates
- ✅ Emergency alert → All family members notified

---

## 🎯 Summary

### Key Architectural Decisions

1. **Clean Architecture**

   - Separation of concerns (Presentation, Domain, Data, Core)
   - Testable and maintainable

2. **Supabase Direct Client**

   - No need for custom backend
   - Built-in auth, real-time, storage
   - RLS for security

3. **Riverpod for State Management**

   - Type-safe, compile-time checked
   - Code generation for boilerplate reduction
   - Easy testing with ProviderContainer

4. **Environment Variables**

   - Secure credential management
   - Easy multi-environment (dev/prod)
   - No hardcoded secrets

5. **Real-time by Default**
   - Automatic UI updates
   - No manual refresh needed
   - Better UX for users

---

**Created:** 8 Oktober 2025  
**Version:** 1.0.0  
**For:** AIVIA Development Team
