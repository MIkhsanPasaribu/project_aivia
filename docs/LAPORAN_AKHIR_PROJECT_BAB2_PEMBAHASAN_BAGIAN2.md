# BAB II: PEMBAHASAN FITUR YANG DIKEMBANGKAN

## Bagian 2: Manajemen Aktivitas, Sistem Notifikasi, dan Kalender

# 2.4 Jurnal Aktivitas Harian

Fitur jurnal aktivitas merupakan jantung dari aplikasi AIVIA. Fitur ini dirancang untuk membantu pasien Alzheimer mengingat dan melakukan aktivitas penting dalam kehidupan sehari-hari mereka. Implementasi fitur ini mencakup operasi lengkap untuk membuat, membaca, memperbarui, dan menghapus aktivitas dengan berbagai fitur pendukung yang membuatnya lebih dari sekadar daftar tugas biasa.

Setiap aktivitas memiliki berbagai atribut yang penting. Ada judul aktivitas yang singkat dan deskriptif, deskripsi detail yang memberikan informasi tambahan, waktu aktivitas yang menentukan kapan aktivitas harus dilakukan, status penyelesaian yang menandai apakah aktivitas sudah selesai atau belum, informasi tentang siapa yang mengambil tanggung jawab aktivitas tersebut, dan bahkan lampiran foto yang memberikan konteks visual.

Untuk keluarga, saya menyediakan antarmuka yang lengkap untuk mengelola aktivitas pasien mereka. Mereka dapat menambah aktivitas baru melalui form yang intuitif dengan berbagai field yang dapat diisi. Proses penambahan aktivitas dilengkapi dengan validasi yang memastikan semua informasi penting telah diisi. Setelah aktivitas dibuat, sistem otomatis akan menjadwalkan pengingat sesuai dengan waktu yang ditentukan.

Fitur edit aktivitas memungkinkan keluarga untuk memperbarui informasi aktivitas yang sudah ada. Ini berguna ketika ada perubahan jadwal atau ketika perlu menambahkan informasi tambahan. Form edit sudah terisi dengan data aktivitas yang ada, sehingga keluarga hanya perlu mengubah bagian yang diperlukan tanpa harus mengisi ulang semuanya.

Untuk menghapus aktivitas, saya mengimplementasikan mekanisme konfirmasi untuk mencegah penghapusan tidak sengaja. Ketika keluarga memilih untuk menghapus aktivitas, dialog konfirmasi akan muncul menjelaskan konsekuensi dari tindakan tersebut. Hanya setelah konfirmasi, aktivitas benar-benar dihapus dari database beserta semua notifikasi yang terjadwal terkait aktivitas tersebut.

Di sisi pasien, antarmuka aktivitas dirancang dengan prinsip kesederhanaan maksimal. Mereka melihat daftar aktivitas dalam format yang sangat jelas dengan ukuran font yang besar dan warna yang kontras. Setiap kartu aktivitas menampilkan informasi penting seperti judul, waktu, dan status dengan ikon yang mudah dipahami. Pasien dapat menandai aktivitas sebagai selesai dengan sekali ketuk pada tombol yang besar dan jelas.

Sistem aktivitas juga mendukung berbagai filter dan pencarian untuk memudahkan pengelolaan. Pengguna dapat memfilter aktivitas berdasarkan status seperti aktif, selesai, atau terlambat. Mereka juga dapat memfilter berdasarkan periode waktu seperti hari ini, minggu ini, atau semua aktivitas. Fitur pencarian memungkinkan pengguna untuk menemukan aktivitas spesifik dengan cepat berdasarkan judul atau deskripsi.

Untuk memberikan gambaran yang lebih visual, saya juga mengimplementasikan tampilan kalender yang menampilkan aktivitas dalam format bulanan. Setiap tanggal yang memiliki aktivitas ditandai dengan indikator khusus, dan pengguna dapat mengetuk tanggal tertentu untuk melihat detail aktivitas pada hari tersebut. Tampilan kalender ini sangat membantu untuk perencanaan jangka panjang dan melihat pola aktivitas.

## 2.5 Sistem Notifikasi Lokal

Sistem notifikasi adalah komponen krusial yang memastikan pasien tidak melewatkan aktivitas penting mereka. Saya mengimplementasikan notifikasi lokal menggunakan Awesome Notifications, sebuah plugin yang sangat powerful untuk Flutter dengan dukungan penjadwalan yang presisi.

Setiap kali aktivitas baru dibuat atau diperbarui, sistem otomatis menjadwalkan notifikasi pengingat. Notifikasi ini dijadwalkan untuk muncul lima belas menit sebelum waktu aktivitas, memberikan pasien waktu yang cukup untuk bersiap. Konten notifikasi dirancang dengan jelas, menampilkan judul aktivitas, deskripsi singkat, dan waktu aktivitas dalam format yang mudah dibaca.

Implementasi notifikasi mempertimbangkan berbagai perubahan di Android, terutama Android 12 ke atas yang memerlukan izin khusus untuk alarm presisi. Saya menambahkan request izin yang sesuai dan memberikan penjelasan kepada pengguna mengapa izin ini penting untuk fungsi aplikasi. Tanpa izin ini, notifikasi mungkin tidak muncul pada waktu yang tepat, yang dapat mengakibatkan pasien melewatkan aktivitas penting.

Notifikasi channel dikonfigurasi dengan prioritas tinggi untuk memastikan notifikasi muncul bahkan ketika perangkat dalam mode hemat baterai. Channel ini diberi nama dan deskripsi yang jelas dalam bahasa Indonesia sehingga pengguna memahami untuk apa notifikasi ini digunakan. Pengaturan suara, getaran, dan LED notification juga dikonfigurasi untuk memberikan peringatan yang cukup menarik perhatian tanpa mengganggu.

Ketika aktivitas dihapus atau waktu aktivitas diubah, sistem otomatis membatalkan notifikasi lama dan menjadwalkan notifikasi baru sesuai dengan perubahan. Ini memastikan bahwa notifikasi yang diterima pasien selalu akurat dan relevan. Mekanisme pembatalan notifikasi menggunakan ID unik yang dihasilkan dari ID aktivitas, memastikan notifikasi yang tepat yang dibatalkan.

Saya juga mengimplementasikan riwayat notifikasi yang memungkinkan pengguna melihat semua notifikasi yang pernah mereka terima. Fitur ini berguna untuk tracking dan debugging, serta memberikan transparansi kepada pengguna tentang aktivitas sistem. Riwayat mencatat kapan notifikasi dikirim, apakah notifikasi berhasil ditampilkan, dan apakah pengguna berinteraksi dengan notifikasi tersebut.

Untuk pengguna keluarga, sistem juga mendukung notifikasi push melalui Firebase Cloud Messaging. Ketika terjadi event penting seperti pasien menyelesaikan aktivitas, keluar dari zona aman, atau menekan tombol darurat, notifikasi push dikirim ke semua perangkat keluarga yang terhubung. Ini memastikan keluarga selalu mendapat informasi terkini tentang kondisi dan aktivitas pasien mereka.

## 2.6 Tampilan Kalender dan Statistik Aktivitas

Untuk memberikan gambaran yang lebih komprehensif tentang pola aktivitas, saya mengembangkan fitur tampilan kalender dan statistik aktivitas. Fitur ini sangat berguna bagi keluarga untuk memantau konsistensi dan performa pasien dalam menjalankan aktivitas harian mereka.

Tampilan kalender menggunakan plugin table_calendar yang menyediakan antarmuka kalender yang interaktif dan dapat dikustomisasi. Setiap tanggal dalam kalender ditandai dengan indikator jika ada aktivitas pada tanggal tersebut. Indikator ini diberi warna berbeda berdasarkan status aktivitas, misalnya hijau untuk aktivitas yang selesai, merah untuk yang terlewat, dan biru untuk yang masih menunggu.

Ketika pengguna mengetuk tanggal tertentu, panel detail di bawah kalender menampilkan daftar semua aktivitas pada tanggal tersebut. Aktivitas ditampilkan dalam urutan kronologis dengan informasi lengkap termasuk waktu, judul, status, dan ikon yang representatif. Pengguna dapat langsung mengetuk aktivitas untuk melihat detail lebih lanjut atau mengeditnya jika mereka memiliki izin untuk itu.

Fitur navigasi kalender memungkinkan pengguna untuk dengan mudah berpindah antar bulan atau langsung melompat ke tanggal tertentu. Ada juga tombol untuk kembali ke tanggal hari ini, yang sangat berguna ketika pengguna sudah browsing ke bulan-bulan sebelumnya dan ingin kembali cepat ke konteks saat ini.

Untuk statistik aktivitas, saya mengimplementasikan beberapa visualisasi yang informatif. Pertama adalah chart penyelesaian aktivitas yang menampilkan persentase aktivitas yang diselesaikan versus yang terlewat dalam periode tertentu. Chart ini menggunakan bar chart atau pie chart yang mudah dipahami dengan warna yang jelas dan label yang deskriptif.

Statistik juga mencakup berbagai metrik numerik seperti total aktivitas dalam periode tertentu, jumlah aktivitas yang diselesaikan, jumlah aktivitas yang terlewat, rata-rata penyelesaian harian, dan streak atau berapa hari berturut-turut pasien menyelesaikan semua aktivitas mereka. Metrik-metrik ini disajikan dalam kartu-kartu yang menarik dengan ikon dan warna yang sesuai.

Untuk memberikan konteks yang lebih mendalam, saya juga menambahkan perbandingan periode. Pengguna dapat melihat bagaimana performa minggu ini dibandingkan dengan minggu lalu, atau bulan ini dibandingkan bulan lalu. Trend naik atau turun ditampilkan dengan ikon panah dan persentase perubahan, membantu keluarga mengidentifikasi pola dan membuat keputusan perawatan yang lebih baik.

Semua data statistik ini dihitung secara efisien di backend menggunakan fungsi agregasi database. Hasil perhitungan di-cache untuk menghindari query berulang yang dapat membebani server. Cache diperbarui otomatis ketika ada perubahan data aktivitas, memastikan statistik yang ditampilkan selalu akurat dan up-to-date.

## 2.7 Lampiran Foto pada Aktivitas

Salah satu fitur yang sangat berguna adalah kemampuan untuk melampirkan foto pada aktivitas. Fitur ini memberikan konteks visual yang sangat membantu pasien Alzheimer, terutama untuk aktivitas yang melibatkan objek atau lokasi tertentu. Misalnya, untuk aktivitas minum obat, keluarga dapat melampirkan foto obat yang harus diminum. Untuk aktivitas berkumpul keluarga, foto lokasi atau foto keluarga dapat dilampirkan.

Implementasi fitur foto dimulai dengan widget pemilih foto yang memungkinkan pengguna untuk memilih hingga lima foto sekaligus dari galeri atau mengambil foto baru dengan kamera. Setiap foto yang dipilih ditampilkan sebagai thumbnail dengan opsi untuk menghapus jika pengguna berubah pikiran sebelum menyimpan.

Setelah foto dipilih, sistem melakukan beberapa langkah pemrosesan. Foto di-resize ke dimensi yang optimal untuk mengurangi ukuran file tanpa mengorbankan kualitas visual yang signifikan. Foto kemudian di-compress menggunakan algoritma yang efisien. Proses ini penting untuk menghemat bandwidth saat upload dan ruang penyimpanan di server.

Foto-foto kemudian diunggah ke Supabase Storage dengan struktur folder yang terorganisir berdasarkan ID aktivitas. Setiap aktivitas memiliki folder sendiri yang berisi semua foto yang dilampirkan. URL foto disimpan di database dalam array, memungkinkan akses cepat ke semua foto aktivitas tersebut.

Di sisi tampilan, foto-foto aktivitas ditampilkan dalam grid yang rapi dengan thumbnail yang dapat diklik. Ketika pengguna mengetuk foto, viewer full-screen terbuka menampilkan foto dalam ukuran penuh dengan kemampuan zoom in dan zoom out menggunakan pinch gesture. Pengguna juga dapat swipe horizontal untuk berpindah antar foto jika ada lebih dari satu foto dilampirkan.

Untuk keluarga, ada opsi tambahan untuk menghapus foto individual dari aktivitas. Ketika foto dihapus, sistem tidak hanya menghapus referensi di database tetapi juga menghapus file fisik dari storage untuk menghindari waste storage. Ini dilakukan dengan aman melalui cascading operation yang memastikan konsistensi data.

Fitur lampiran foto ini juga terintegrasi dengan fitur notifikasi. Ketika notifikasi pengingat aktivitas muncul, jika aktivitas memiliki foto terlampir, foto pertama ditampilkan sebagai gambar thumbnail di notifikasi. Ini memberikan konteks visual langsung kepada pasien tanpa perlu membuka aplikasi terlebih dahulu.
