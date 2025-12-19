# Laporan Akhir Proyek Aplikasi AIVIA

## Aplikasi Asisten Interaktif Virtual untuk Alzheimer

**Nama**: M. Ikhsan Pasaribu  
**Program Studi**: Teknologi Informasi  
**Mata Kuliah**: Praktikum Pemrograman Bergerak  
**Periode Pengembangan**: Oktober - Desember 2025  
**Status Proyek**: Selesai (100%)

---

# BAB I: PENDAHULUAN

## 1.1 Latar Belakang

Alzheimer merupakan penyakit degeneratif yang menyerang fungsi kognitif seseorang, terutama memori dan kemampuan untuk melakukan aktivitas sehari-hari. Di Indonesia, jumlah penderita Alzheimer terus meningkat seiring dengan pertumbuhan populasi lansia. Kondisi ini tidak hanya berdampak pada penderita, tetapi juga memberikan beban yang sangat berat bagi keluarga yang merawat mereka.

Dalam merawat pasien Alzheimer, keluarga menghadapi berbagai tantangan. Pasien sering kali lupa melakukan aktivitas penting seperti makan atau minum obat, kesulitan mengenali wajah orang terdekat, dan berisiko mengalami wandering atau berjalan tanpa tujuan yang dapat membahayakan keselamatan mereka. Keluarga juga kesulitan memantau keberadaan dan kondisi pasien, terutama ketika tidak bisa mendampingi secara langsung.

Teknologi mobile saat ini telah berkembang pesat dan menawarkan berbagai solusi untuk membantu kehidupan sehari-hari. Smartphone yang sudah sangat umum digunakan memiliki berbagai sensor dan kemampuan yang dapat dimanfaatkan untuk membantu perawatan pasien Alzheimer. Namun, aplikasi yang ada saat ini masih sangat terbatas dan belum secara khusus dirancang untuk memenuhi kebutuhan kompleks dari pasien Alzheimer dan keluarga mereka.

Dari analisis kebutuhan tersebut, saya mengembangkan AIVIA atau Alzheimer Interactive Virtual Intelligent Assistant. Aplikasi ini dirancang sebagai solusi komprehensif yang menggabungkan berbagai fitur untuk membantu pasien Alzheimer menjalani aktivitas harian mereka dengan lebih mandiri, sekaligus memberikan ketenangan pikiran bagi keluarga melalui sistem pemantauan dan notifikasi yang canggih.

AIVIA dikembangkan dengan mempertimbangkan karakteristik khusus pengguna. Untuk pasien, antarmuka dirancang sangat sederhana dengan elemen visual yang besar, warna kontras tinggi, dan navigasi yang intuitif. Untuk keluarga, aplikasi menyediakan dashboard yang informatif dengan berbagai tools manajemen dan pemantauan yang lengkap. Semua fitur dirancang dengan prinsip aksesibilitas dan kemudahan penggunaan sebagai prioritas utama.

## 1.2 Tujuan Pengembangan

Tujuan utama dari pengembangan aplikasi AIVIA adalah menciptakan solusi digital yang benar-benar membantu meningkatkan kualitas hidup pasien Alzheimer dan meringankan beban keluarga dalam merawat mereka. Secara lebih spesifik, tujuan pengembangan aplikasi ini dapat dijabarkan sebagai berikut.

Pertama, membangun sistem pengingat aktivitas yang cerdas dan dapat diandalkan. Pasien Alzheimer sering kali lupa dengan jadwal harian mereka, sehingga diperlukan sistem yang dapat mengingatkan mereka di waktu yang tepat. Sistem ini tidak hanya sekedar alarm, tetapi terintegrasi dengan notifikasi yang jelas dan mudah dipahami, serta dapat dikelola oleh keluarga dari jarak jauh.

Kedua, mengimplementasikan sistem pelacakan lokasi yang akurat dan realtime. Fitur ini sangat penting mengingat pasien Alzheimer rentan mengalami wandering. Keluarga harus dapat mengetahui lokasi pasien kapan saja dan mendapat peringatan otomatis jika pasien keluar dari zona aman. Sistem ini harus dapat bekerja di latar belakang tanpa mengganggu penggunaan aplikasi lainnya.

Ketiga, menyediakan fitur pengenalan wajah berbasis pembelajaran mesin yang dapat membantu pasien mengingat orang-orang terdekat mereka. Fitur ini menggunakan teknologi pemrosesan di perangkat untuk menjaga privasi data, sekaligus memberikan informasi yang membantu pasien mengingat kembali hubungan mereka dengan orang tersebut.

Keempat, membangun sistem keamanan berlapis dengan tombol darurat dan geofencing. Keamanan pasien adalah prioritas tertinggi, sehingga aplikasi harus mampu mendeteksi situasi berbahaya dan memberikan respons cepat, baik melalui notifikasi ke keluarga maupun kemampuan untuk menghubungi bantuan darurat.

Kelima, menciptakan pengalaman pengguna yang inklusif melalui dukungan tema gelap, multibahasa, dan berbagai fitur aksesibilitas lainnya. Aplikasi harus dapat digunakan dengan nyaman dalam berbagai kondisi dan oleh pengguna dengan berbagai preferensi dan kebutuhan.

Keenam, mengembangkan sistem yang reliable dan efisien dengan dukungan mode offline, sinkronisasi otomatis, dan optimasi performa. Aplikasi harus tetap berfungsi dengan baik bahkan ketika koneksi internet tidak stabil, mengingat target pengguna mungkin berada di berbagai lokasi dengan kondisi jaringan yang berbeda.

## 1.3 Ruang Lingkup Proyek

Ruang lingkup pengembangan aplikasi AIVIA mencakup berbagai aspek yang saling terintegrasi untuk membentuk solusi yang komprehensif. Berikut adalah rincian dari ruang lingkup proyek ini.

Dari sisi platform, aplikasi dikembangkan menggunakan Flutter sebagai framework utama dengan target platform Android. Pemilihan Flutter memungkinkan pengembangan yang efisien dengan performa yang baik, sekaligus membuka kemungkinan untuk ekspansi ke platform lain di masa mendatang. Aplikasi memanfaatkan berbagai kemampuan native Android seperti layanan latar belakang, notifikasi lokal, akses kamera, dan sensor lokasi.

Dari sisi arsitektur, aplikasi dibangun dengan pendekatan clean architecture yang memisahkan lapisan presentasi, domain, dan data. State management menggunakan Riverpod yang memungkinkan pengelolaan state yang reaktif dan efisien. Database menggunakan Supabase dengan PostgreSQL sebagai backend, dilengkapi dengan Row Level Security untuk keamanan data dan Realtime untuk sinkronisasi data secara langsung.

Ruang lingkup fungsional aplikasi mencakup tujuh area utama. Pertama adalah manajemen pengguna yang meliputi autentikasi, profil, dan sistem linking antara pasien dan keluarga. Kedua adalah manajemen aktivitas harian dengan fitur jurnal, pengingat, kalender, dan lampiran foto. Ketiga adalah sistem lokasi dan peta dengan pelacakan realtime, visualisasi peta, riwayat pergerakan, dan geofencing.

Keempat adalah sistem keamanan dan darurat dengan tombol panik, deteksi keluar zona aman, dan notifikasi otomatis ke kontak darurat. Kelima adalah pengenalan wajah menggunakan machine learning on-device dengan model TensorFlow Lite. Keenam adalah sistem komunikasi dengan fitur chat realtime dan status online. Ketujuh adalah personalisasi dengan dukungan tema gelap, multibahasa Indonesia dan Inggris, serta berbagai pengaturan lainnya.

Dari sisi teknis, aplikasi mengimplementasikan berbagai pattern dan best practice. Offline-first architecture memastikan aplikasi tetap berfungsi tanpa internet dengan sistem antrian dan sinkronisasi otomatis. Error handling yang komprehensif menggunakan Result pattern memberikan penanganan kesalahan yang terstruktur. Optimasi performa dilakukan melalui lazy loading, caching, dan efisiensi query database.

Untuk keamanan dan privasi, aplikasi menerapkan enkripsi data sensitif, Row Level Security di database, pemrosesan wajah di perangkat tanpa mengirim data ke server, dan manajemen izin yang ketat sesuai dengan kebutuhan fitur. Semua ini dirancang untuk melindungi privasi pengguna yang merupakan aspek krusial dalam aplikasi kesehatan.

Ruang lingkup juga mencakup aspek non-fungsional seperti aksesibilitas dengan ukuran font yang dapat disesuaikan, kontras warna tinggi, dan ukuran target sentuh yang memadai. Performa aplikasi dijaga agar tetap responsif dengan waktu loading yang minimal. Reliabilitas dijamin melalui penanganan error yang baik dan mekanisme recovery otomatis. Skalabilitas dipertimbangkan dalam desain database dan struktur kode untuk memudahkan pengembangan fitur di masa mendatang.

Dokumentasi menjadi bagian penting dari ruang lingkup proyek ini. Setiap tahap pengembangan didokumentasikan dengan detail dalam laporan progress yang terstruktur. Kode dilengkapi dengan komentar yang jelas, dan arsitektur sistem didokumentasikan dalam diagram dan penjelasan tertulis. Dokumentasi ini tidak hanya untuk keperluan akademis, tetapi juga untuk memudahkan maintenance dan pengembangan lanjutan di masa mendatang.
