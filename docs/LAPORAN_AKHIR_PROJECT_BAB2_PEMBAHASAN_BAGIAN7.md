# BAB II: PEMBAHASAN FITUR YANG DIKEMBANGKAN

## Bagian 7: Dashboard Statistik dan Fitur Pendukung

# 2.23 Dashboard Statistik untuk Keluarga

Dashboard merupakan pusat informasi bagi keluarga yang memberikan overview komprehensif tentang kondisi dan aktivitas pasien. Implementasi dashboard dirancang untuk menyajikan informasi yang kompleks dalam format yang mudah dipahami dengan visualisasi yang menarik.

Statistik aktivitas menjadi bagian utama dari dashboard. Keluarga dapat melihat berapa banyak aktivitas yang dijadwalkan untuk hari ini, minggu ini, dan bulan ini. Untuk setiap periode, ditampilkan breakdown berapa aktivitas yang sudah selesai, berapa yang masih pending, dan berapa yang terlambat atau terlewat. Informasi ini disajikan dalam kartu-kartu yang berwarna dengan ikon yang representatif untuk memudahkan scanning visual.

Grafik penyelesaian aktivitas menampilkan trend performa pasien dari waktu ke waktu. Saya menggunakan line chart untuk menampilkan persentase penyelesaian aktivitas harian selama seminggu atau sebulan terakhir. Chart ini membantu keluarga mengidentifikasi pola seperti hari-hari dimana pasien cenderung lebih produktif atau kurang konsisten. Warna dan marker digunakan untuk highlight hari dengan performa sangat baik atau yang memerlukan perhatian.

Statistik lokasi memberikan insight tentang pergerakan dan kebiasaan pasien. Dashboard menampilkan berapa lama pasien berada di rumah versus di luar dalam periode tertentu, lokasi yang paling sering dikunjungi dengan durasi rata-rata, jumlah kali pasien keluar dari safe zone, dan total jarak yang ditempuh. Informasi ini membantu keluarga memahami pola aktivitas dan mengidentifikasi perubahan yang mungkin memerlukan perhatian.

Metrik pengenalan wajah juga ditampilkan di dashboard. Keluarga dapat melihat berapa kali pasien menggunakan fitur pengenalan wajah, tingkat keberhasilan pengenalan, orang-orang yang paling sering dikenali, dan trend penggunaan dari waktu ke waktu. Data ini memberikan gambaran tentang seberapa membantu fitur ini bagi pasien dan mungkin mengindikasikan progression atau improvement kondisi mereka.

Alert summary menampilkan ringkasan semua alert dan notifikasi penting. Ini mencakup alert darurat yang triggered, notifikasi geofence yang diterima, dan pengingat aktivitas yang terlewat. Setiap kategori alert memiliki counter dan dapat diklik untuk melihat detail lebih lanjut. Ini membantu keluarga tetap aware tentang situasi yang memerlukan perhatian.

Widget quick actions menyediakan akses cepat ke fitur-fitur yang sering digunakan. Dari dashboard, keluarga dapat langsung menambah aktivitas baru, melihat lokasi pasien di peta, membuka chat dengan pasien, atau mengakses pengaturan geofence. Quick actions ini mengurangi jumlah tap yang diperlukan untuk tugas common, meningkatkan efisiensi penggunaan aplikasi.

Untuk memberikan konteks historis, dashboard juga menampilkan comparison dengan periode sebelumnya. Misalnya statistik minggu ini dibandingkan dengan minggu lalu, dengan indikator trend naik atau turun. Ini membantu keluarga melihat apakah ada improvement atau degradation dalam kondisi dan kebiasaan pasien.

Semua data statistik di dashboard di-cache untuk performa optimal. Data dihitung di backend dan di-update secara periodic, sehingga loading dashboard sangat cepat. Cache invalidation dilakukan secara cerdas ketika ada perubahan data yang signifikan, memastikan informasi yang ditampilkan selalu akurat tanpa overhead query yang berlebihan.

## 2.24 Sistem Pengaturan dan Personalisasi

Aplikasi menyediakan sistem pengaturan yang comprehensive untuk memungkinkan personalisasi sesuai kebutuhan dan preferensi masing-masing pengguna. Pengaturan diorganisir dalam kategori yang logis untuk memudahkan navigasi.

Kategori appearance mencakup pengaturan visual aplikasi. Pengguna dapat memilih tema antara terang, gelap, atau otomatis mengikuti sistem. Mereka juga dapat menyesuaikan ukuran font dengan pilihan kecil, normal, besar, atau sangat besar. Pengaturan ini sangat penting terutama untuk pasien dengan gangguan penglihatan. Preferensi bahasa juga berada di kategori ini dengan pilihan yang jelas antara bahasa yang didukung.

Kategori notifications memberikan kontrol granular atas berbagai jenis notifikasi. Pengguna dapat enable atau disable notifikasi untuk setiap kategori seperti pengingat aktivitas, alert darurat, event geofence, pesan chat, dan update sistem. Untuk setiap kategori yang enabled, mereka dapat mengatur apakah notifikasi muncul di lock screen, menggunakan suara, atau dengan getaran. Pengaturan ini menggunakan native notification channels sehingga terintegrasi dengan pengaturan sistem.

Kategori privacy and security mencakup pengaturan yang berkaitan dengan keamanan dan privasi data. Pasien dapat mengatur izin akses untuk setiap keluarga yang terhubung, termasuk siapa yang dapat melihat lokasi mereka, siapa yang dapat mengedit aktivitas, dan siapa yang menerima alert darurat. Ada juga opsi untuk mengeksport semua data pribadi untuk compliance dengan regulasi privasi.

Kategori location services memungkinkan konfigurasi pelacakan lokasi. Pengguna dapat mengatur frekuensi update lokasi dengan pilihan real-time, setiap lima menit, atau setiap lima belas menit. Mereka juga dapat set akurasi GPS dengan trade-off antara akurasi dan konsumsi baterai. Ada opsi untuk pause pelacakan lokasi sementara ketika tidak diperlukan.

Kategori data and storage menyediakan informasi tentang penggunaan storage dan opsi untuk mengelola data. Pengguna dapat melihat berapa banyak storage yang digunakan oleh berbagai jenis data seperti foto aktivitas, foto wajah, dan database lokal. Ada opsi untuk clear cache, menghapus data lama, atau reset aplikasi ke kondisi awal dengan tetap menjaga data penting.

Untuk keamanan, ada kategori account yang memungkinkan pengguna mengganti password, update email, atau menghapus akun mereka. Operasi sensitif ini memerlukan konfirmasi dengan memasukkan password saat ini untuk mencegah perubahan tidak sah. Penghapusan akun menampilkan warning yang jelas tentang konsekuensi dan memerlukan konfirmasi multiple untuk menghindari penghapusan tidak sengaja.

Semua pengaturan disimpan dengan aman dan disinkronkan ke cloud ketika memungkinkan. Ini memungkinkan pengguna untuk mempertahankan preferensi mereka ketika login dari perangkat berbeda. Untuk pengaturan yang sifatnya lokal seperti cache size, nilai disimpan di local storage perangkat.

## 2.25 Fitur Help dan Onboarding

Untuk membantu pengguna baru memahami aplikasi, saya mengimplementasikan sistem onboarding yang comprehensive dan fitur help yang mudah diakses kapan saja.

Onboarding screen ditampilkan ketika pengguna pertama kali membuka aplikasi setelah registrasi. Ini terdiri dari beberapa layar yang menjelaskan fitur-fitur utama aplikasi dengan visual yang menarik dan teks yang ringkas. Setiap screen fokus pada satu fitur atau konsep, menghindari information overload. Pengguna dapat swipe untuk maju ke screen berikutnya atau skip onboarding jika mereka ingin langsung explore aplikasi.

Untuk pasien, onboarding di-customize untuk menjelaskan dengan sangat sederhana bagaimana menggunakan aplikasi. Focus pada fitur yang akan mereka gunakan yaitu melihat aktivitas, mengenali wajah, dan tombol darurat. Bahasa yang digunakan sangat simple dan visual yang besar membuat informasi mudah dicerna. Ada opsi untuk replay onboarding kapan saja melalui menu help.

Untuk keluarga, onboarding mencakup lebih banyak detail tentang cara mengelola pasien, membuat aktivitas, setting geofence, dan menggunakan dashboard. Tutorial interaktif memandu mereka melalui langkah-langkah untuk setup awal seperti menghubungkan dengan akun pasien dan membuat aktivitas pertama. Ini membantu mereka quickly productive dengan aplikasi.

Layar help yang accessible dari menu utama menyediakan berbagai resource bantuan. Ada FAQ yang menjawab pertanyaan umum tentang penggunaan fitur, troubleshooting untuk masalah common, kontak support untuk bantuan lebih lanjut, dan changelog yang menampilkan apa yang baru di versi terkini. Semua konten help tersedia dalam bahasa yang dipilih pengguna.

Contextual help juga tersedia di berbagai tempat di aplikasi. Icon help kecil ditampilkan di samping fitur atau setting yang mungkin membingungkan. Ketika di-tap, popup atau bottom sheet muncul menjelaskan fitur tersebut dengan detail. Ini memungkinkan pengguna mendapat bantuan tepat ketika mereka membutuhkannya tanpa harus mencari di documentation.

Tooltip dan hints ditampilkan untuk first-time user di berbagai layar. Misalnya ketika pertama kali membuka peta, tooltip menjelaskan bagaimana zoom dan pan. Ketika pertama kali membuat geofence, hint menjelaskan bagaimana adjust radius dengan slider. Tooltip ini automatically dismissed setelah ditampilkan beberapa kali, menghindari annoyance untuk experienced users.

Video tutorials embedded di layar help untuk fitur kompleks seperti setting geofence atau menambahkan orang dikenal untuk pengenalan wajah. Video memberikan demonstrasi visual step-by-step yang lebih mudah diikuti daripada instruksi tertulis. Video dapat di-play dalam aplikasi tanpa perlu membuka browser external.

Feedback mechanism memungkinkan pengguna melaporkan bug atau mengajukan feature request langsung dari aplikasi. Form feedback mencakup field untuk deskripsi issue, kategori seperti bug atau feature request, dan opsi untuk attach screenshot. Feedback dikirim ke sistem tracking dimana tim development dapat review dan respond. Pengguna menerima konfirmasi bahwa feedback mereka diterima dan dapat track status through aplikasi.

## 2.26 Testing dan Quality Assurance

Sepanjang development, saya melakukan berbagai testing untuk memastikan kualitas aplikasi. Testing approach mencakup multiple layers dari unit test hingga user acceptance testing.

Unit testing dilakukan untuk business logic yang kritis seperti calculation untuk geofence containment, formatting untuk date dan time, validation untuk input forms, dan parsing untuk data dari API. Test coverage untuk layer business logic mencapai lebih dari delapan puluh persen, memberikan confidence bahwa logic bekerja dengan benar dalam berbagai scenarios.

Widget testing dilakukan untuk komponen UI yang reusable seperti custom buttons, input fields, cards, dan dialogs. Test memastikan widget render dengan benar, respond terhadap user interaction, dan handle error state dengan proper. Snapshot testing digunakan untuk detect unintended visual changes.

Integration testing dengan Patrol memungkinkan testing end-to-end flows seperti user registration dan login, membuat dan menyelesaikan aktivitas, triggering dan handling emergency alert, dan setting geofence dan receiving notification. Test ini berjalan di real device atau emulator, memberikan confidence bahwa fitur bekerja dalam environment actual.

Manual testing dilakukan secara extensive di berbagai devices dengan Android versions berbeda. Testing mencakup happy path untuk semua fitur utama, edge cases seperti poor network atau low battery, error scenarios seperti invalid input atau API failure, dan stress testing dengan data volume tinggi. Bugs yang ditemukan didocument dan diprioritize untuk fix.

Accessibility testing memastikan aplikasi usable untuk users dengan disabilities. Testing dengan screen reader untuk verify proper semantics, testing dengan font size yang besar untuk verify layout tidak break, testing dengan high contrast mode untuk verify color tidak sole indicator, dan testing dengan touch exploration mode untuk verify all interactive elements accessible. Feedback dari testing ini digunakan untuk improve accessibility di seluruh aplikasi.

Performance profiling dilakukan untuk identify dan fix bottlenecks. Tools seperti Flutter DevTools digunakan untuk monitor frame rate, memory usage, network calls, dan CPU usage. Optimizations dilakukan seperti lazy loading untuk heavy widgets, efficient list rendering dengan builder pattern, image caching dan optimization, dan database query optimization. Hasil profiling menunjukkan aplikasi maintain sixty FPS di most scenarios dengan memory footprint yang reasonable.

Flutter analyze dijalankan secara regular untuk ensure code quality. Ini catch potential issues seperti unused variables, missing return types, improperly formatted code, dan violations terhadap linter rules. Analysis options dikonfigurasi dengan rules yang strict untuk maintain consistency dan best practices di codebase.
