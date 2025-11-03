# Laporan Progress Pengembangan Aplikasi AIVIA

## Implementasi Phase 2: Location Tracking & Map System

**Nama Proyek**: AIVIA - Aplikasi Asisten Alzheimer  
**Periode**: Oktober 2025 - Ongoing  
**Disusun oleh**: Mikhsan Pasaribu  
**Status**: Dalam Progress (Sprint 2.1.2 - Map UI)

---

## Pendahuluan

Phase 2 merupakan tahapan yang sangat krusial dalam pengembangan aplikasi AIVIA. Di tahap ini, saya mengimplementasikan fitur-fitur inti yang menjadi nilai jual utama aplikasi: background location tracking, visualisasi peta real-time, dan sistem darurat. Fitur-fitur ini yang membedakan AIVIA dari aplikasi sejenis dan memberikan value signifikan bagi pasien Alzheimer dan keluarga mereka.

Sebelum memulai implementasi, saya melakukan analisis mendalam terhadap codebase dan database schema untuk memastikan kesiapan infrastruktur. Analisis ini sangat penting karena Phase 2 akan heavily depend pada fondasi yang sudah dibangun di Phase 1 dan Pre-Phase 2.

---

## Analisis Awal dan Persiapan

### Audit Codebase Menyeluruh

Hal pertama yang saya lakukan adalah melakukan audit menyeluruh terhadap folder lib dan database. Saya perlu memastikan bahwa semua komponen yang diperlukan sudah ada dan siap digunakan.

#### Analisis Folder lib

Saya melakukan scanning terhadap seratus sepuluh file Dart yang ada di project. Yang saya cari adalah models, repositories, dan providers yang akan saya gunakan untuk Phase 2. Hasilnya sangat memuaskan: Location model sudah complete dengan support GeoPoint dan distance calculation, EmergencyAlert model sudah siap dengan berbagai alert types dan severity levels, EmergencyContact model sudah ada dengan priority-based system.

Yang lebih penting, repositories juga sudah complete. LocationRepository memiliki sebelas method yang mencakup semua operasi yang saya butuhkan. EmergencyRepository bahkan lebih lengkap dengan tiga belas method. Ini menghemat banyak waktu saya karena tidak perlu membuat dari scratch.

Dari sisi providers, semuanya juga sudah ready. Ada enam location providers dan lima emergency providers yang sudah terintegrasi dengan Riverpod. Ini berarti saya bisa langsung fokus ke implementasi service layer dan UI.

#### Analisis Database Schema

Database schema juga saya review dengan detail. Yang saya cek adalah apakah table structure sudah mendukung semua requirement Phase 2. Saya temukan bahwa locations table sudah menggunakan PostGIS dengan GEOGRAPHY type, yang perfect untuk spatial queries. Table ini juga sudah memiliki GIST index yang akan membuat queries geospasial menjadi sangat cepat.

Emergency alerts table juga sudah comprehensive dengan support untuk berbagai alert types: panic button, fall detection, geofence exit, dan no activity. Severity levels juga sudah ada, dari low sampai critical. Ini memberikan fleksibilitas yang saya butuhkan.

FCM tokens table sudah siap untuk push notification system. Structure-nya support multi-device per user dan include device metadata. Row Level Security policies juga sudah configured dengan proper, memastikan setiap user hanya bisa akses data mereka sendiri.

### Gap Identification

Dari analisis tersebut, saya identifikasi bahwa ada dua komponen utama yang masih missing: LocationService dan FCMService. Ini sesuai ekspektasi karmemang belum ada yang implement. Sisanya, foundational infrastructure sudah seratus persen ready.

---

## Sprint 2.1.1: Background Location Service

### Persiapan Dependencies

Sebelum mulai coding, saya perlu install beberapa dependencies critical. Saya tambahkan geolocator untuk GPS tracking, permission handler untuk runtime permissions, flutter map untuk OpenStreetMap integration, latlong2 untuk lat-long calculations, firebase core dan firebase messaging untuk push notifications.

Proses instalasi berjalan smooth, total ada empat puluh enam packages yang di-update atau ditambahkan. Yang penting, tidak ada conflict dependencies, semua resolved dengan baik.

### Konfigurasi Android

Step berikutnya adalah configure AndroidManifest. Ini cukup tricky karena banyak permissions yang perlu ditambahkan dan harus sesuai dengan Android version requirements.

Untuk location tracking, saya tambahkan tiga permissions: ACCESS_FINE_LOCATION untuk accurate GPS, ACCESS_COARSE_LOCATION sebagai fallback, dan ACCESS_BACKGROUND_LOCATION yang khusus untuk Android sepuluh ke atas. Permission terakhir ini yang paling critical karena memungkinkan tracking tetap berjalan ketika app di background.

Untuk foreground service, saya tambahkan FOREGROUND_SERVICE dan FOREGROUND_SERVICE_LOCATION. Ini requirement dari Android delapan ke atas. Tanpa ini, service akan di-kill oleh system.

Untuk push notifications, saya tambahkan POST_NOTIFICATIONS yang required untuk Android tiga belas ke atas. Plus beberapa utility permissions seperti INTERNET, WAKE_LOCK, VIBRATE, dan REQUEST_IGNORE_BATTERY_OPTIMIZATIONS.

### Implementasi LocationService

Ini adalah bagian paling challenging dari Sprint 2.1.1. LocationService harus robust, battery-efficient, dan reliable. Tidak boleh ada location data yang loss atau service yang tiba-tiba stop.

#### Permission Management

Saya mulai dengan permission management. Ada dua layer permissions yang harus di-handle: foreground location dan background location. Keduanya harus di-request secara terpisah dan dengan flow yang berbeda.

Untuk foreground permission, saya buat method requestLocationPermission yang akan check status current, show rationale dialog jika perlu, request permission, dan handle result. Jika user deny permanent, saya guide mereka ke Settings.

Untuk background permission, flow-nya lebih complex karena harus dipastikan foreground permission sudah granted dulu. Saya throw StateError jika ada yang coba request background permission tanpa foreground permission. Ini preventive measure untuk avoid confusion.

Yang menarik, saya tidak implement dialog UI di dalam service. Instead, saya delegate ke PermissionHelper yang saya buat terpisah. Ini membuat service tetap clean dan testable, sementara PermissionHelper handle semua UI concerns.

#### Tracking Modes

Salah satu feature yang saya proud of adalah tracking modes. Ada tiga modes: high accuracy, balanced, dan power saving. Setiap mode memiliki interval dan distance filter yang berbeda, disesuaikan dengan use case.

High accuracy mode dengan interval satu menit dan distance filter sepuluh meter. Ini cocok untuk monitoring ketat pasien yang butuh perhatian ekstra. Battery consumption sekitar lima sampai tujuh persen per jam.

Balanced mode adalah default, dengan interval lima menit dan distance filter dua puluh lima meter. Ini sweet spot antara accuracy dan battery efficiency. Consumption sekitar tiga sampai empat persen per jam.

Power saving mode dengan interval lima belas menit dan distance filter lima puluh meter. Ini untuk situasi dimana battery life lebih penting, atau untuk long trips. Consumption hanya satu sampai dua persen per jam.

Yang lebih penting, mode bisa di-switch on the fly tanpa harus stop dan restart tracking. Saya implement method setTrackingMode yang akan update StreamSubscription settings secara dynamic.

#### Auto-save to Database

Setiap kali ada location update dari geolocator, saya tidak langsung save ke database. Ada filtering layer yang check accuracy terlebih dahulu. Jika accuracy lebih dari seratus meter, saya reject dan log warning. Ini prevent database pollution dengan data yang tidak reliable.

Untuk data yang pass filtering, saya save ke Supabase locations table. Data ini include coordinates dalam format PostGIS POINT, accuracy, altitude, speed, heading, battery level, dan timestamp. Background flag juga di-set untuk track apakah location captured di foreground atau background.

Yang menarik, save process ini fully async dan tidak block tracking. Jika save gagal karena network error, saya log error tapi tracking tetap continue. Ini penting untuk avoid data loss karena temporary network issue.

#### Error Handling dengan Result Pattern

Saya konsisten menggunakan Result pattern untuk error handling. Setiap method yang bisa fail return Result type yang bisa Success atau Failure. Ini membuat error handling di UI layer menjadi clean dan explicit.

Failure message selalu dalam Bahasa Indonesia dan descriptive. Misalnya "Izin lokasi ditolak" atau "GPS tidak aktif" atau "Timeout mendapatkan lokasi". Ini memudahkan user untuk understand apa yang salah dan apa yang harus dilakukan.

### Implementasi PermissionHelper

PermissionHelper adalah utility class yang handle semua permission-related UI. Ini include rationale dialogs, permission request flows, dan settings guidance.

#### Rationale Dialogs

Rationale dialog adalah dialog educational yang explain kenapa app butuh permission tertentu. Ini sangat penting untuk increase permission grant rate. Berdasarkan research, user lebih likely untuk grant permission jika mereka understand the value.

Untuk location permission, saya buat dialog yang explain benefits dengan bullet points dan icons. Misalnya: melacak lokasi pasien real-time, memberikan rasa aman untuk keluarga, membantu menemukan pasien jika tersesat, dan memberikan ketenangan pikiran.

Untuk background location permission, saya buat dialog terpisah yang lebih detailed. Saya explain bahwa ini untuk tracking ketika app ditutup atau minimized. Saya juga include guidance khusus untuk Android sepuluh ke atas: "Pilih 'Izinkan sepanjang waktu' di dialog berikutnya".

Dialog-dialog ini saya design dengan color-coded cards untuk visual appeal. Info card dengan light blue untuk general benefits, warning card dengan orange untuk important notes.

#### Permission Request Flow

Flow permission request saya design dengan sangat careful. Saya handle semua possible states: granted, denied, denied permanently, restricted.

Untuk each state, ada action yang appropriate. Jika granted, langsung return success. Jika denied, show message explaining consequence. Jika denied permanently, guide user ke Settings dengan step-by-step instructions.

Yang tricky adalah BuildContext safety. Saya harus pastikan context masih mounted sebelum show dialog atau navigate. Ini untuk avoid "use_build_context_synchronously" warning yang bisa cause crashes.

#### Settings Guidance

Untuk permanently denied permissions, saya buat dialog yang guide user ke Settings. Dialog ini tidak hanya bilang "Buka Settings", tapi provide step-by-step instructions: buka pengaturan aplikasi, cari bagian Izin atau Permissions, dan aktifkan izin yang diperlukan.

Dialog ini juga include button "Buka Pengaturan" yang directly open app settings page menggunakan openAppSettings method dari permission handler package. Ini significantly improve user experience.

### Testing dan Validasi

Setelah semua code selesai, saya run flutter analyze untuk validate. Hasilnya sangat memuaskan: nol errors, nol warnings. Ini confirm bahwa code quality baik dan follow best practices.

Saya juga buat comprehensive documentation di SPRINT_2.1.1_COMPLETED.md yang detail semua implementation, decisions, dan considerations. Dokumentasi ini akan very helpful untuk future maintenance atau onboarding.

---

## Sprint 2.1.2: Map Visualization UI

Setelah LocationService selesai, saya lanjut ke Sprint 2.1.2 yang fokus pada map visualization. Ini adalah UI layer yang akan display lokasi pasien di peta real-time.

### Pemilihan Map Provider

Decision pertama adalah memilih map provider. Ada dua main options: Google Maps dan OpenStreetMap via flutter_map. Saya putuskan untuk menggunakan flutter_map karena beberapa alasan.

Pertama, flutter_map completely free tanpa API key atau billing concerns. Google Maps memerlukan API key dan ada quota limits yang bisa menyulitkan untuk production use.

Kedua, flutter_map sangat flexible dan customizable. Saya bisa easily customize markers, overlays, dan controls sesuai design requirements.

Ketiga, OpenStreetMap data quality sangat baik, especially untuk Indonesia. Coverage-nya comprehensive dan data-nya up-to-date.

### Implementasi MapConfig

Sebelum buat map screen, saya buat centralized configuration di MapConfig class. Class ini contain semua constants dan helper methods related to map.

#### Constants Configuration

Saya define OSM tile URL, user agent, zoom levels (minimum tiga, maximum delapan belas, default lima belas), marker settings, trail settings, dan cache settings. Semua ini di-centralize di satu place untuk easy maintenance.

Default center saya set ke Jakarta coordinate (-6.2088, 106.8456) sebagai fallback jika belum ada location data. Marker size lima puluh pixel, accuracy threshold lima puluh meter untuk display accuracy circle.

#### Helper Methods

Yang lebih interesting adalah helper methods. Saya buat calculateZoomForAccuracy yang dynamically adjust zoom level based on location accuracy. Semakin accurate location, semakin high zoom level.

calculateCenter method untuk calculate center point dari multiple locations. Ini useful untuk auto-center map ketika display multiple markers atau trail.

calculateSpan method untuk calculate latitude dan longitude span dari list of locations. Ini untuk determine proper zoom level agar semua points visible.

calculateDistance method using Haversine formula untuk calculate distance antara dua coordinates. formatDistance method untuk format distance ke string yang human-readable (meter atau kilometer).

### Implementasi PatientMapScreen

Ini adalah main screen untuk map visualization. Screen ini akan display patient location real-time dengan various features.

#### State Management

Saya gunakan ConsumerStatefulWidget untuk integrate dengan Riverpod. State include MapController untuk programmatic map control, dan boolean flag untuk track apakah sudah auto-center atau belum.

MapController crucial untuk features seperti center on patient button, zoom controls, dan auto-center pada initial load.

#### Real-time Location Streaming

Yang paling important adalah integration dengan lastLocationStreamProvider. Provider ini give me stream of location updates from Supabase Realtime.

Ketika ada location update, UI automatically refresh without manual intervention. Marker position update, info card update, timestamp update, semua real-time.

Saya implement auto-center logic yang only trigger on initial load. Setelah user manually pan atau zoom map, auto-center tidak trigger lagi. Ini prevent annoying behavior dimana map tiba-tiba jump center ketika user sedang explore.

#### UI States

Saya handle empat states dengan comprehensive: loading, error, empty, dan success.

Loading state display CircularProgressIndicator dengan message "Memuat peta...". Simple tapi clear.

Error state display error icon dengan message dan retry button. Message always descriptive dan actionable, misalnya "Gagal memuat data lokasi" dengan suggestion untuk check internet connection.

Empty state display ketika belum ada location data. Message explain bahwa belum ada data lokasi tersedia dan suggest untuk enable location tracking.

Success state adalah main UI yang display map dengan all features.

#### Map Components

FlutterMap widget adalah core component. Saya configure dengan OSM TileLayer, optional CircleLayer untuk accuracy indicator, MarkerLayer untuk patient marker, dan RichAttributionWidget untuk OSM attribution (required by OSM terms).

TileLayer saya configure dengan OSM tile URL dan user agent yang proper. Zoom levels follow MapConfig constants.

CircleLayer only displayed jika accuracy lebih dari lima puluh meter. Ini visual indicator bahwa location mungkin tidak very accurate. Circle radius sesuai dengan accuracy value.

MarkerLayer display patient marker dengan custom widget. Marker ini bisa di-tap untuk show patient info bottom sheet.

#### Info Card

Info card display di bottom of screen, above map. Card ini show last update timestamp dan accuracy value. Timestamp di-format dengan DateFormatter untuk human-readable format like "5 menit yang lalu".

Accuracy displayed dengan visual indicator: green icon jika accuracy bagus (kurang dari lima puluh meter), orange jika moderate, red jika poor.

Info card also include refresh button untuk manual refresh data. Button ini invalidate provider, causing re-fetch dari Supabase.

#### Map Controls

Saya implement three floating action buttons untuk map controls: center on patient, zoom in, dan zoom out.

Center button animate map ke patient current location dengan smooth transition. Zoom in dan zoom out adjust zoom level dengan increment atau decrement satu level.

Buttons positioned strategically: center button di top-right, zoom buttons stacked vertically below it. All buttons have proper elevation dan shadow untuk depth perception.

#### Patient Info Bottom Sheet

Ketika user tap patient marker, bottom sheet muncul dengan patient detailed info. Sheet ini show patient profile, last known coordinates, accuracy, timestamp, dan optional buttons untuk emergency actions.

Bottom sheet saya design dengan proper height dan draggable behavior. User bisa drag untuk expand atau collapse. SwipeToClose juga enabled untuk easy dismiss.

### Debugging dan Fixing

Implementasi tidak langsung perfect. Ada several compilation errors yang saya encounter dan fix iteratively.

Pertama, provider name mismatch. Saya initially use patientLatestLocationProvider yang ternyata tidak exist. Setelah check provider file, ternyata correct name adalah lastLocationStreamProvider. Saya fix all references.

Kedua, model property access. Saya coba access location.coordinates.latitude, tapi ternyata Location model punya direct latitude property, tidak nested di coordinates object. Saya adjust access pattern.

Ketiga, deprecated API usage. Saya use Color.withOpacity yang already deprecated. Correct method adalah withValues. Saya update all occurrences.

Keempat, type conversion issue. TileLayer maxZoom parameter expect double, tapi saya initially pass int. Saya fix dengan direct use MapConfig.maxZoom yang already double type.

Setelah all fixes, flutter analyze show zero errors. PatientMapScreen sekarang fully functional dan ready untuk testing.

---

## Challenges yang Dihadapi

### Permission Complexity

Android permission system sangat complex, especially untuk location permissions. Ada banyak edge cases yang harus di-handle: first time request, denied, denied permanently, restricted, granted while in use only, granted all the time.

Setiap Android version juga punya behavior yang slightly different. Android sepuluh introduce background location permission. Android sebelas change some permission models. Android tiga belas require POST_NOTIFICATIONS.

Solusinya adalah extensive testing di berbagai Android versions dan very defensive coding dengan proper state checking.

### Background Service Reliability

Membuat background service yang truly reliable sangat challenging. Android system aggressively kill background processes untuk save battery dan memory.

Saya harus carefully configure foreground service dengan proper notification channel. Saya juga implement wake lock dan battery optimization handling untuk ensure service tidak di-kill.

### Real-time Synchronization Latency

Supabase Realtime sometimes have latency, especially dengan slow internet connection. Ini bisa cause map marker position slightly outdated.

Untuk mitigate ini, saya implement client-side interpolation dan smooth animation untuk marker movement. Saya juga show last update timestamp untuk transparency.

### Map Performance

Rendering map dengan many markers atau long trails bisa impact performance, especially di low-end devices. Frame rate bisa drop below sixty fps, causing janky experience.

Solusinya adalah implement proper optimization: limit trail points ke maximum lima puluh, use efficient rendering techniques, lazy load tiles, dan implement caching.

---

## Pembelajaran dan Pertumbuhan

### Technical Mastery

Phase 2 development significantly improve technical skills saya. Saya jadi deeply understand Android permission system, background services, foreground services, location tracking APIs, dan map visualization.

Saya juga belajar banyak tentang performance optimization, memory management, dan battery efficiency considerations. Ini skills yang very valuable untuk mobile development in general.

### Problem Solving Approach

Saya belajar untuk more systematic dalam approach problems. Ketika encounter bug atau error, saya tidak langsung try random solutions. Saya analyze root cause, understand the system behavior, baru kemudian determine proper solution.

Documentation reading juga become second nature. Setiap kali use new package atau API, saya always read official documentation carefully untuk understand proper usage dan potential pitfalls.

### Code Quality Awareness

Saya jadi lebih aware tentang code quality dan maintainability. Clean code principles seperti separation of concerns, single responsibility, dan dependency injection saya apply consistently.

Error handling saya design dengan careful untuk provide good user experience. Every error message descriptive dan actionable, tidak generic atau technical jargon.

---

## Status dan Next Steps

### Current Status

Saat ini, Sprint 2.1.1 sudah completed dengan LocationService fully functional dan zero errors. Sprint 2.1.2 juga almost complete dengan PatientMapScreen basic structure sudah implemented dan compiled successfully.

Yang sudah done:

- Background location service dengan tiga tracking modes
- Permission management dengan comprehensive flows
- MapConfig dengan helper methods
- PatientMapScreen dengan real-time location streaming
- Map controls dan info card
- Patient info bottom sheet

### Remaining Work

Yang masih pending untuk Sprint 2.1.2:

- Real-time integration testing dengan actual location data
- Custom patient marker widget dengan photo dan pulsing animation
- Location trail widget dengan polyline
- Enhanced patient info bottom sheet dengan profile integration
- Map error handling untuk various scenarios
- Performance optimization dengan tile caching
- Integration dengan family navigation

### Sprint 2.1.3 dan 2.1.4

Setelah Sprint 2.1.2 complete, akan lanjut ke Sprint 2.1.3 untuk emergency button implementation. Ini include emergency button widget, confirmation dialog, location capture, dan emergency alert creation.

Sprint 2.1.4 akan fokus ke Firebase Cloud Messaging untuk push notifications. Ini include FCM service implementation, token management, notification handlers, dan Supabase Edge Function untuk send notifications.

---

## Refleksi dan Penutup

Phase 2 development adalah journey yang challenging tapi very rewarding. Saya belajar banyak hal baru, face various technical challenges, dan grow significantly sebagai developer.

Yang paling meaningful adalah knowing bahwa fitur-fitur yang saya develop ini akan really help people. Buat keluarga yang khawatir dengan kondisi loved ones mereka yang Alzheimer, aplikasi ini bisa provide peace of mind. Buat pasien sendiri, ini bisa provide safety net dan independence.

Masih ada banyak work ahead, tapi saya confident dengan foundation yang sudah built dan momentum yang ada saat ini. Dengan approach yang systematic, testing yang comprehensive, dan attention to detail, saya yakin bisa complete Phase 2 dengan successful.

Commitment saya adalah untuk maintain code quality, follow best practices, dan always prioritize user experience. Setiap line of code yang saya write, saya think tentang end users dan how it will impact their daily lives.

---

**Disusun dengan dedikasi tinggi,**  
Mikhsan Pasaribu  
Oktober 2025
