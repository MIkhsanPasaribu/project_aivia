# Laporan Progress Pengembangan Aplikasi AIVIA

## Tahap Persiapan Phase 2 (Pre-Phase 2)

**Nama Proyek**: AIVIA (Alzheimer Intelligent Virtual Interactive Assistant) - Aplikasi Asisten Alzheimer  
**Periode**: 11 - 12 Oktober 2025  
**Disusun oleh**: M. Ikhsan Pasaribu  
**Status**: Selesai (100%)

---

## Pendahuluan

Pada tahap ini, saya fokus menyelesaikan berbagai persiapan yang diperlukan sebelum memasuki Phase 2 dari pengembangan aplikasi AIVIA. Phase 2 sendiri merupakan tahapan kritis yang akan mengimplementasikan fitur-fitur inti seperti pelacakan lokasi real-time, sistem darurat, dan visualisasi peta. Oleh karena itu, saya perlu memastikan bahwa semua fondasi infrastruktur sudah siap dan tidak ada yang terlewat.

Tahap Pre-Phase 2 ini saya bagi menjadi empat bagian besar yang saya kerjakan secara bertahap. Setiap bagian memiliki fokus dan tujuan yang berbeda, namun semuanya saling terkait dan mendukung satu sama lain untuk menciptakan fondasi yang kokoh.

---

## Bagian 1: Foundation (Day 1)

### Latar Belakang

Ketika saya mulai mempersiapkan Phase 2, saya menyadari bahwa ada beberapa komponen fundamental yang masih perlu saya lengkapi. Terutama yang berkaitan dengan manajemen profil pengguna dan fitur upload gambar. Ini penting karena nantinya fitur-fitur Phase 2 akan sangat bergantung pada data profil yang lengkap dan akurat.

### Apa yang Saya Kerjakan

#### Sistem Upload Gambar

Saya memulai dengan mengimplementasikan sistem upload gambar yang robust. Ini terdengar sederhana, namun ternyata ada banyak hal yang perlu diperhatikan. Saya harus memastikan bahwa gambar yang diupload tidak terlalu besar (untuk menghemat bandwidth dan storage), memiliki format yang konsisten, dan tentunya aman dari sisi security.

Saya membuat sebuah service khusus yang menangani seluruh proses ini. Service ini bisa mengambil gambar dari kamera atau galeri, melakukan cropping dengan rasio yang konsisten, resize dan compress untuk mengoptimalkan ukuran file, dan akhirnya mengupload ke Supabase Storage. Yang menarik, saya juga mengimplementasikan cleanup otomatis untuk temporary files agar tidak menumpuk di device pengguna.

#### Repository dan Provider untuk Profil

Setelah sistem upload gambar selesai, saya lanjut membuat repository untuk mengelola data profil. Repository ini bertindak sebagai jembatan antara aplikasi dengan database. Saya implementasikan berbagai method yang akan sering digunakan, seperti mengambil data profil, update profil, upload avatar, dan delete avatar.

Untuk state management, saya menggunakan Riverpod yang sudah menjadi standar di project ini. Saya buat beberapa provider yang memudahkan komponen UI untuk mengakses dan memanipulasi data profil secara reaktif. Yang paling penting adalah stream provider yang membuat data profil selalu up-to-date secara real-time.

#### User Interface Edit Profil

Bagian yang paling challenging adalah membuat UI yang user-friendly, terutama mengingat aplikasi ini ditujukan untuk anak-anak dengan Alzheimer. Saya harus memastikan setiap elemen UI cukup besar untuk di-tap, kontras warna yang jelas, dan feedback yang jelas untuk setiap aksi.

Saya buat form edit profil yang mencakup nama lengkap, nomor telepon, tanggal lahir, dan alamat. Untuk avatar, saya buat section khusus yang memudahkan user untuk upload foto dari kamera atau galeri. Setiap input field memiliki validasi real-time, sehingga user langsung tahu jika ada yang salah tanpa harus submit dulu.

### Hasil yang Dicapai

Alhamdulillah, semua task di Day 1 berhasil saya selesaikan. Total saya membuat tujuh komponen baru: dependency installation, image upload service dengan tujuh method, dokumentasi setup Supabase Storage, profile repository dengan tujuh method, profile provider dengan Riverpod, update model UserProfile, dan screen edit profile yang lengkap.

Yang paling memuaskan adalah ketika saya run flutter analyze dan hasilnya nol error. Ini menunjukkan bahwa code yang saya tulis sudah memenuhi standar dan best practices.

---

## Bagian 2: Patient-Family Linking System

### Latar Belakang

Salah satu fitur unik dari aplikasi AIVIA adalah kemampuan untuk menghubungkan akun pasien dengan akun keluarga atau wali. Ini sangat penting karena keluarga perlu bisa memantau aktivitas dan lokasi pasien. Namun, hubungan ini harus dikelola dengan hati-hati, terutama dari sisi permission dan security.

### Apa yang Saya Kerjakan

#### Model dan Repository

Saya mulai dengan membuat model PatientFamilyLink yang merepresentasikan hubungan antara pasien dan keluarga. Model ini tidak hanya menyimpan informasi dasar seperti ID pasien dan ID keluarga, tapi juga menyimpan metadata penting seperti jenis hubungan (anak, orang tua, pasangan, dll), status primary caregiver, dan permission flags.

Permission flags ini sangat krusial. Ada dua jenis permission yang saya implementasikan: permission untuk mengedit aktivitas pasien, dan permission untuk melihat lokasi pasien. Ini memberikan fleksibilitas kepada pasien atau primary caregiver untuk mengontrol siapa saja yang bisa mengakses informasi sensitif.

Repository-nya sendiri saya lengkapi dengan sepuluh method yang mencakup semua operasi CRUD plus beberapa utility method seperti search patient by email dan check permissions.

#### Provider dan Real-time Sync

Yang menarik dari implementasi ini adalah penggunaan Supabase Realtime untuk sinkronisasi data. Ketika ada perubahan pada data linking (misalnya keluarga baru ditambahkan atau permission diubah), perubahan itu langsung ter-reflect di semua device yang terhubung tanpa perlu refresh manual.

Saya buat beberapa provider yang memudahkan UI untuk mengakses data ini. Ada provider untuk list pasien yang linked ke keluarga, provider untuk list keluarga yang linked ke pasien, dan provider untuk manage permissions.

### Hasil yang Dicapai

Tahap ini selesai dengan sempurna. Saya berhasil membuat sistem linking yang secure dan flexible, dengan total enam komponen utama: model PatientFamilyLink dengan delapan property dan support untuk seven relationship types, repository dengan sepuluh method, lima provider dengan real-time sync, dan dokumentasi lengkap.

---

## Bagian 3: Family Dashboard

### Latar Belakang

Setelah sistem linking selesai, saya perlu membuat dashboard khusus untuk keluarga. Dashboard ini akan menjadi hub central dimana keluarga bisa melihat overview semua pasien yang mereka monitor, termasuk aktivitas terbaru dan status.

### Apa yang Saya Kerjakan

#### Desain Dashboard

Saya mulai dengan merancang layout dashboard yang informatif namun tidak overwhelming. Saya gunakan card-based layout dimana setiap pasien ditampilkan dalam sebuah card yang menampilkan informasi penting: foto profil, nama, relationship type, dan quick stats.

Quick stats ini menampilkan jumlah aktivitas hari ini dan last seen location. Ini memberikan gambaran cepat tentang kondisi pasien tanpa harus masuk ke detail screen.

#### Link Patient Screen

Salah satu fitur penting adalah kemampuan untuk link patient baru. Saya buat screen khusus yang memudahkan keluarga untuk mencari pasien berdasarkan email dan melakukan linking. Screen ini memiliki form yang clear dan validasi yang ketat untuk memastikan data yang diinput benar.

Yang perlu saya perhatikan di sini adalah error handling. Misalnya, apa yang terjadi jika email tidak ditemukan? Atau jika patient sudah ter-link sebelumnya? Atau jika yang dicoba di-link ternyata bukan account dengan role patient? Semua skenario ini saya handle dengan message yang jelas dan actionable.

#### Integrasi dengan Navigation

Saya pastikan semua navigation flow berjalan smooth. Dari dashboard, keluarga bisa tap card pasien untuk melihat detail, atau tap tombol "Tambah Pasien" untuk melakukan linking baru. Setiap transition dilengkapi dengan proper animation dan feedback visual.

### Hasil yang Dicapai

Dashboard selesai dengan baik dan semua navigation wiring berfungsi sempurna. Saya berhasil membuat family dashboard screen yang responsive dan informatif, link patient screen dengan validasi lengkap, dan settings screen dengan notification toggle yang persistent.

---

## Bagian 4: Polish dan Finalisasi

### Latar Belakang

Menjelang akhir Pre-Phase 2, saya melakukan review menyeluruh terhadap codebase. Saya menemukan beberapa TODO comments yang perlu diselesaikan dan beberapa widget reusable yang akan sangat membantu development Phase 2.

### Apa yang Saya Kerjakan

#### Menyelesaikan TODO Kritis

Saya identifikasi ada delapan TODO yang tersebar di codebase. Dari delapan itu, enam bersifat critical dan perlu diselesaikan sebelum Phase 2. Dua sisanya bisa di-defer karena bergantung pada dependency external yang belum ready.

TODO pertama yang saya selesaikan adalah auth state check di splash screen. Ini penting agar user yang sudah login tidak perlu login ulang setiap kali buka aplikasi. Saya implementasikan persistent auth menggunakan Supabase session management.

TODO kedua adalah profile realtime subscription. Sebelumnya, profile hanya di-fetch sekali saat app start. Sekarang, profile akan auto-update ketika ada perubahan dari device lain atau dari dashboard web (jika ada).

TODO ketiga dan keempat berkaitan dengan navigation wiring yang masih belum complete. Saya pastikan semua navigation path sudah terhubung dengan benar.

#### Library Widget Reusable

Saya menyadari bahwa ada beberapa pattern UI yang berulang di berbagai screen. Daripada copy-paste code, lebih baik saya buat widget library yang reusable. Ini akan menghemat waktu development dan memastikan consistency UI.

Saya buat enam widget: CustomButton dengan tiga variant (primary, secondary, outline) dan support untuk loading state; CustomTextField dengan validation dan password toggle automatic; LoadingIndicator dengan static method untuk show/hide dialog; CustomErrorWidget untuk menampilkan error state dengan cara yang konsisten; EmptyStateWidget untuk halaman yang tidak memiliki data; dan ConfirmationDialog untuk konfirmasi action yang destructive.

#### Patient Detail Screen

Terakhir, saya buat patient detail screen yang akan digunakan oleh keluarga untuk melihat informasi lengkap tentang pasien. Screen ini menampilkan profile pasien, relationship info, quick actions (panggilan, pesan), recent activities, dan emergency contacts.

Design-nya saya buat dengan sliver app bar yang collapsible, sehingga ketika user scroll, header mengecil dan memberikan lebih banyak space untuk konten. Ini memberikan experience yang modern dan smooth.

### Hasil yang Dicapai

Tahap finalisasi ini selesai dengan sempurna. Total saya membuat delapan file baru dengan lebih dari seribu lima ratus baris code. Yang lebih penting, saya berhasil menyelesaikan enam TODO critical, dan codebase sekarang benar-benar clean tanpa error.

---

## Tantangan yang Dihadapi

### Manajemen State yang Complex

Salah satu tantangan terbesar adalah mengelola state yang semakin complex, terutama untuk relationship antara pasien dan keluarga. Saya harus memastikan bahwa ketika ada perubahan di satu tempat, perubahan itu ter-reflect di semua tempat yang relevan.

Solusinya adalah dengan memanfaatkan Riverpod secara maksimal. Dengan provider pattern dan dependency injection, saya bisa membuat state management yang clean dan maintainable.

### Real-time Synchronization

Implementasi real-time sync dengan Supabase juga memiliki learning curve tersendiri. Saya perlu memahami bagaimana Supabase Realtime bekerja, bagaimana cara subscribe dan unsubscribe dengan benar, dan bagaimana handle edge cases seperti connection loss atau reconnection.

Setelah trial and error, akhirnya saya menemukan pattern yang tepat: menggunakan stream provider dari Riverpod yang secara otomatis handle lifecycle subscription.

### UI/UX untuk Cognitive Impairment

Challenge yang paling meaningful adalah memastikan UI ramah untuk penderita Alzheimer. Saya perlu research tentang accessibility guidelines dan best practices untuk users dengan cognitive impairment.

Beberapa prinsip yang saya terapkan: ukuran touch target minimum empat puluh delapan pixel, spacing yang generous antar elemen, kontras warna yang tinggi, icon yang familiar dan intuitif, dan feedback yang jelas untuk setiap action.

---

## Pembelajaran dan Refleksi

### Technical Skills

Selama tahap Pre-Phase 2 ini, kemampuan technical saya berkembang cukup signifikan. Saya jadi lebih familiar dengan Supabase ecosystem, terutama untuk Storage, Realtime, dan Row Level Security. Saya juga makin confident dengan Flutter state management menggunakan Riverpod.

Yang paling valuable adalah pemahaman saya tentang clean architecture dan separation of concerns. Dengan memisahkan code menjadi layers (model, repository, provider, UI), codebase jadi jauh lebih maintainable dan testable.

### Soft Skills

Dari sisi soft skills, saya belajar pentingnya planning dan documentation. Dengan membuat dokumentasi yang detail di setiap tahap, saya bisa dengan mudah track progress dan identify bottlenecks. Dokumentasi ini juga akan sangat membantu untuk onboarding developer lain jika project ini berkembang.

Saya juga belajar untuk lebih systematic dalam approach problem solving. Ketika menghadapi bug atau error, saya tidak langsung panic atau trial-error random. Saya coba understand root cause-nya dulu, baru kemudian cari solusi yang appropriate.

### Time Management

Estimasi waktu yang saya buat di awal ternyata cukup accurate. Bahkan, di beberapa bagian saya bisa selesai lebih cepat dari estimasi. Ini karena saya sudah mulai familiar dengan codebase dan patterns yang digunakan.

Yang penting, saya belajar untuk tidak multitasking. Fokus menyelesaikan satu task sampai tuntas sebelum pindah ke task berikutnya terbukti lebih efektif.

---

## Kesimpulan

Tahap Pre-Phase 2 ini berhasil saya selesaikan dengan baik. Dari yang awalnya terlihat seperti daftar panjang tasks yang menakutkan, dengan approach yang systematic dan fokus, semuanya bisa diselesaikan step by step.

Total, saya berhasil membuat sebelas file baru dengan lebih dari tiga ribu baris code. Lebih penting dari angka-angka itu, saya berhasil membangun fondasi yang solid untuk Phase 2. Sekarang, aplikasi memiliki sistem profil yang lengkap, sistem linking patient-family yang secure dan flexible, dashboard yang informatif, dan library widget reusable yang akan mempercepat development kedepannya.

Flutter analyze menunjukkan nol error dan nol warning, yang menandakan code quality yang baik. Semua tests yang saya jalankan juga berhasil pass.

Yang paling penting, saya merasa confident untuk melanjutkan ke Phase 2. Fondasi yang sudah dibangun di tahap Pre-Phase 2 ini akan sangat membantu ketika saya implementasi fitur-fitur yang lebih complex seperti background location tracking, real-time map, dan emergency alert system.

---

## Langkah Selanjutnya

Dengan selesainya Pre-Phase 2, saya siap untuk memulai Phase 2 yang akan fokus pada tiga fitur utama:

**Pertama**, background location tracking. Ini adalah fitur yang paling challenging secara technical karena harus bekerja reliable di background, battery efficient, dan comply dengan permission model Android yang cukup strict.

**Kedua**, map visualization. Saya akan implementasi real-time map yang menampilkan lokasi pasien, dengan features seperti markers, trails, dan controls yang intuitif.

**Ketiga**, emergency alert system. Ini adalah fitur yang paling critical dari sisi functionality. Ketika pasien dalam kondisi darurat, keluarga harus bisa segera tahu dan mengambil action.

Phase 2 diperkirakan akan memakan waktu lima hingga tujuh hari kerja. Dengan fondasi yang sudah solid dari Pre-Phase 2, saya optimis bisa menyelesaikannya dengan baik.

---

**Disusun dengan penuh tanggung jawab,**  
Mikhsan Pasaribu  
12 Oktober 2025
