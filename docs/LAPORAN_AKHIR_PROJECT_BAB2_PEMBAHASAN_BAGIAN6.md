# BAB II: PEMBAHASAN FITUR YANG DIKEMBANGKAN

## Bagian 6: Tema Gelap, Dukungan Multibahasa, dan Sistem Chat

# 2.19 Implementasi Tema Gelap

Tema gelap bukan hanya soal estetika, tetapi merupakan fitur penting yang meningkatkan kenyamanan pengguna dalam berbagai kondisi pencahayaan dan membantu menghemat baterai pada perangkat dengan layar OLED. Implementasi tema gelap di AIVIA dirancang dengan sangat hati-hati mengingat karakteristik pengguna aplikasi.

Desain palet warna untuk tema gelap mempertimbangkan banyak aspek. Saya tidak hanya membalik warna dari tema terang, tetapi merancang skema warna yang secara khusus dioptimalkan untuk mode gelap. Warna background menggunakan abu-abu gelap bukan hitam murni untuk mengurangi kontras yang terlalu ekstrem dan mata lelah. Warna teks menggunakan putih dengan sedikit keabu-abuan untuk memberikan kontras yang cukup tanpa menyilaukan.

Setiap warna dalam palet diuji untuk memastikan rasio kontras memenuhi standar aksesibilitas WCAG. Untuk teks normal, rasio kontras minimal 4.5:1, sementara untuk teks besar minimal 3:1. Testing dilakukan menggunakan tools otomatis dan manual untuk berbagai kombinasi warna foreground dan background yang digunakan di aplikasi.

Implementasi teknis menggunakan ThemeData dari Flutter dengan dukungan penuh untuk Material Design 3. Saya membuat dua ThemeData yang terpisah, satu untuk tema terang dan satu untuk tema gelap, dengan setiap komponen UI dikonfigurasi secara eksplisit. Ini memastikan konsistensi visual di seluruh aplikasi dan memudahkan maintenance di masa mendatang.

Switching antara tema dilakukan dengan smooth transition. Saya menggunakan AnimatedTheme yang memberikan animasi fade ketika tema berubah, membuat transisi terasa natural dan tidak jarring. State tema disimpan di local storage sehingga preferensi pengguna diingat antar sesi aplikasi.

Selain manual switching, aplikasi juga mendukung tema otomatis yang mengikuti pengaturan sistem. Pada Android 10 ke atas, pengguna dapat mengatur tema di level sistem operasi, dan aplikasi akan otomatis mengikuti preferensi tersebut kecuali pengguna secara eksplisit memilih tema tertentu di aplikasi. Ini memberikan pengalaman yang konsisten dengan aplikasi lain di perangkat.

Komponen-komponen khusus seperti peta dan chart juga disesuaikan untuk tema gelap. Tile peta menggunakan style gelap ketika tema gelap aktif, memastikan peta tidak terlalu terang dan konsisten dengan sisa aplikasi. Chart menggunakan palet warna yang disesuaikan dengan background yang lebih gelap namun tetap mempertahankan kemampuan untuk membedakan data series.

Untuk pasien Alzheimer yang mungkin tidak familiar dengan konsep tema, saya membuat toggle yang sangat visual. Alih-alih hanya text switch, toggle menampilkan ikon matahari untuk tema terang dan bulan untuk tema gelap dengan preview warna yang jelas. Ini membuat pilihan lebih intuitif dan mudah dipahami.

## 2.20 Dukungan Multibahasa

Mengingat target pengguna di Indonesia tetapi juga kemungkinan ekspansi ke pasar lain, saya mengimplementasikan dukungan multibahasa yang robust. Aplikasi saat ini mendukung Bahasa Indonesia dan Bahasa Inggris dengan arsitektur yang memudahkan penambahan bahasa lain di masa mendatang.

Implementasi menggunakan sistem lokalisasi Flutter yang official yaitu flutter_localizations. Semua string yang ditampilkan ke pengguna didefinisikan dalam file ARB (Application Resource Bundle) untuk setiap bahasa yang didukung. File-file ini berisi pasangan key-value dimana key adalah identifier unik dan value adalah teks dalam bahasa tersebut.

Proses development lokalisasi dimulai dengan ekstraksi semua hardcoded string dari kode dan menggantinya dengan pemanggilan ke lokalisasi API. Setiap string yang perlu ditampilkan menggunakan pattern context.l10n.stringKey dimana l10n adalah extension method yang saya buat untuk mengakses AppLocalizations dengan lebih concise.

File ARB untuk Bahasa Indonesia mencakup lebih dari tiga ratus string yang mencakup semua teks di aplikasi. Dari label button, judul layar, pesan error, hingga konten dialog dan notifikasi, semuanya didefinisikan dengan clear context sehingga mudah dipahami oleh translator. Setiap entry juga dilengkapi dengan deskripsi dan contoh penggunaan untuk memastikan terjemahan yang akurat.

Untuk string yang memerlukan parameter dinamis seperti nama pengguna atau angka, saya menggunakan placeholder yang didefinisikan dalam ARB. Misalnya untuk pesan dengan nama pengguna bisa didefinisikan sebagai halo {name} selamat datang. System lokalisasi akan otomatis replace placeholder dengan nilai actual ketika string ditampilkan.

Plural dan conditional string juga di-handle dengan proper menggunakan ICU message format. Misalnya untuk menampilkan jumlah aktivitas, string bisa berbeda tergantung apakah nol, satu, atau banyak aktivitas. Format ICU memungkinkan definisi yang elegant untuk case-case ini dalam setiap bahasa.

Switching bahasa dilakukan melalui menu pengaturan dengan pilihan yang jelas. Setiap bahasa ditampilkan dalam bahasa itu sendiri misalnya Indonesia untuk Bahasa Indonesia dan English untuk Bahasa Inggris sehingga pengguna dapat memilih bahasa mereka bahkan jika mereka belum memahami bahasa yang sedang aktif. Perubahan bahasa langsung tereffect di seluruh aplikasi tanpa perlu restart.

Preferensi bahasa disimpan di local storage dan dimuat ketika aplikasi dibuka. Selain itu, aplikasi juga dapat otomatis memilih bahasa berdasarkan locale sistem pengguna. Jika bahasa sistem didukung oleh aplikasi, bahasa tersebut otomatis dipilih sebagai default, memberikan pengalaman out-of-the-box yang baik.

Testing lokalisasi dilakukan dengan menggunakan pseudo-locales untuk mendeteksi string yang belum dilokalisasi. Saya juga melakukan manual testing dengan switching bahasa di berbagai layar untuk memastikan tidak ada layout issue yang disebabkan oleh perbedaan panjang teks antar bahasa. Beberapa adjustment pada layout diperlukan untuk mengakomodasi bahasa dengan teks yang lebih panjang.

## 2.21 Sistem Chat Real-Time

Komunikasi adalah aspek penting dalam perawatan pasien Alzheimer. Untuk memfasilitasi ini, saya mengimplementasikan sistem chat in-app yang memungkinkan pasien dan keluarga berkomunikasi dengan mudah. Chat ini terintegrasi dengan sistem notifikasi untuk memastikan pesan tidak terlewat.

Implementasi chat menggunakan Supabase Realtime yang memberikan capability untuk streaming data changes secara real-time. Setiap kali pesan baru dikirim, semua client yang terhubung ke room chat langsung menerima update tanpa perlu polling. Ini memberikan pengalaman chat yang responsive seperti aplikasi messaging populer.

Data model chat dirancang dengan dua entity utama yaitu chat rooms dan messages. Chat room merepresentasikan conversation antara dua atau lebih pengguna dengan metadata seperti participants, last message, unread count, dan timestamp. Messages berisi konten pesan, sender info, timestamp, read status, dan referensi ke room yang memilikinya.

Antarmuka chat list menampilkan semua conversation yang dimiliki pengguna. Setiap conversation ditampilkan sebagai card dengan informasi penting seperti foto profil participant lain, nama participant, preview pesan terakhir, timestamp dalam format relative seperti dua menit yang lalu, dan badge unread count jika ada pesan yang belum dibaca. List di-sort berdasarkan timestamp pesan terakhir sehingga conversation paling aktif muncul di atas.

Ketika pengguna membuka conversation, mereka masuk ke chat room screen yang menampilkan riwayat pesan dalam format bubble chat yang familiar. Pesan dari pengguna sendiri ditampilkan di sebelah kanan dengan warna berbeda, sementara pesan dari participant lain di sebelah kiri. Setiap bubble menampilkan konten pesan, timestamp, dan status read untuk pesan yang dikirim pengguna.

Input field untuk mengirim pesan dirancang dengan ergonomis. Field text terletak di bottom screen dengan tombol send yang besar dan jelas. Field ini expand secara otomatis ketika pengguna menulis pesan yang panjang, memberikan ruang yang cukup tanpa menutupi riwayat chat. Tombol send hanya enabled ketika ada teks yang diinput, mencegah pengiriman pesan kosong.

Typing indicator memberikan feedback real-time ketika participant lain sedang mengetik. Ini menggunakan presence tracking dari Supabase Realtime yang mendeteksi ketika pengguna aktif di input field. Indicator ditampilkan sebagai animated dots dengan nama participant yang sedang typing.

Status online ditampilkan untuk setiap participant menggunakan dot indicator kecil di samping foto profil. Hijau untuk online, abu-abu untuk offline. Status ini juga menggunakan presence tracking yang update secara real-time. Last seen timestamp ditampilkan ketika user offline, memberikan context kapan terakhir kali mereka aktif.

Notifikasi push dikirim untuk pesan baru ketika penerima tidak sedang aktif di aplikasi. Notifikasi ini memiliki prioritas tinggi dan menampilkan nama sender dan preview konten pesan. Ketika notifikasi di-tap, aplikasi langsung membuka conversation yang relevan. Untuk melindungi privasi, konten pesan tidak ditampilkan di lock screen jika pengguna mengaktifkan private notifications.

Fitur additional seperti send photo belum diimplementasikan di versi saat ini untuk menjaga kesederhanaan, tetapi arsitektur sudah dirancang untuk mendukung berbagai tipe pesan di masa mendatang. Database schema memiliki field message type yang dapat diextend untuk mendukung images, voice notes, atau location sharing.

Untuk pasien yang mungkin kesulitan mengetik, saya berencana menambahkan voice-to-text di versi mendatang. Ini akan menggunakan speech recognition API native platform untuk mengkonversi ucapan menjadi teks yang bisa dikirim sebagai pesan. Fitur ini akan sangat membantu pasien yang kesulitan dengan keyboard virtual.

## 2.22 Manajemen Notifikasi dan Status Online

Sistem notifikasi terintegrasi di seluruh aplikasi memastikan pengguna selalu informed tentang event penting. Setiap jenis notifikasi dikonfigurasi dengan prioritas dan behavior yang sesuai dengan tingkat urgency informasi.

Notifikasi dikategorikan dalam beberapa channel Android untuk memberikan kontrol granular kepada pengguna. Ada channel untuk activity reminders, emergency alerts, geofence events, chat messages, dan system notifications. Setiap channel dapat dikonfigurasi independently oleh pengguna termasuk sound, vibration, dan visibility.

Histori notifikasi tersimpan di database dan dapat diakses melalui layar khusus. Pengguna dapat melihat semua notifikasi yang pernah diterima, filter berdasarkan kategori atau tanggal, search notifikasi spesifik, dan clear individual atau bulk notifikasi. Ini memberikan transparansi dan control yang lebih baik atas notifikasi.

Untuk mengoptimalkan pengiriman notifikasi push, saya mengimplementasikan FCM token management yang robust. Setiap perangkat yang login mendaftarkan token FCM-nya ke database dengan metadata seperti device model, OS version, dan app version. Ketika notifikasi perlu dikirim, sistem query semua token untuk user tersebut dan mengirim ke semua perangkat mereka.

Status online tracking memungkinkan pengguna melihat apakah family member mereka sedang aktif di aplikasi. Ini menggunakan Supabase Realtime presence yang efficient dan scalable. Ketika user membuka aplikasi, presence mereka di-broadcast ke channel shared dengan connected users. Ketika aplikasi ditutup atau connection lost, presence otomatis di-remove setelah timeout period.

Optimasi dilakukan untuk mengurangi false offline status. Saya mengimplementasikan heartbeat mechanism yang periodically update presence timestamp. Ini memastikan status tetap akurat bahkan ketika user idle di aplikasi. Timeout dikonfigurasi dengan balance antara accuracy dan overhead network.
