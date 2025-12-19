# BAB II: PEMBAHASAN FITUR YANG DIKEMBANGKAN

## Bagian 1: Sistem Autentikasi, Profil, dan Keterkaitan Pasien-Keluarga

# 2.1 Sistem Autentikasi dan Manajemen Pengguna

Pengembangan aplikasi AIVIA dimulai dengan membangun fondasi yang kuat melalui sistem autentikasi yang aman dan reliable. Saya menggunakan Supabase Auth sebagai backend autentikasi karena menyediakan berbagai fitur keamanan yang sudah teruji dan mudah diintegrasikan dengan Flutter.

Sistem autentikasi yang saya kembangkan mendukung dua alur utama yaitu registrasi pengguna baru dan login untuk pengguna yang sudah terdaftar. Pada saat registrasi, pengguna diminta untuk mengisi informasi dasar seperti nama lengkap, alamat email, dan kata sandi. Yang menarik dari implementasi ini adalah pengguna juga harus memilih peran mereka, apakah sebagai pasien atau sebagai anggota keluarga yang akan merawat. Pemilihan peran ini sangat penting karena menentukan antarmuka dan fitur yang akan ditampilkan kepada pengguna.

Proses registrasi dirancang dengan validasi yang ketat untuk memastikan data yang masuk valid dan aman. Email harus mengikuti format yang benar, kata sandi minimal delapan karakter untuk keamanan, dan nama lengkap tidak boleh kosong. Setiap kesalahan input langsung ditampilkan kepada pengguna dengan pesan yang jelas dalam bahasa Indonesia, sehingga pengguna tahu persis apa yang perlu diperbaiki.

Setelah registrasi berhasil, sistem otomatis membuat profil pengguna di database dengan informasi yang telah diisi. Ini dilakukan melalui trigger database yang berjalan otomatis setiap kali ada pengguna baru yang terdaftar. Pendekatan ini memastikan konsistensi data dan mengurangi kemungkinan error karena prosesnya terotomatisasi.

Untuk proses login, saya mengimplementasikan sistem yang sederhana namun aman. Pengguna cukup memasukkan email dan kata sandi yang telah didaftarkan. Sistem akan memverifikasi kredensial tersebut dengan database, dan jika valid, pengguna akan diarahkan ke halaman beranda sesuai dengan peran mereka. Session management ditangani oleh Supabase sehingga pengguna tidak perlu login berulang kali setiap kali membuka aplikasi.

Aspek keamanan menjadi prioritas utama dalam implementasi autentikasi ini. Kata sandi pengguna di-hash sebelum disimpan di database, sehingga bahkan administrator tidak dapat melihat kata sandi asli pengguna. Token autentikasi menggunakan JWT yang memiliki masa berlaku tertentu dan dapat di-refresh secara otomatis. Setiap request ke backend dilindungi dengan verifikasi token untuk memastikan hanya pengguna yang sah yang dapat mengakses data.

## 2.2 Manajemen Profil Pengguna

Setelah sistem autentikasi berjalan, langkah berikutnya adalah membangun sistem manajemen profil yang memungkinkan pengguna untuk melihat dan mengubah informasi pribadi mereka. Profil pengguna mencakup berbagai informasi seperti nama lengkap, nomor telepon, tanggal lahir, alamat, dan foto profil.

Implementasi manajemen profil dimulai dengan membuat repository yang bertanggung jawab untuk semua operasi terkait data profil. Repository ini menyediakan berbagai method seperti mengambil data profil, memperbarui informasi profil, mengunggah foto profil, dan menghapus foto profil. Semua operasi ini dirancang dengan error handling yang baik menggunakan Result pattern, sehingga setiap kesalahan dapat ditangani dengan tepat.

Untuk foto profil, saya mengimplementasikan sistem unggah gambar yang komprehensif. Pengguna dapat memilih foto dari galeri atau mengambil foto baru menggunakan kamera. Foto yang dipilih kemudian akan di-crop agar memiliki rasio yang konsisten, di-resize untuk mengoptimalkan ukuran file, dan di-compress untuk menghemat bandwidth dan ruang penyimpanan. Setelah itu, foto diunggah ke Supabase Storage dan URL-nya disimpan di database profil pengguna.

Antarmuka edit profil dirancang dengan mempertimbangkan kemudahan penggunaan. Setiap field input memiliki label yang jelas, placeholder yang membantu, dan validasi real-time yang memberikan feedback langsung kepada pengguna. Jika ada kesalahan input, pesan error ditampilkan di bawah field yang bersangkutan dengan bahasa yang mudah dipahami. Tombol simpan hanya akan aktif ketika semua input valid, mencegah penyimpanan data yang tidak lengkap atau salah.

State management untuk profil pengguna menggunakan Riverpod dengan StreamProvider. Ini memungkinkan data profil selalu up-to-date secara real-time. Ketika ada perubahan pada profil di database, baik dari perangkat yang sama atau perangkat lain, perubahan tersebut langsung tercermin di aplikasi tanpa perlu refresh manual. Pendekatan ini memberikan pengalaman pengguna yang lebih baik dan mengurangi kemungkinan data yang tidak sinkron.

Untuk mengoptimalkan performa, saya juga mengimplementasikan caching sederhana. Data profil yang sudah pernah dimuat akan disimpan sementara di memori, sehingga tidak perlu mengambil data dari server setiap kali layar profil dibuka. Cache ini akan diperbarui otomatis ketika ada perubahan data, memastikan pengguna selalu melihat informasi yang terkini.

## 2.3 Sistem Keterkaitan Pasien-Keluarga

Salah satu fitur unik dari aplikasi AIVIA adalah kemampuan untuk menghubungkan akun pasien dengan akun keluarga atau pengasuh. Fitur ini sangat penting karena memungkinkan keluarga untuk memantau dan membantu pasien Alzheimer dalam aktivitas sehari-hari mereka, bahkan dari jarak jauh.

Sistem keterkaitan ini dirancang dengan model many-to-many, dimana satu pasien dapat dihubungkan dengan beberapa anggota keluarga, dan satu anggota keluarga juga dapat merawat beberapa pasien. Setiap hubungan menyimpan metadata penting seperti jenis hubungan misalnya anak, orang tua, atau pasangan, status pengasuh utama, dan berbagai izin akses.

Konsep izin akses menjadi aspek krusial dalam sistem ini. Saya mengimplementasikan dua jenis izin utama yaitu izin untuk mengedit aktivitas pasien dan izin untuk melihat lokasi pasien. Izin ini dapat dikonfigurasi secara individual untuk setiap anggota keluarga, memberikan fleksibilitas dalam mengelola privasi dan akses data sensitif. Misalnya, seorang anak mungkin diberikan semua izin penuh, sementara saudara jauh mungkin hanya dapat melihat aktivitas tanpa bisa mengeditnya.

Proses menghubungkan pasien dengan keluarga dirancang sesederhana mungkin. Keluarga cukup memasukkan email atau kode unik pasien yang ingin mereka hubungkan. Sistem kemudian akan mengirim permintaan keterkaitan yang harus disetujui oleh pasien atau pengasuh utama. Mekanisme persetujuan ini penting untuk mencegah akses yang tidak sah dan menjaga privasi pasien.

Setelah keterkaitan berhasil dibuat, anggota keluarga akan dapat mengakses berbagai fitur yang berkaitan dengan pasien tersebut melalui aplikasi. Mereka dapat melihat dan mengelola jadwal aktivitas pasien, memantau lokasi real-time pasien jika memiliki izin, menerima notifikasi darurat, melihat riwayat aktivitas dan pengenalan wajah, serta berkomunikasi melalui fitur chat.

Di sisi database, sistem keterkaitan ini dilindungi dengan Row Level Security yang ketat. Setiap query ke database secara otomatis difilter berdasarkan hubungan keterkaitan yang ada. Misalnya, ketika seorang keluarga mengakses data aktivitas, database hanya akan mengembalikan aktivitas dari pasien yang terhubung dengan mereka. Pendekatan ini memastikan isolasi data antar pengguna dan mencegah akses tidak sah bahkan di level database.

Untuk memberikan pengalaman yang lebih baik, saya juga mengimplementasikan sistem notifikasi untuk berbagai event terkait keterkaitan. Pasien akan menerima notifikasi ketika ada permintaan keterkaitan baru. Keluarga akan mendapat notifikasi ketika permintaan mereka disetujui atau ditolak. Notifikasi juga dikirim ketika ada perubahan status pengasuh utama atau perubahan izin akses. Semua notifikasi ini membantu pengguna tetap terinformasi tentang perubahan yang terjadi dalam sistem keterkaitan.

Implementasi sistem keterkaitan ini juga mempertimbangkan skenario edge case seperti ketika pasien menghapus akun mereka. Dalam kasus ini, semua keterkaitan dengan keluarga akan otomatis dihapus melalui cascade delete. Ketika seorang anggota keluarga tidak lagi ingin terhubung, mereka dapat memutuskan keterkaitan dengan mudah melalui antarmuka aplikasi. Data riwayat keterkaitan disimpan untuk audit trail, namun tidak lagi aktif mempengaruhi akses data.

Sistem ini juga terintegrasi dengan fitur-fitur lain di aplikasi. Misalnya, ketika membuat aktivitas baru, keluarga dapat memilih pasien mana yang akan dibuatkan aktivitas tersebut jika mereka terhubung dengan lebih dari satu pasien. Ketika melihat peta, keluarga dapat dengan mudah beralih antara lokasi pasien yang berbeda jika mereka merawat beberapa pasien sekaligus. Integrasi yang mulus ini membuat pengalaman pengguna menjadi lebih kohesif dan intuitif.
