# Laporan Progress 7: Lampiran Foto Aktivitas dan Integrasi UI Lengkap

**Nama**: M. Ikhsan Pasaribu  
**Periode**: Desember 2025  
**Fokus**: Fitur Lampiran Foto Aktivitas, Integrasi UI End-to-End, Peningkatan Konteks Visual  
**Status Implementasi**: Selesai (100%)

---

## BAB I: PENDAHULUAN

### 1.1 Latar Belakang

Setelah menyelesaikan implementasi dark mode dan berbagai fitur core seperti tracking lokasi, geofencing, dan pengenalan wajah, saya mulai mempertimbangkan aspek yang sering terlewatkan namun sangat bermakna: konteks visual dalam aktivitas sehari-hari. Pasien dengan gangguan kognitif seperti Alzheimer sering kesulitan mengingat instruksi atau objek penting. Keluarga juga memerlukan cara yang lebih jelas untuk memverifikasi bahwa aktivitas telah dilakukan dengan benar.

Dari observasi ini, saya menyadari bahwa lampiran foto pada setiap aktivitas bisa menjadi alat yang powerful dan sederhana. Foto obat, lokasi kegiatan, atau instruksi visual dapat membantu pasien mengingat dengan lebih baik. Untuk keluarga, foto memberikan bukti konkret dan konteks yang membuat komunikasi terasa lebih jelas dan minim miskomunikasi.

Pada progress ketujuh ini, saya memfokuskan diri untuk menyelesaikan fitur lampiran foto secara menyeluruh. Mulai dari pemilihan foto, kompresi untuk efisiensi, pengunggahan ke storage, integrasi pada antarmuka keluarga, hingga tampilan di sisi pasien. Semuanya dirancang dengan prinsip kesederhanaan dan aksesibilitas yang telah menjadi fondasi AIVIA.

### 1.2 Tujuan

Tujuan saya adalah menyelesaikan alur lampiran foto end-to-end dan membuat fitur ini terintegrasi secara natural pada semua antarmuka yang relevan. Saya ingin memastikan bahwa fitur ini tidak hanya fungsional, tetapi juga aman, efisien, dan mudah digunakan oleh semua pengguna aplikasi.

Secara spesifik, saya ingin mencapai beberapa tujuan utama. Pertama, mengembangkan widget-widget reusable yang mendukung pemilihan foto, tampilan grid, dan viewer fullscreen dengan zoom dan swipe. Kedua, mengintegrasikan repository dan provider untuk mengelola unggahan batch foto, sinkronisasi database, dan penghapusan aman. Ketiga, mengintegrasikan fitur ini pada layar keluarga (tambah dan edit aktivitas) dan layar pasien (daftar dan detail aktivitas) tanpa menggangu alur utama. Keempat, memastikan kualitas kode tetap terjaga dengan validasi statis dan prinsip error handling yang konsisten.

### 1.3 Ruang Lingkup

Ruang lingkup pekerjaan mencakup pengembangan tiga komponen widget utama (pemilih foto, grid foto, dan viewer), integrasi repository untuk operasi foto (unggah, hapus single, hapus massal), integrasi provider dengan state management yang robust, serta integrasi pada layar keluarga dan pasien. Saya juga melakukan validasi keamanan, privasi, dan performa untuk memastikan aplikasi tetap stabil dan responsif.

---

## BAB II: PROGRESS PENGEMBANGAN

### 2.1 Desain Solusi dan Arsitektur

Saya merancang alur data yang sederhana namun aman. Ketika pengguna memilih foto dari galeri atau kamera, file langsung di-resize dan dikompres untuk menjaga performa dan hemat bandwidth. Setelah itu, foto diunggah ke Supabase Storage dalam bucket bernama `activity-photos` dengan struktur path berbasis `activityId`, sehingga pengelolaan dan penghapusan dapat dilakukan secara terstruktur dan selektif.

Di sisi database, kolom `photo_urls` di tabel `activities` (yang berjenis TEXT array) menyimpan daftar URL publik dari Supabase Storage. Repository kemudian memperbarui kolom ini setelah unggahan berhasil, sehingga UI dapat langsung menerima data yang valid dan siap ditampilkan. Setiap operasi mutasi (unggah, hapus) melalui jalur yang sudah dilindungi oleh Row Level Security (RLS) Supabase, memastikan tidak ada akses yang tidak sah.

### 2.2 Implementasi Teknis Komponen

Pada sisi presentasi, saya mengembangkan tiga komponen utama yang masing-masing memiliki tanggung jawab spesifik. Pertama adalah `ActivityPhotoPicker`, widget yang memungkinkan pengguna memilih hingga lima foto sekaligus dari galeri atau kamera. Widget ini menampilkan pratinjau thumbnail dari foto yang dipilih, dengan opsi untuk menghapus foto sebelum unggahan. Kedua adalah `ActivityPhotoGrid`, widget yang menampilkan foto dalam format grid dengan dukungan untuk menghapus foto (khusus untuk keluarga). Ketiganya adalah `PhotoViewerScreen`, layar fullscreen untuk melihat foto dengan dukungan pinch-to-zoom dan swipe antar foto.

Di sisi data, repository menyediakan tiga metode utama. `uploadPhotos` menangani unggahan batch foto dengan callback untuk melaporkan progress. Metode ini juga menangani sinkronisasi array `photo_urls` di database setelah semua foto berhasil diunggah. `deletePhoto` menghapus satu foto berdasarkan URL publik yang diturunkan ke path yang aman di storage, kemudian memperbarui array `photo_urls` di database. `deleteAllPhotos` melakukan pembersihan massal ketika diperlukan, misalnya saat aktivitas dihapus.

Di lapisan state management, saya menggunakan Riverpod dengan `AsyncValue` untuk mengelola state operasi asinkron. Provider controller memiliki metode yang sesuai dengan repository, namun dengan tambahan error handling yang robust menggunakan pola `Result<T>`. Ini memastikan UI dapat membedakan antara keadaan loading, sukses, dan gagal dengan jelas.

### 2.3 Integrasi pada Layar Keluarga

Integrasi pada layar keluarga dilakukan di dua tempat utama: form tambah aktivitas dan form edit aktivitas. Di layar tambah, saya menambahkan widget `ActivityPhotoPicker` setelah field deskripsi aktivitas. Pengguna dapat memilih foto sebelum menyimpan aktivitas. Setelah aktivitas berhasil dibuat, jika ada foto yang dipilih, aplikasi secara otomatis mengunggah foto-foto tersebut dan memperbarui data aktivitas.

Di layar edit, tampilan menjadi sedikit lebih kompleks. Aplikasi menampilkan foto-foto existing menggunakan widget `ActivityPhotoGrid`, dengan opsi untuk menghapus masing-masing foto jika diperlukan. Di bawah galeri existing, aplikasi menyediakan `ActivityPhotoPicker` untuk menambahkan foto baru. Ketika pengguna menyimpan perubahan, aplikasi mengunggah foto-foto baru dan menghapus foto yang telah dihapus dari interface.

Kartu aktivitas pada daftar aktivitas keluarga ditingkatkan dengan pratinjau foto kompak menggunakan widget `ActivityPhotoCompactGrid`. Ini menampilkan beberapa foto pertama dalam ukuran kecil, cukup untuk memberikan visual context tanpa membuat kartu menjadi terlalu besar atau berat secara visual.

### 2.4 Integrasi pada Layar Pasien

Untuk pasien, integrasi difokuskan pada penyediaan konteks visual tanpa beban kognitif tambahan. Di layar daftar aktivitas, setiap aktivitas ditampilkan dengan pratinjau foto kompak jika ada. Ini memberikan isyarat visual bahwa aktivitas tersebut memiliki instruksi atau konteks visual, namun tidak mengalihkan perhatian dari informasi utama.

Di modal detail aktivitas, pasien dapat melihat galeri foto lengkap dalam ukuran yang lebih besar. Widget `ActivityPhotoGrid` ditampilkan tanpa opsi hapus (karena pasien bukan yang mengelola), memungkinkan pasien melihat foto-foto dengan clear dan mudah. Jika pengguna mengetuk salah satu foto, layar fullscreen `PhotoViewerScreen` terbuka, memberikan pengalaman viewing yang immersive dengan zoom dan navigasi yang responsif.

Pada layar manajemen aktivitas keluarga dan layar daftar aktivitas pasien dalam patient detail, integrasi juga diterapkan secara konsisten dengan pratinjau foto kompak di setiap kartu aktivitas.

### 2.5 Keamanan dan Privasi

Keamanan adalah prioritas utama dalam implementasi fitur ini. Row Level Security (RLS) Supabase tetap aktif dan dihormati. Akses terhadap URL foto mengikuti keterkaitan antara pengguna dan pasien, sehingga pasien hanya dapat melihat foto aktivitas mereka sendiri, dan keluarga hanya dapat melihat foto aktivitas pasien yang terkait dengan mereka.

Penghapusan foto dilakukan berdasarkan path yang diturunkan dari URL objek publik. Tidak ada informasi sensitif yang disimpan pada nama file atau metadata. Kolom `photo_urls` hanya menyimpan URL publik yang diperlukan untuk tampilan, sehingga tidak ada data privat yang bocor ke database.

Saya juga melakukan sanitasi terhadap upload untuk memastikan hanya file gambar yang valid (JPEG, PNG) yang dapat diunggah, dengan ukuran maksimal yang reasonable. Proses resize dan kompresi mengurangi risiko upload file yang sangat besar yang bisa mempengaruhi performa.

### 2.6 Performa dan Optimasi

Untuk menjaga performa aplikasi tetap optimal, foto di-resize dan dikompres sebelum unggahan. Ukuran maksimal untuk activity photo adalah 800x800 piksel dengan kualitas 85%, yang menghasilkan ukuran file yang reasonable namun tetap berkualitas visual yang baik.

Tampilan grid foto menggunakan lazy loading untuk gambar, sehingga hanya foto yang visible di screen yang di-load terlebih dahulu. Library `cached_network_image` digunakan untuk caching lokal, mengurangi bandwidth dan mempercepat loading pada kunjungan berikutnya.

Integrasi Riverpod memastikan UI tetap responsif dan terkontrol, dengan minimal rebuilds yang tidak perlu. Provider hanya memicu rebuild pada widget yang benar-benar tergantung pada state yang berubah, bukan seluruh tree.

### 2.7 Testing dan Validasi

Saya melakukan validasi statis menggunakan `flutter analyze` dan memastikan tidak ada error, peringatan, atau info yang perlu ditindaklanjuti. Alur unggah dan hapus foto telah diuji di emulator dan perangkat fisik, menunjukkan behavior yang sesuai dengan harapan.

Setiap operasi dilengkapi dengan feedback visual yang jelas dan informatif. Ketika foto sedang diunggah, user melihat indicator loading. Ketika penghapusan berhasil, snackbar muncul dengan pesan sukses. Ketika ada error, pesan error ditampilkan dengan bahasa Indonesia yang jelas dan tips untuk mengatasi masalah.

---

## BAB III: EVALUASI DAN DAMPAK

Fitur lampiran foto aktivitas memberikan dampak positif yang nyata pada pengalaman pengguna. Keluarga sekarang memiliki cara yang lebih konkret untuk berkomunikasi instruksi visual kepada pasien. Misalnya, foto obat yang harus diminum, lokasi kegiatan, atau pola cara melakukan aktivitas tertentu dapat langsung ditampilkan di aplikasi.

Bagi pasien, dukungan visual membantu mengurangi cognitive load. Alih-alih hanya membaca teks instruksi, pasien dapat melihat visual yang lebih mudah dipahami dan diingat. Ini sejalan dengan prinsip bahwa individu dengan Alzheimer sering mempertahankan kemampuan visual processing lebih baik daripada text comprehension.

Dari perspektif engineering, implementasi ini menunjukkan bahwa kompleksitas dapat dikelola dengan baik melalui clean architecture, separation of concerns yang jelas, dan systematic testing. Fitur ini menambah nilai aplikasi tanpa mengorbankan stability atau maintainability kode.

---

## BAB IV: PENUTUP

### 4.1 Kesimpulan

Fitur lampiran foto aktivitas telah selesai secara end-to-end dan terintegrasi mulus pada alur pasien dan keluarga. Database telah diperbarui dengan migration yang menciptakan kolom `photo_urls` dan index untuk optimasi. Repository dan provider menyediakan API yang clean dan aman untuk operasi foto. Widget-widget reusable telah dikembangkan dan diintegrasikan ke semua screen yang relevan. Kualitas kode, keamanan, dan performa telah dijaga dengan baik melalui validasi statis dan testing manual.

Aplikasi AIVIA sekarang berada pada kondisi yang lebih mature, dengan fitur lampiran foto yang memberikan nilai tambah signifikan untuk meningkatkan clarity komunikasi antara keluarga dan pasien.

### 4.2 Rencana Lanjutan

Ke depan, saya akan memfokuskan pada beberapa area untuk continuous improvement. Optimasi cache gambar di sisi klien dapat ditingkatkan untuk menangani koneksi internet yang lambat dengan better caching strategy. Penambahan alt text sederhana pada setiap foto dapat meningkatkan aksesibilitas bagi pengguna dengan screen readers.

Fitur offline-first upload scheduling dapat memungkinkan user untuk schedule upload ketika jaringan tersedia, mengurangi frustration di area dengan konektivitas yang tidak stabil. Pembersihan metadata foto (EXIF stripping) pada unggahan dapat memberikan lapisan privasi tambahan dengan menghapus informasi lokasi dan device yang tertanam pada file foto.

Instrumentasi dan monitoring terhadap metrics seperti latency unggah, durasi kompresi, dan cache hit rates dapat memberikan insights untuk optimasi lebih lanjut. Experimentation dengan different compression levels berdasarkan network speed dapat meningkatkan user experience pada berbagai kondisi jaringan.

---

**Validasi**: `flutter analyze` → Tidak ada isu.

**Catatan**: Seluruh perubahan mengikuti pedoman penamaan, standar kualitas kode, prinsip aksesibilitas, dan best practices yang telah ditetapkan pada iterasi-iterasi sebelumnya. Fitur ini mempertahankan konsistensi dengan design system yang sudah ada dan tidak memperkenalkan breaking changes pada API yang sudah ada.
