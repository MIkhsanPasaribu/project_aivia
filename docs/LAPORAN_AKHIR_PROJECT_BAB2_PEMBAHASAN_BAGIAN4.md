# BAB II: PEMBAHASAN FITUR YANG DIKEMBANGKAN

## Bagian 4: Geofencing dan Arsitektur Offline-First

# 2.12 Sistem Geofencing

Geofencing merupakan fitur keamanan proaktif yang memungkinkan keluarga untuk mendefinisikan zona-zona geografis tertentu dan menerima peringatan otomatis ketika pasien masuk atau keluar dari zona tersebut. Fitur ini sangat berguna untuk mencegah situasi berbahaya dan memberikan ketenangan pikiran bagi keluarga.

Implementasi geofencing dimulai dengan model data yang menyimpan informasi zona. Setiap zona geofence memiliki nama yang deskriptif, koordinat pusat lingkaran zona, radius dalam meter yang mendefinisikan ukuran zona, jenis zona seperti safe zone atau restricted zone, status aktif atau tidak, dan metadata tambahan seperti deskripsi dan catatan khusus. Struktur data ini disimpan di database dengan dukungan query geospasial menggunakan ekstensi PostGIS.

Untuk membuat zona baru, keluarga menggunakan antarmuka yang intuitif. Mereka dapat memilih lokasi dengan cara mengetuk di peta, menggunakan lokasi saat ini, atau memasukkan alamat yang akan di-geocode menjadi koordinat. Setelah pusat zona ditentukan, keluarga dapat menyesuaikan radius dengan menggunakan slider yang menampilkan lingkaran overlay di peta secara real-time. Ini memberikan feedback visual langsung tentang area yang akan dicover oleh zona tersebut.

Saya mengimplementasikan berbagai jenis zona dengan perilaku yang berbeda. Safe zone memberikan notifikasi ketika pasien keluar dari zona, berguna untuk area rumah atau tempat aman lainnya. Alert zone memberikan notifikasi ketika pasien masuk ke zona, berguna untuk area yang berbahaya seperti jalan raya atau tempat ramai. Silent zone tidak memberikan notifikasi sama sekali, berguna untuk temporary override sistem geofencing di lokasi tertentu.

Deteksi event geofence dilakukan secara efisien di backend menggunakan query geospasial. Setiap kali ada update lokasi baru dari pasien, sistem mengecek apakah lokasi tersebut berada dalam atau di luar zona yang telah didefinisikan. Jika terjadi transisi yakni pasien masuk atau keluar dari zona sistem membuat record event dan memicu notifikasi sesuai konfigurasi zona.

Event geofence dicatat dengan detail lengkap untuk audit dan analisis. Log mencakup informasi zona yang terkena, jenis event seperti enter atau exit, lokasi koordinat ketika event terjadi, timestamp yang presisi, durasi waktu pasien berada di dalam zona untuk exit event, dan metadata tambahan yang mungkin relevan. Log ini dapat diakses melalui antarmuka riwayat event dengan berbagai filter dan pencarian.

Notifikasi geofence dirancang untuk memberikan informasi yang cukup tanpa overwhelming keluarga. Ketika pasien keluar dari safe zone, notifikasi menampilkan nama zona, waktu event, lokasi terakhir pasien, dan tombol quick action untuk melihat peta atau menelepon pasien. Prioritas notifikasi dapat dikonfigurasi per zona, dengan zona kritis mendapat prioritas tertinggi yang memastikan notifikasi muncul bahkan dalam mode tidak mengganggu.

Untuk mencegah spam notifikasi, saya mengimplementasikan cooldown mechanism. Setelah event geofence trigger, sistem tidak akan mengirim notifikasi lagi untuk zona yang sama dalam periode tertentu, misalnya lima menit. Ini menghindari skenario dimana pasien berada di perbatasan zona dan terus masuk keluar yang akan menghasilkan notifikasi berulang yang mengganggu.

Manajemen zona geofence melalui antarmuka yang komprehensif. Keluarga dapat melihat daftar semua zona yang telah dibuat dengan informasi ringkas, mengedit zona yang sudah ada termasuk mengubah radius atau jenis, menonaktifkan zona sementara tanpa menghapusnya, menghapus zona yang tidak lagi diperlukan, dan duplikasi zona untuk membuat zona serupa di lokasi berbeda. Semua operasi ini dilakukan dengan konfirmasi yang sesuai untuk mencegah perubahan tidak sengaja.

Visualisasi zona di peta menggunakan lingkaran semi-transparan dengan warna yang sesuai jenisnya. Safe zone berwarna hijau, alert zone berwarna merah, dan silent zone berwarna abu-abu. Label nama zona ditampilkan di tengah lingkaran dengan font yang jelas. Zona yang sedang tidak aktif ditampilkan dengan opacity lebih rendah untuk membedakannya dari zona aktif.

## 2.13 Arsitektur Offline-First

Mengingat target pengguna aplikasi yang mungkin berada di area dengan konektivitas internet yang tidak stabil, saya mengimplementasikan arsitektur offline-first yang memastikan aplikasi tetap fungsional tanpa koneksi internet. Data penting di-cache secara lokal dan operasi yang memerlukan koneksi server di-queue untuk diproses ketika koneksi tersedia kembali.

Untuk storage lokal, saya menggunakan kombinasi beberapa teknologi. Sqflite untuk data terstruktur seperti aktivitas dan kontak yang perlu query kompleks, Shared Preferences untuk pengaturan dan preferensi user yang simple key-value, dan Hive untuk cache data yang perlu akses cepat dengan struktur yang fleksibel. Kombinasi ini memberikan fleksibilitas dan performa yang optimal untuk berbagai jenis data.

Sistem queue offline menggunakan database sqflite untuk menyimpan operasi yang pending. Setiap operasi yang gagal karena koneksi disimpan sebagai entry di tabel queue dengan informasi tentang jenis operasi, data payload yang di-serialize, timestamp operasi, jumlah retry yang sudah dilakukan, dan status saat ini. Queue ini diproses secara otomatis ketika aplikasi mendeteksi koneksi internet kembali tersedia.

Saya mengimplementasikan retry mechanism dengan exponential backoff. Operasi yang gagal tidak langsung di-retry, tetapi menunggu periode tertentu yang meningkat eksponensial dengan setiap kegagalan. Misalnya, retry pertama setelah satu menit, kedua setelah dua menit, ketiga setelah empat menit, dan seterusnya. Ini mencegah aplikasi membanjiri server dengan request retry ketika baru kembali online.

Untuk data lokasi, implementasi offline sangat krusial. Ketika koneksi terputus, data lokasi tetap dikumpulkan dan disimpan di database lokal. Queue khusus menangani upload batch lokasi untuk efisiensi. Ketika koneksi tersedia, sistem mengupload data lokasi dalam batch besar dengan timestamp yang presisi, memastikan riwayat lokasi tetap lengkap tanpa gap.

Conflict resolution menjadi pertimbangan penting dalam arsitektur offline-first. Untuk menghindari konflik data, saya menggunakan strategi last-write-wins untuk data profil dan pengaturan, merge strategy untuk data aktivitas dimana perubahan dari berbagai sumber di-merge berdasarkan timestamp, dan versioning untuk data kritis yang memerlukan resolusi konflik manual. Strategi ini dipilih berdasarkan karakteristik dan kepentingan masing-masing jenis data.

Indikator status koneksi ditampilkan dengan jelas di aplikasi. Banner kecil muncul di bagian atas layar ketika aplikasi dalam mode offline, menginformasikan pengguna bahwa beberapa fitur mungkin terbatas dan data akan disinkronkan ketika koneksi tersedia. Banner ini tidak invasive tetapi cukup visible untuk memberikan awareness kepada pengguna tentang status koneksi.

Sinkronisasi data dilakukan secara cerdas untuk menghemat bandwidth dan baterai. Sistem hanya menyinkronkan data yang berubah sejak sinkronisasi terakhir menggunakan timestamp comparison. Data besar seperti foto di-upload dengan prioritas lebih rendah dibanding data kritis seperti alert darurat. User dapat mengonfigurasi untuk hanya menyinkronkan melalui WiFi untuk menghemat kuota data cellular.

Untuk memberikan feedback kepada pengguna, saya mengimplementasikan sync progress indicator. Ketika sinkronisasi berjalan, indikator menampilkan jumlah item yang pending upload, progress persentase, dan estimasi waktu tersisa. User dapat memilih untuk membatalkan sinkronisasi jika diperlukan, dengan operasi yang sudah berhasil tetap tersimpan dan yang belum akan di-retry di kesempatan berikutnya.

## 2.14 Optimasi Database dan Performa

Dengan data lokasi yang terus bertambah setiap waktu, optimasi database menjadi sangat penting untuk menjaga performa aplikasi. Saya mengimplementasikan berbagai strategi optimasi yang memastikan aplikasi tetap responsif bahkan dengan dataset yang besar.

Indexing yang proper adalah fondasi dari performa query yang baik. Saya membuat index pada kolom-kolom yang sering digunakan untuk filtering dan sorting seperti patient_id, timestamp, dan status. Untuk query geospasial, saya menggunakan GIST index yang dioptimalkan untuk tipe data geography PostGIS. Index ini membuat query yang melibatkan perhitungan jarak dan containment menjadi jauh lebih cepat.

Clustering data lokasi berdasarkan waktu dan koordinat mengurangi ukuran dataset tanpa kehilangan informasi penting. Data lokasi yang sangat dekat satu sama lain dalam waktu singkat di-cluster menjadi satu titik representatif dengan metadata agregat. Ini mengurangi jumlah row di database sekaligus mempercepat query dan rendering di peta.

Data retention policy memastikan database tidak terus membesar tanpa batas. Data lokasi yang lebih lama dari tiga bulan otomatis dipindahkan ke tabel arsip atau dihapus sesuai konfigurasi. Sebelum dihapus, statistik agregat dihitung dan disimpan untuk mempertahankan informasi historis tanpa perlu menyimpan data raw yang detail. Policy ini berjalan otomatis melalui scheduled job yang dikelola oleh pg_cron di database.

Query optimization dilakukan dengan berbagai teknik. Saya menggunakan query yang efisien dengan projection yang spesifik hanya memilih kolom yang diperlukan, pagination untuk dataset besar mencegah loading data yang tidak perlu, dan prepared statements untuk query yang sering digunakan mengurangi parsing overhead. Setiap query kritis di-profile untuk memastikan execution plan yang optimal.

Caching di level aplikasi mengurangi roundtrip ke database. Data yang tidak sering berubah seperti zona geofence dan profil user di-cache di memori dengan invalidation strategy yang tepat. Cache ini diperbarui secara reaktif ketika ada perubahan data, memastikan user selalu melihat data yang akurat tanpa perlu query database setiap saat.

Untuk analitik dan reporting, saya membuat materialized views yang menyimpan hasil query agregat yang kompleks. Views ini di-refresh secara periodic, memberikan akses cepat ke statistik tanpa perlu menghitung ulang setiap kali diakses. Ini sangat penting untuk dashboard yang menampilkan berbagai metrik dan chart.

Background processing untuk tugas-tugas heavy seperti clustering lokasi dan perhitungan statistik dilakukan di server menggunakan background workers. Ini memastikan operasi tersebut tidak mempengaruhi responsiveness aplikasi mobile dan dapat memanfaatkan resource server yang lebih powerful. Hasil processing kemudian disinkronkan kembali ke aplikasi secara asinkron.
