# BAB II: PEMBAHASAN FITUR YANG DIKEMBANGKAN

## Bagian 3: Pelacakan Lokasi, Peta Interaktif, dan Sistem Darurat

# 2.8 Pelacakan Lokasi Latar Belakang

Salah satu fitur paling krusial dalam aplikasi AIVIA adalah kemampuan untuk melacak lokasi pasien secara real-time, bahkan ketika aplikasi tidak aktif digunakan. Fitur ini sangat penting mengingat pasien Alzheimer rentan mengalami wandering atau berjalan tanpa tujuan yang dapat membahayakan keselamatan mereka.

Implementasi pelacakan lokasi dimulai dengan integrasi layanan lokasi native Android melalui plugin Geolocator. Saya mengonfigurasi layanan ini untuk bekerja di latar belakang menggunakan Foreground Service, yang merupakan requirement Android untuk aplikasi yang perlu akses lokasi berkelanjutan. Foreground Service menampilkan notifikasi persisten yang menginformasikan pengguna bahwa pelacakan lokasi aktif, sesuai dengan kebijakan privasi Android.

Untuk akurasi maksimal, saya menggunakan GPS sebagai sumber lokasi utama dengan akurasi tinggi. Namun, sistem juga dapat fallback ke network location jika GPS tidak tersedia, misalnya ketika pasien berada di dalam ruangan. Sistem secara cerdas menyeimbangkan antara akurasi dan konsumsi baterai dengan menyesuaikan frekuensi update lokasi berdasarkan kecepatan pergerakan pasien.

Lokasi pasien diperbarui setiap lima belas meter pergerakan atau setiap tiga puluh detik jika pasien diam di satu tempat. Data lokasi yang dikumpulkan mencakup koordinat latitude dan longitude, akurasi dalam meter, timestamp yang tepat, kecepatan pergerakan, dan arah pergerakan jika tersedia. Semua informasi ini disimpan di database untuk analisis dan tracking.

Aspek izin menjadi perhatian khusus dalam implementasi ini. Aplikasi memerlukan beberapa izin lokasi yang berbeda tergantung pada versi Android. Untuk Android 10 ke atas, diperlukan izin khusus untuk akses lokasi latar belakang. Saya mengimplementasikan flow permintaan izin yang bertahap, dimana aplikasi pertama meminta izin lokasi saat aplikasi digunakan, kemudian setelah disetujui, meminta izin tambahan untuk akses latar belakang dengan penjelasan yang jelas mengapa ini penting.

Untuk mengoptimalkan baterai, saya juga mengintegrasikan Battery Optimization Exempt. Aplikasi memandu pengguna untuk mengecualikan AIVIA dari optimasi baterai Android agar pelacakan tidak dihentikan secara agresif oleh sistem. Ini dilakukan dengan dialog yang menjelaskan langkah-langkah yang perlu dilakukan pengguna di pengaturan sistem.

Saya mengimplementasikan mekanisme retry otomatis untuk menangani kasus ketika upload lokasi gagal karena koneksi internet terputus. Lokasi yang gagal diupload disimpan dalam antrian lokal menggunakan sqflite dan akan dicoba upload kembali ketika koneksi tersedia. Ini memastikan tidak ada data lokasi yang hilang bahkan dalam kondisi jaringan yang buruk.

## 2.9 Visualisasi Peta Interaktif

Data lokasi yang dikumpulkan ditampilkan kepada keluarga melalui visualisasi peta yang interaktif dan informatif. Saya menggunakan Flutter Map dengan tile dari OpenStreetMap untuk menampilkan peta, memberikan pengalaman yang smooth tanpa biaya API seperti Google Maps.

Peta menampilkan posisi real-time pasien dengan marker yang jelas dan mudah diidentifikasi. Marker menggunakan ikon yang representatif dengan warna yang mencolok sehingga mudah ditemukan di peta. Ketika marker diklik, popup muncul menampilkan informasi detail seperti alamat terdekat yang di-geocode, timestamp lokasi terakhir, dan akurasi lokasi dalam meter.

Selain posisi saat ini, peta juga dapat menampilkan riwayat pergerakan pasien dalam bentuk polyline yang menghubungkan titik-titik lokasi. Keluarga dapat memilih periode waktu untuk ditampilkan, misalnya pergerakan hari ini, minggu ini, atau custom date range. Polyline diberi warna berbeda berdasarkan waktu, dengan gradasi dari merah untuk waktu paling lama hingga hijau untuk waktu paling baru.

Fitur clustering diimplementasikan untuk menangani kasus ketika ada banyak data lokasi dalam area yang kecil. Alih-alih menampilkan ratusan marker individual yang akan membuat peta berantakan, titik-titik yang berdekatan dikelompokkan menjadi satu cluster marker yang menunjukkan jumlah titik di dalamnya. Ketika pengguna zoom in, cluster akan pecah menjadi marker individual.

Peta juga menampilkan zona geofence yang telah dikonfigurasi. Setiap zona ditampilkan sebagai lingkaran semi-transparan dengan warna dan label yang sesuai. Zona aman ditampilkan dengan warna hijau, zona berbahaya dengan merah. Ini memberikan konteks visual yang jelas tentang posisi pasien relatif terhadap zona-zona yang telah ditetapkan.

Saya menambahkan berbagai kontrol interaktif pada peta. Ada tombol untuk center peta ke lokasi pasien saat ini, tombol untuk menampilkan atau menyembunyikan riwayat pergerakan, toggle untuk mengaktifkan atau menonaktifkan auto-follow yang membuat peta otomatis mengikuti pergerakan pasien, dan slider untuk menyesuaikan transparansi zona geofence. Kontrol-kontrol ini memberikan fleksibilitas bagi keluarga untuk menyesuaikan tampilan peta sesuai kebutuhan mereka.

Fitur heat map juga tersedia untuk menampilkan area dimana pasien paling sering berada. Ini berguna untuk mengidentifikasi pola pergerakan dan tempat-tempat favorit pasien. Heat map dihitung dari data lokasi historis dengan algoritma density-based yang efisien.

## 2.10 Sistem Tombol Darurat

Keamanan pasien adalah prioritas utama, dan untuk itu saya mengimplementasikan sistem tombol darurat yang mudah diakses dari mana saja di aplikasi. Tombol darurat ditampilkan sebagai Floating Action Button besar berwarna merah yang selalu visible di layar utama pasien.

Ketika pasien menekan tombol darurat, pertama-tama muncul dialog konfirmasi untuk mencegah aktivasi tidak sengaja. Dialog menjelaskan dengan jelas bahwa menekan tombol ini akan mengirim peringatan darurat ke semua kontak keluarga yang terdaftar. Setelah konfirmasi, sistem langsung mengambil lokasi pasien dengan akurasi tinggi dan membuat entry peringatan darurat di database.

Alert darurat mencakup berbagai informasi penting seperti ID pasien, lokasi koordinat presisi tinggi, alamat hasil geocoding jika tersedia, timestamp yang tepat, status alert yang initially active, dan pesan default yang dapat dikustomisasi. Entry ini kemudian memicu berbagai aksi otomatis yang telah dikonfigurasi.

Semua anggota keluarga yang terhubung dengan pasien langsung menerima push notification melalui Firebase Cloud Messaging. Notifikasi ini memiliki prioritas tinggi dan akan muncul bahkan jika perangkat dalam mode tidak mengganggu. Konten notifikasi jelas dan mendesak, menampilkan nama pasien, pesan darurat, dan lokasi dalam format yang mudah dipahami.

Notifikasi darurat memiliki action buttons yang memungkinkan keluarga untuk langsung merespons. Ada tombol untuk membuka peta dan melihat lokasi pasien, tombol untuk menelepon pasien langsung, tombol untuk menelepon layanan darurat, dan tombol untuk menandai alert sebagai handled. Ini memungkinkan respons yang cepat tanpa perlu membuka aplikasi terlebih dahulu.

Saya juga mengimplementasikan escalation mechanism. Jika alert darurat tidak di-acknowledge oleh keluarga dalam waktu tertentu, misalnya lima menit, sistem otomatis mengirim notifikasi ulang dengan prioritas lebih tinggi. Jika masih belum ada respons, sistem dapat dikonfigurasi untuk mengirim SMS atau email backup ke kontak darurat alternatif.

Untuk audit dan analisis, semua aktivasi tombol darurat dicatat dalam log dengan detail lengkap. Log ini mencakup siapa yang mengaktifkan alert, kapan, dimana, siapa yang merespons pertama kali, berapa lama waktu respons, dan bagaimana situasi diselesaikan. Data ini berguna untuk evaluasi sistem keamanan dan peningkatan prosedur emergency response.

Di sisi pasien, setelah tombol darurat ditekan dan konfirmasi diberikan, aplikasi menampilkan screen reassurance yang memberitahu pasien bahwa bantuan sedang dalam perjalanan. Screen ini menampilkan pesan menenangkan, contact information keluarga yang sudah dihubungi, dan opsi untuk membatalkan alert jika ternyata salah pencet. Ini memberikan pasien perasaan aman dan tahu bahwa sistem bekerja dengan baik.

## 2.11 Riwayat Lokasi dan Analisis Pergerakan

Selain tracking real-time, aplikasi juga menyimpan dan menganalisis riwayat lokasi pasien. Fitur ini memberikan insight valuable tentang pola pergerakan dan kebiasaan pasien yang dapat membantu keluarga dalam merawat mereka.

Riwayat lokasi dapat diakses melalui layar tersendiri yang menampilkan list kronologis dari semua data lokasi yang terekam. Setiap entry menampilkan timestamp, alamat atau koordinat, dan akurasi data. List ini mendukung infinite scrolling untuk menangani dataset yang besar tanpa membebani performa aplikasi.

Saya mengimplementasikan berbagai filter untuk memudahkan analisis. Keluarga dapat memfilter berdasarkan date range untuk melihat pergerakan dalam periode tertentu, berdasarkan time of day untuk mengidentifikasi pola harian, berdasarkan day of week untuk melihat perbedaan pola weekday versus weekend, dan berdasarkan location zone untuk melihat seberapa sering pasien berada di zona tertentu.

Fitur export data memungkinkan keluarga untuk mengekspor riwayat lokasi dalam format CSV atau JSON. Data export ini dapat digunakan untuk analisis lebih lanjut menggunakan tools eksternal atau untuk sharing dengan profesional medis. Export mencakup semua informasi relevan dalam format yang terstruktur dan mudah diproses.

Untuk privasi dan efisiensi storage, saya mengimplementasikan data retention policy. Data lokasi yang lebih lama dari periode tertentu, misalnya tiga bulan, secara otomatis diarsipkan atau dihapus sesuai konfigurasi. Namun, statistik agregat tetap disimpan untuk analisis jangka panjang tanpa menyimpan data lokasi detail yang tidak lagi diperlukan.

Sistem juga menghasilkan berbagai statistik dari data lokasi historis. Ini mencakup total jarak yang ditempuh dalam periode tertentu, lokasi yang paling sering dikunjungi dengan frequency count, waktu rata-rata berada di rumah versus di luar, pola pergerakan harian average, dan anomaly detection yang menandai pergerakan yang tidak biasa. Statistik ini disajikan dalam dashboard yang visual dan mudah dipahami dengan grafik dan chart yang informatif.
