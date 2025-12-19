# BAB II: PEMBAHASAN FITUR YANG DIKEMBANGKAN

## Bagian 5: Pengenalan Wajah dengan Machine Learning

# 2.15 Sistem Pengenalan Wajah On-Device

Salah satu fitur paling inovatif dari aplikasi AIVIA adalah sistem pengenalan wajah yang membantu pasien Alzheimer mengingat orang-orang terdekat mereka. Fitur ini menggunakan machine learning yang berjalan sepenuhnya di perangkat, menjaga privasi data wajah yang sangat sensitif.

Implementasi dimulai dengan pemilihan teknologi yang tepat. Saya menggunakan kombinasi Google ML Kit untuk deteksi wajah dan TensorFlow Lite untuk ekstraksi fitur wajah. ML Kit menyediakan deteksi wajah yang cepat dan akurat dengan kemampuan mendeteksi landmark wajah seperti mata, hidung, dan mulut. TensorFlow Lite memungkinkan saya menjalankan model neural network yang kompleks dengan efisien di perangkat mobile tanpa memerlukan koneksi internet.

Model yang saya gunakan adalah GhostFaceNet, sebuah model yang dioptimalkan untuk perangkat mobile dengan ukuran kecil namun akurasi tinggi. Model ini menghasilkan embedding vektor berdimensi 512 untuk setiap wajah yang terdeteksi. Embedding ini adalah representasi numerik unik dari wajah yang dapat dibandingkan untuk menentukan kesamaan antar wajah.

Proses pengenalan wajah dimulai dengan deteksi wajah dalam gambar menggunakan ML Kit. Ketika wajah terdeteksi, bounding box dan landmark wajah diidentifikasi. Wajah kemudian di-crop dari gambar asli berdasarkan bounding box dengan margin tertentu untuk memastikan seluruh wajah tercakup. Gambar wajah di-resize ke ukuran yang diharapkan model yaitu 112x112 pixel dan dinormalisasi nilai pixelnya.

Preprocessing yang tepat sangat penting untuk akurasi. Saya mengimplementasikan berbagai teknik preprocessing termasuk alignment wajah berdasarkan landmark mata untuk orientasi yang konsisten, equalization histogram untuk mengatasi variasi pencahayaan, dan normalisasi pixel value ke range yang sesuai untuk model. Preprocessing ini memastikan model menerima input dalam format yang optimal.

Setelah preprocessing, gambar wajah dimasukkan ke model TensorFlow Lite yang menghasilkan embedding vektor. Proses inferensi dilakukan secara asinkron untuk tidak memblokir UI thread, memberikan pengalaman yang smooth kepada pengguna. Embedding yang dihasilkan kemudian disimpan di database bersama dengan informasi orang tersebut.

## 2.16 Manajemen Data Orang yang Dikenal

Untuk sistem pengenalan wajah berfungsi, keluarga perlu terlebih dahulu mendaftarkan orang-orang yang ingin dikenali oleh pasien. Saya membuat antarmuka yang user-friendly untuk proses ini.

Proses pendaftaran dimulai dengan form input yang mengumpulkan informasi tentang orang tersebut. Informasi yang dikumpulkan meliputi nama lengkap yang wajib diisi, hubungan dengan pasien seperti anak, cucu, teman, deskripsi atau bio yang membantu pasien mengingat, dan informasi kontak jika relevan. Form ini memiliki validasi yang memastikan data yang penting tidak kosong dan dalam format yang benar.

Setelah informasi dasar diisi, keluarga perlu mengupload foto wajah orang tersebut. Mereka dapat memilih foto dari galeri atau mengambil foto baru dengan kamera. Ketika foto dipilih, sistem langsung melakukan deteksi wajah untuk memvalidasi bahwa foto mengandung wajah yang jelas. Jika tidak ada wajah terdeteksi atau ada lebih dari satu wajah, sistem memberikan feedback dan meminta pengguna memilih foto yang lebih sesuai.

Jika validasi berhasil, foto diproses untuk menghasilkan embedding wajah. Proses ini mungkin memakan waktu beberapa detik tergantung perangkat, sehingga saya menampilkan loading indicator dengan pesan yang informatif. Setelah embedding dihasilkan, foto diupload ke Supabase Storage dan embedding disimpan di database menggunakan tipe data vector yang didukung oleh ekstensi pgvector.

Database yang menyimpan data orang yang dikenal dirancang untuk query kemiripan vektor yang efisien. Saya membuat index HNSW (Hierarchical Navigable Small World) pada kolom embedding yang memungkinkan pencarian nearest neighbor dengan sangat cepat bahkan dengan dataset yang besar. Index ini adalah kunci dari performa sistem pengenalan yang real-time.

Manajemen data orang yang dikenal menyediakan operasi CRUD yang lengkap. Keluarga dapat melihat daftar semua orang yang terdaftar dengan foto thumbnail dan informasi ringkas, mengedit informasi atau memperbarui foto jika diperlukan, menghapus entry jika orang tersebut tidak lagi relevan, dan mencari orang spesifik dengan nama atau hubungan. Antarmuka ini dirancang dengan card layout yang visual dan mudah navigasi.

Untuk setiap orang yang terdaftar, saya juga menyimpan metadata tambahan seperti frekuensi pengenalan yang mencatat berapa kali pasien mengenali orang tersebut, timestamp pengenalan terakhir, dan akurasi rata-rata pengenalan. Metadata ini berguna untuk analisis dan dapat memberikan insight tentang memori pasien dari waktu ke waktu.

## 2.17 Proses Pengenalan Wajah Real-Time

Di sisi pasien, fitur pengenalan wajah diimplementasikan dengan antarmuka yang sangat sederhana dan intuitif. Pasien membuka layar pengenalan wajah yang langsung menampilkan preview kamera dengan overlay panduan.

Overlay kamera menampilkan area oval sebagai guide dimana pasien harus memposisikan wajah orang yang ingin dikenali. Ada juga teks instruksi dengan font besar dan kontras tinggi yang memberikan panduan langkah demi langkah. Instruksi seperti arahkan kamera ke wajah orang dan pastikan wajah berada dalam frame ditampilkan dengan bahasa yang sangat sederhana.

Deteksi wajah berjalan secara kontinyu pada stream kamera. Setiap frame dianalisis untuk mencari wajah, dan ketika wajah terdeteksi, bounding box ditampilkan di overlay sebagai feedback visual. Ini membantu pasien memastikan wajah sudah terdeteksi dengan baik sebelum mengambil foto.

Tombol capture besar dan berwarna mencolok memungkinkan pasien mengambil foto ketika sudah siap. Setelah foto diambil, preview kamera berhenti dan sistem mulai memproses foto untuk pengenalan. Loading indicator dengan animasi dan pesan yang menenangkan ditampilkan selama proses pengenalan.

Proses pengenalan melibatkan beberapa langkah. Pertama, foto yang diambil dianalisis untuk deteksi wajah. Jika tidak ada wajah terdeteksi, pesan error yang jelas ditampilkan dan pasien diminta mengambil foto ulang. Jika wajah terdeteksi, embedding dihasilkan dari wajah tersebut menggunakan model TensorFlow Lite.

Embedding kemudian dibandingkan dengan semua embedding di database menggunakan vector similarity search. Supabase dengan pgvector sangat efisien untuk operasi ini, mengembalikan wajah yang paling mirip beserta skor kemiripan dalam hitungan milidetik. Jika skor kemiripan melebihi threshold tertentu, misalnya 85 persen, sistem menganggap wajah berhasil dikenali.

Hasil pengenalan ditampilkan dalam layar yang terpisah dengan desain yang sangat jelas. Jika wajah dikenali, layar menampilkan foto orang yang dikenali dari database, nama lengkap dengan font sangat besar, hubungan dengan pasien, bio atau deskripsi yang membantu mengingat, dan skor kepercayaan pengenalan. Semua informasi ini ditampilkan dengan layout yang bersih dan spacing yang generous.

Jika wajah tidak dikenali karena tidak ada match di database atau skor kemiripan terlalu rendah, layar menampilkan pesan yang sopan bahwa wajah tidak dikenali beserta saran untuk meminta keluarga mendaftarkan orang tersebut. Ini mencegah pasien merasa frustasi dan memberikan solusi yang constructive.

Setiap upaya pengenalan, baik berhasil maupun tidak, dicatat dalam log untuk tracking dan analisis. Log mencakup timestamp, pasien yang melakukan pengenalan, hasil pengenalan, skor kemiripan, dan foto yang digunakan jika diperlukan untuk review. Data ini dapat diakses oleh keluarga untuk memahami seberapa sering pasien menggunakan fitur ini dan seberapa efektif fitur ini membantu mereka.

## 2.18 Optimasi dan Akurasi Model

Untuk memastikan sistem pengenalan wajah bekerja dengan baik dalam berbagai kondisi, saya melakukan berbagai optimasi dan improvement.

Handling kondisi pencahayaan yang buruk dilakukan melalui preprocessing yang adaptive. Sistem mendeteksi brightness rata-rata foto dan melakukan adjustment otomatis. Foto yang terlalu gelap di-brightening dengan gamma correction, sementara foto yang terlalu terang di-dimming. Histogram equalization juga diterapkan untuk meningkatkan kontras lokal.

Untuk handling pose wajah yang tidak frontal, saya mengimplementasikan face alignment yang lebih robust. Landmark wajah digunakan untuk menghitung transformasi affine yang merotasi dan scale wajah ke posisi frontal. Ini meningkatkan akurasi secara signifikan ketika pasien mengambil foto dari angle yang tidak optimal.

Occlusion atau sebagian wajah tertutup seperti oleh kacamata atau masker juga dipertimbangkan. Saya melatih model dengan dataset yang mencakup berbagai kondisi occlusion. Meskipun akurasi menurun ketika sebagian besar wajah tertutup, model masih dapat mengenali wajah dengan partial occlusion dengan reasonable accuracy.

Kualitas foto input sangat mempengaruhi akurasi. Untuk itu, saya menambahkan quality check yang menolak foto blur atau yang resolusinya terlalu rendah. Foto di-score berdasarkan sharpness dan resolution, dan hanya foto yang memenuhi threshold minimal yang diproses lebih lanjut. Ini mencegah false recognition yang dapat disebabkan oleh foto berkualitas buruk.

Threshold kemiripan diset berdasarkan extensive testing untuk menyeimbangkan false positive dan false negative. Threshold yang terlalu rendah akan menyebabkan banyak false recognition, sementara threshold terlalu tinggi akan membuat sistem gagal mengenali wajah yang seharusnya dikenali. Saya menemukan bahwa threshold 85 persen memberikan balance yang baik untuk use case aplikasi ini.

Continuous improvement dilakukan dengan mengumpulkan feedback dari penggunaan real. Keluarga dapat memberikan feedback tentang akurasi pengenalan, dan data ini digunakan untuk fine-tuning threshold dan preprocessing parameters. Dalam versi future, feedback ini dapat digunakan untuk retraining model dengan data yang lebih representative dari use case actual.
