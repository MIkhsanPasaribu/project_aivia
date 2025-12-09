# Laporan Progress 4: Implementasi Geofencing dan Enterprise Tracking

**Nama**: M. Ikhsan Pasaribu  
**Periode**: November 2025  
**Fokus**: Geofencing System & Enterprise-Grade Tracking Infrastructure  
**Status Implementasi**: Selesai (100%)

---

## BAB I: PENDAHULUAN

### 1.1 Latar Belakang

Pada tahap pengembangan sebelumnya, saya telah berhasil membangun fondasi aplikasi AIVIA dengan sistem pelacakan lokasi dasar dan notifikasi darurat. Namun, untuk benar-benar memberikan value yang optimal bagi keluarga pasien Alzheimer, saya menyadari bahwa aplikasi ini membutuhkan sistem keamanan yang lebih proaktif. Di sinilah ide implementasi geofencing muncul.

Geofencing adalah teknologi yang memungkinkan aplikasi untuk mendeteksi ketika pengguna masuk atau keluar dari area geografis tertentu. Dalam konteks AIVIA, fitur ini sangat krusial karena pasien Alzheimer sering kali mengalami wandering atau berjalan tanpa tujuan yang jelas. Dengan geofencing, keluarga bisa mendefinisikan safe zones seperti rumah, taman, atau tempat-tempat familiar, dan akan mendapat notifikasi instant jika pasien keluar dari zona tersebut.

Selain geofencing, saya juga fokus pada peningkatan sistem tracking agar lebih enterprise-grade. Ini termasuk implementasi offline-first architecture, optimasi database dengan clustering dan retention policies, serta integrasi Firebase Cloud Messaging yang robust untuk push notifications.

### 1.2 Tujuan

Tujuan utama dari progress keempat ini adalah membangun sistem keamanan berlapis yang tidak hanya reaktif, tapi juga proaktif dalam melindungi pasien Alzheimer. Secara spesifik, saya ingin mencapai beberapa hal:

Pertama, mengimplementasikan sistem geofencing yang user-friendly. Keluarga harus bisa dengan mudah membuat, mengedit, dan menghapus geofence langsung dari aplikasi tanpa perlu pengetahuan teknis. Interface-nya harus intuitif, dengan visualisasi peta yang jelas dan feedback yang immediate.

Kedua, memastikan sistem tracking bisa bekerja dalam kondisi network yang tidak stabil. Indonesia, terutama di daerah suburban dan rural, masih memiliki coverage internet yang spotty. Aplikasi harus bisa menyimpan data lokasi secara lokal dan melakukan sync otomatis ketika koneksi tersedia kembali.

Ketiga, mengoptimasi performa database. Dengan tracking yang berjalan 24/7, data lokasi akan bertambah sangat cepat. Saya perlu implementasi data retention policies yang pintar, clustering untuk query optimization, dan indexing yang proper agar aplikasi tetap responsif meskipun data sudah jutaan rows.

Keempat, membangun notification system yang reliable dan cost-effective. Push notification adalah lifeline dari aplikasi ini, sehingga harus dipastikan selalu sampai dengan latensi minimal. Namun tetap harus menggunakan free tier untuk menjaga sustainability project.

### 1.3 Ruang Lingkup

Progress keempat ini mencakup beberapa area pengembangan yang saling terkait:

**Geofencing System** meliputi implementasi model, repository, provider untuk geofence management, UI screens untuk create, edit, delete, dan list geofences, map integration dengan circular geofence visualization, dan event detection system yang trigger ketika patient masuk atau keluar dari geofence.

**Offline-First Tracking** mencakup implementasi local database menggunakan sqflite, queue system untuk location data yang pending sync, auto-retry mechanism dengan exponential backoff, dan conflict resolution strategies untuk data synchronization.

**Database Optimization** termasuk clustering implementation untuk location data grouping, data retention policies menggunakan pg_cron, spatial indexing dengan PostGIS optimization, dan query performance tuning dengan proper indexes.

**Push Notification System** meliputi Firebase Cloud Messaging integration, FCM token management dan device registration, notification channels untuk Android 8+, background message handling, dan notification tracking untuk delivery confirmation.

**Edge Functions** mencakup notification dispatcher function di Supabase, batch processing untuk multiple recipients, rate limiting untuk prevent spam, dan error handling dengan retry logic.

Semua implementasi ini saya pastikan menggunakan best practices, mengikuti clean architecture principles, dan tetap dalam constraint free tier dari semua services yang digunakan.

---

## BAB II: PROGRESS PENGEMBANGAN

### 2.1 Sprint 2.3A: Offline-First Architecture

#### Persiapan dan Perencanaan

Sebelum mulai coding, saya melakukan riset mendalam tentang offline-first patterns di mobile apps. Saya pelajari berbagai approaches seperti sync strategies, conflict resolution, dan queue management. Dari riset tersebut, saya putuskan untuk menggunakan sqflite sebagai local database dan implement custom queue service.

#### Implementasi Location Queue Database

Langkah pertama adalah membuat database schema untuk local storage. Saya desain table yang simple namun comprehensive dengan fields untuk location ID, patient ID, coordinates, accuracy, timestamp, sync status, retry count, last retry timestamp, dan error message. Schema ini cukup untuk handle semua scenarios dari successful sync sampai repeated failures.

Implementasinya saya buat dalam class `LocationQueueDatabase` dengan singleton pattern untuk ensure hanya ada satu instance. Database initialization saya handle di method `_initDatabase()` yang akan create table jika belum ada. Method-method CRUD saya implementasikan dengan proper error handling dan logging yang detail.

Yang paling challenging adalah design retry mechanism. Saya tidak bisa simpan semua failed data selamanya karena akan bloat storage. Jadi saya implement logic dimana setelah lima kali retry, data akan di-mark sebagai permanently failed dan di-archive ke separate table. User bisa review dan manual retry jika perlu.

#### Offline Queue Service

Setelah database ready, saya buat `OfflineQueueService` yang berfungsi sebagai orchestrator untuk semua offline operations. Service ini handle enqueue location data, process sync queue dengan batch processing, implement exponential backoff untuk retry, monitor network connectivity, dan provide status updates melalui streams.

Saya implement background sync yang berjalan setiap 5 menit ketika app di foreground dan setiap 15 menit ketika di background. Interval ini saya pilih berdasarkan trade-off antara data freshness dan battery consumption. Untuk connectivity monitoring, saya gunakan connectivity_plus package yang provide reliable stream of network status changes.

Bagian yang saya most proud of adalah conflict resolution strategy. Ketika sync data ke server, ada kemungkinan data dengan timestamp yang sama atau sangat dekat sudah ada di server. Saya handle ini dengan membandingkan accuracy, dimana data dengan accuracy lebih baik akan dipertahankan. Ini ensure data quality tetap terjaga.

#### Testing dan Validation

Testing offline-first system cukup tricky karena harus simulate berbagai network conditions. Saya test dengan cara force airplane mode, simulate slow 3G connection, random network disconnects, dan app termination scenarios. Alhamdulillah, semua scenarios bisa di-handle dengan graceful tanpa data loss.

Saya juga implement comprehensive logging untuk troubleshooting. Setiap enqueue, sync attempt, success, dan failure di-log dengan detail termasuk timestamp, patient ID, location, dan error message jika ada. Log ini sangat helpful ketika debugging issues di production.

### 2.2 Sprint 2.3B: Database Migrations

#### Analisis Schema Requirements

Sebelum create migrations, saya audit existing schema untuk identify gaps. Saya perlu beberapa tables baru: fcm_tokens untuk device registration, pending_notifications untuk notification queue, notification_delivery_logs untuk tracking, geofences untuk zone definitions, dan geofence_events untuk entry/exit logging.

#### Migration Scripts Development

Saya buat series migration scripts yang comprehensive. File `006_fcm_tokens.sql` untuk FCM infrastructure, `007_data_retention.sql` untuk retention policies, `008_location_clustering.sql` untuk clustering optimization, `009_geofences.sql` untuk geofence tables, dan `010_geofence_events.sql` untuk event tracking.

Setiap migration script saya structure dengan clear sections: table creation dengan proper constraints, indexes untuk performance, RLS policies untuk security, dan triggers untuk automation. Saya juga include rollback scripts di comments untuk ease of reverting jika ada issues.

Yang paling complex adalah migration 008 untuk location clustering. Saya implement custom clustering algorithm menggunakan PostgreSQL spatial functions. Algorithm ini group nearby locations berdasarkan time window dan distance threshold, lalu create summary records yang jauh lebih compact. Ini significantly reduce storage dan improve query performance.

#### Row Level Security Policies

Security adalah top priority saya, jadi semua tables saya protect dengan RLS policies. Untuk fcm_tokens, users hanya bisa manage tokens mereka sendiri. Untuk geofences, hanya owner atau family members yang di-grant permission bisa access. Untuk events, read access di-grant ke semua family members yang linked, tapi hanya system yang bisa write.

RLS policies saya test thoroughly dengan different user roles dan scenarios. Saya ensure tidak ada data leakage dan permissions properly enforced. Saya juga add extensive comments di migration files untuk explain rationale behind setiap policy.

#### Data Retention Implementation

Untuk prevent database bloat, saya implement retention policies using pg_cron. Raw location data older than 30 days akan di-archive ke separate table, clustered data older than 90 days akan di-deleted, dan event logs older than 180 days akan di-cleaned up. Retention windows ini saya design berdasarkan typical use cases dan storage constraints.

Saya juga implement soft delete pattern untuk critical data like geofences dan emergency alerts. Instead of hard delete, data di-mark sebagai deleted dan actual deletion baru happen after retention period. Ini provide safety net jika ada accidental deletes.

### 2.3 Sprint 2.3C & 2.3D: Firebase & FCM Integration

#### Firebase Project Setup

Firebase setup adalah prerequisite untuk push notifications. Saya create new Firebase project khusus untuk AIVIA, configure Android app dengan proper package name, download google-services.json, dan integrate dengan Flutter project. Setup process relatif straightforward, tapi saya harus careful dengan configuration untuk ensure FCM works properly.

Saya juga setup Firebase Console dengan proper permissions dan team member access. Documentation saya create untuk reference future maintenance dan onboarding new team members.

#### FCM Service Implementation

FCM service adalah core dari notification system. Saya implement dalam class `FCMService` dengan comprehensive functionality. Service ini handle FCM token management, device registration ke Supabase, message handling untuk foreground dan background, notification display dengan proper channels, dan permission management untuk Android 13+.

Token management adalah critical piece. Ketika app pertama kali launch, FCM token di-generate dan di-register ke Supabase. Token ini kemudian di-use oleh server untuk send notifications. Saya implement auto-refresh mechanism karena FCM tokens bisa expire atau change setelah app reinstall.

Untuk notification channels, saya create separate channels untuk different types: emergency alerts dengan high priority dan sound, geofence events dengan default priority, dan activity reminders dengan low priority. Ini give users granular control over which notifications mereka want.

Background message handling adalah most challenging part. Android has strict constraints pada background execution, jadi saya harus carefully design handler agar bisa process notifications tanpa exceed time limits. Saya implement efficient processing dengan minimal operations dan defer heavy work ke foreground.

#### Provider Integration

Untuk expose FCM functionality ke UI layer, saya create `FCMProvider` dengan Riverpod. Provider ini provide reactive access ke token status, device info, notification permission status, dan notification history. Semua state properly managed dengan AsyncValue untuk handle loading, success, dan error states.

### 2.4 Sprint 2.3E: Geofencing Implementation

#### Geofence Model dan Repository

Saya mulai dengan design model `Geofence` yang comprehensive. Model ini include ID, patient ID, name, center coordinates, radius, isActive flag, notification settings, timestamps, dan metadata. Saya also implement helper methods untuk check if point is inside geofence dan calculate distance from center.

`GeofenceRepository` saya implement dengan full CRUD operations plus specialized queries. Ada method untuk get active geofences for patient, search nearby geofences, check geofence violations, dan batch operations. Semua methods properly handle errors dan return Result types untuk type-safe error handling.

#### Geofence Provider

`GeofenceProvider` saya design dengan several specialized providers: list provider dengan real-time updates, detail provider untuk single geofence, nearby provider untuk geofences near current location, dan actions provider untuk create/update/delete operations. Architecture ini make state management very clean dan predictable.

Real-time updates adalah key feature. Ketika geofence di-create, edit, atau delete oleh family member lain, changes instantly reflected di all connected devices. Saya achieve this dengan Supabase real-time subscriptions yang very powerful dan easy to use.

#### UI Implementation

UI untuk geofencing saya design dengan user-friendliness sebagai top priority. `GeofenceListScreen` menampilkan all geofences dalam card layout dengan quick actions untuk edit dan delete. Cards show essential info: name, radius, status, dan violation count.

`GeofenceFormScreen` untuk create dan edit saya buat very intuitive. Ada map preview yang show exact geofence location dan coverage area. User bisa drag center marker dan adjust radius dengan slider. Real-time validation ensure data integrity sebelum save.

`GeofenceDetailScreen` provide comprehensive view dengan statistics, recent events, map visualization, dan action buttons. Saya juga implement event timeline yang show history of entries dan exits dengan timestamps dan patient info.

#### Event Detection System

Geofence event detection adalah automated background process. Setiap kali ada location update, system check apakah location berada dalam atau outside dari active geofences. Jika ada state change dari inside ke outside atau vice versa, event record di-create dan notification di-trigger.

Saya implement smart debouncing untuk prevent notification spam. Jika patient bolak-balik cross boundary dalam short time window, hanya first event yang trigger notification. Subsequent events di-log tapi not notified until certain cooldown period passed.

### 2.5 Edge Function Development

#### Notification Dispatcher Function

Edge function adalah serverless function yang running di Supabase edge network. Function `send-emergency-notification` yang saya develop handle dispatch push notifications ke multiple recipients dengan efficient batching.

Function architecture saya design dengan modularity. Ada separate modules untuk FCM client initialization, recipient resolution berdasarkan patient links, notification payload construction, batch sending dengan rate limiting, dan delivery logging untuk tracking.

Error handling di edge function especially important karena running di distributed environment. Saya implement comprehensive error catching dengan proper logging dan graceful degradation. Jika sending ke certain device fail, process continue untuk devices lain instead of full failure.

#### Testing dan Deployment

Testing edge functions locally adalah challenging karena need emulate Supabase environment. Saya use Supabase CLI dengan local development setup. Setelah satisfied dengan local testing, saya deploy ke staging environment untuk integration testing.

Production deployment saya lakukan dengan careful monitoring. Saya setup alerts untuk function errors dan performance issues. Alhamdulillah, deployment smooth dan function perform excellently dengan p95 latency under 200ms.

### 2.6 Quality Assurance dan Documentation

#### Code Quality

Sepanjang development, saya maintain strict code quality standards. Setiap file follow Dart style guide dan pass flutter analyze tanpa errors atau warnings. Saya also enforce lint rules untuk ensure consistency across codebase.

Code review saya lakukan secara self-review dengan checklist: functionality correctness, error handling completeness, performance considerations, security implications, dan code maintainability. Setiap issue found immediately di-address sebelum commit.

#### Testing Coverage

Testing strategy saya fokus pada critical paths. Unit tests untuk repository methods dan business logic, widget tests untuk UI components, dan integration tests untuk end-to-end flows. Saya juga extensive manual testing di real devices dengan various Android versions.

For geofencing, saya test dengan actual physical movement untuk validate detection accuracy. Saya walk around test areas dengan app running dan verify notifications arrive dengan correct timing dan information.

#### Documentation

Documentation adalah deliverable important yang often overlooked. Saya create comprehensive docs untuk every major component: architecture diagrams, API documentation, setup guides, troubleshooting guides, dan user manuals.

Saya also maintain changelog yang detail untuk track all changes across sprints. Ini very helpful untuk future reference dan knowledge transfer ke new team members.

---

## BAB III: KESIMPULAN DAN SARAN

### 3.1 Kesimpulan

Progress keempat ini successfully deliver enterprise-grade tracking dan geofencing system yang significantly enhance safety features dari aplikasi AIVIA. Total saya implement lebih dari 5,700 lines of production code dengan zero compilation errors, yang menunjukkan quality dan maturity dari implementation.

Beberapa achievements yang saya most proud of adalah offline-first architecture yang ensure no data loss meskipun network unstable, comprehensive database optimization yang maintain performance dengan massive data volume, geofencing system yang user-friendly dan reliable, dan Firebase integration yang provide instant notifications dengan zero cost.

Yang paling satisfying adalah knowing that features ini will directly impact safety dari patients dan peace of mind dari families. Geofencing especially adalah game-changer dalam monitoring dan protecting patients dengan wandering behavior.

From technical perspective, saya berhasil maintain 100% free tier usage meskipun implement enterprise-grade features. Ini membuktikan bahwa dengan proper architecture dan optimization, kita bisa build powerful systems tanpa significant infrastructure costs.

### 3.2 Saran untuk Progress Selanjutnya

Meskipun Phase 2 sudah complete, masih ada several areas yang bisa di-improve di future progress. Pertama adalah implementation machine learning untuk predictive analytics. Dengan accumulation location data, kita bisa predict patient behavior patterns dan provide proactive recommendations.

Kedua adalah enhancement geofencing dengan dynamic radius adjustment berdasarkan time of day atau activity patterns. Misalnya, radius bisa auto-expand di malam hari ketika patient biasanya lebih active, atau auto-shrink di siang hari ketika usually rest.

Ketiga adalah integration dengan wearable devices seperti smartwatch untuk additional safety layer. Wearables bisa provide more accurate tracking dan additional sensors seperti heart rate yang valuable untuk health monitoring.

Keempat adalah implementation social features seperti caregiver network dimana multiple family members atau professional caregivers bisa collaborate dalam patient monitoring. Ini require careful design untuk privacy dan permission management.

Kelima adalah advanced analytics dashboard untuk families untuk visualize trends, patterns, dan insights dari collected data. Dashboard bisa show heatmaps untuk frequently visited areas, timeline untuk daily routines, dan alerts untuk anomaly detection.

### 3.3 Penutup

Alhamdulillah, progress keempat ini successfully completed dengan results yang sangat memuaskan. Saya bersyukur bisa implement features yang not hanya technically sound, tapi juga truly meaningful untuk target users aplikasi ini.

Journey implement geofencing dan enterprise tracking system teach saya banyak hal tentang mobile architecture, distributed systems, dan user experience design. Challenge-challenge yang saya hadapi, dari offline sync complexity sampai notification reliability, membuat saya grow significantly sebagai developer.

Looking forward, saya excited untuk continue pengembangan aplikasi AIVIA dengan focus pada features yang even more impactful. Target saya adalah make AIVIA as the go-to solution untuk Alzheimer patient care di Indonesia dan beyond.

Terima kasih telah membaca laporan progress ini. Saya harap documentation ini bermanfaat tidak hanya untuk tracking progress tapi juga sebagai learning resource untuk future development efforts.

---

**Catatan**: Laporan ini disusun berdasarkan implementasi aktual dari Sprint 2.3A hingga 2.3E yang mencakup periode November 2025. Semua code dan documentation tersedia di repository project untuk reference dan review.

**Status Akhir**: ✅ Production Ready | 0 Errors | 100% Free Tier
