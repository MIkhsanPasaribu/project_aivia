/// String constants untuk aplikasi AIVIA
/// Semua teks UI dalam Bahasa Indonesia untuk aksesibilitas
class AppStrings {
  AppStrings._(); // Private constructor

  // App Info
  static const String appName = 'AIVIA';
  static const String appTagline = 'Asisten untuk Penderita Alzheimer';

  // Auth Screens
  static const String loginTitle = 'Masuk ke Akun Anda';
  static const String registerTitle = 'Daftar Akun Baru';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String fullName = 'Nama Lengkap';
  static const String confirmPassword = 'Konfirmasi Kata Sandi';
  static const String userRole = 'Peran Pengguna';
  static const String loginButton = 'Masuk';
  static const String registerButton = 'Daftar';
  static const String forgotPassword = 'Lupa Kata Sandi?';
  static const String noAccount = 'Belum punya akun?';
  static const String registerHere = 'Daftar di sini';
  static const String haveAccount = 'Sudah punya akun?';
  static const String loginHere = 'Masuk di sini';

  // User Roles
  static const String rolePatient = 'Pasien';
  static const String roleFamily = 'Keluarga/Wali';
  static const String roleAdmin = 'Admin';

  // Navigation - Patient
  static const String navHome = 'Beranda';
  static const String navRecognizeFace = 'Kenali Wajah';
  static const String navProfile = 'Profil';

  // Navigation - Family
  static const String navDashboard = 'Dashboard';
  static const String navLocation = 'Lokasi Pasien';
  static const String navActivities = 'Kelola Aktivitas';
  static const String navKnownPersons = 'Orang Dikenal';

  // Activity Screens
  static const String activityTitle = 'Jurnal Aktivitas';
  static const String addActivity = 'Tambah Aktivitas';
  static const String editActivity = 'Edit Aktivitas';
  static const String activityName = 'Nama Aktivitas';
  static const String activityDescription = 'Deskripsi';
  static const String activityTime = 'Waktu Aktivitas';
  static const String activityDate = 'Tanggal';
  static const String saveActivity = 'Simpan';
  static const String cancelActivity = 'Batal';
  static const String deleteActivity = 'Hapus Aktivitas';
  static const String activityCompleted = 'Selesai';
  static const String activityPending = 'Belum Selesai';
  static const String noActivities = 'Belum ada aktivitas';
  static const String todayActivities = 'Aktivitas Hari Ini';
  static const String upcomingActivities = 'Aktivitas Mendatang';

  // Notifications
  static const String notificationTitle = 'Pengingat Aktivitas';
  static const String notificationBody = 'Saatnya untuk melakukan aktivitas';
  static const String notificationReminder = 'Pengingat: ';

  // Dialogs
  static const String confirmDelete = 'Konfirmasi Hapus';
  static const String confirmDeleteMessage =
      'Apakah Anda yakin ingin menghapus aktivitas ini?';
  static const String yes = 'Ya';
  static const String no = 'Tidak';
  static const String ok = 'OK';
  static const String cancel = 'Batal';

  // Validation Messages
  static const String emailRequired = 'Email harus diisi';
  static const String emailInvalid = 'Format email tidak valid';
  static const String passwordRequired = 'Kata sandi harus diisi';
  static const String passwordTooShort = 'Kata sandi minimal 8 karakter';
  static const String passwordNotMatch = 'Kata sandi tidak cocok';
  static const String nameRequired = 'Nama harus diisi';
  static const String roleRequired = 'Peran harus dipilih';
  static const String activityNameRequired = 'Nama aktivitas harus diisi';
  static const String activityTimeRequired = 'Waktu aktivitas harus diisi';

  // Error Messages
  static const String errorGeneral = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorNetwork = 'Tidak dapat terhubung ke server.';
  static const String errorAuth = 'Email atau kata sandi salah.';
  static const String errorEmailExists = 'Email sudah terdaftar.';
  static const String errorSessionExpired =
      'Sesi Anda telah berakhir. Silakan masuk kembali.';

  // Success Messages
  static const String successLogin = 'Berhasil masuk';
  static const String successRegister = 'Pendaftaran berhasil';
  static const String successLogout = 'Berhasil keluar';
  static const String successActivityAdded = 'Aktivitas berhasil ditambahkan';
  static const String successActivityUpdated = 'Aktivitas berhasil diperbarui';
  static const String successActivityDeleted = 'Aktivitas berhasil dihapus';

  // Loading Messages
  static const String loading = 'Memuat...';
  static const String loggingIn = 'Sedang masuk...';
  static const String registering = 'Sedang mendaftar...';
  static const String saving = 'Menyimpan...';

  // Profile
  static const String profile = 'Profil';
  static const String editProfile = 'Edit Profil';
  static const String logout = 'Keluar';
  static const String logoutConfirm = 'Apakah Anda yakin ingin keluar?';

  // Emergency
  static const String emergency = 'Darurat';
  static const String emergencyButton = 'Tombol Darurat';
  static const String emergencyConfirm =
      'Tekan lama untuk mengirim peringatan darurat';
}
