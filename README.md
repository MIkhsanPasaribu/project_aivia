# 🧠 AIVIA (Alzheimer Intelligent Virtual Interactive Assistant) - Aplikasi Asisteni Penderita Alzheimer

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)](https://supabase.com/)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-purple.svg)](https://riverpod.dev/)

Aplikasi Android berbasis Flutter yang dirancang sebagai alat bantu khusus untuk anak-anak penderita penyakit Alzheimer. Aplikasi ini menyediakan fitur-fitur keamanan, pengingat aktivitas, pengenalan wajah, dan pelacakan lokasi untuk membantu pasien dan keluarga mereka.

---

## ✨ Fitur Utama

### MVP Phase 1 (✅ Selesai)

- ✅ **Splash Screen** - Animasi smooth dengan logo
- ✅ **Autentikasi** - Login & Register dengan validasi lengkap
- ✅ **Bottom Navigation** - 3 menu untuk Pasien (Beranda, Kenali Wajah, Profil)
- ✅ **Jurnal Aktivitas** - CRUD READ dengan grouping (hari ini/mendatang), pull-to-refresh
- ✅ **Profile Screen** - Informasi user, menu settings, logout
- ✅ **Pallet Warna Terapeutik** - Warna lembut untuk pengguna dengan gangguan kognitif
- ✅ **100+ String Bahasa Indonesia** - UI lengkap dalam bahasa Indonesia
- ✅ **🌙 Dark Mode** - 100% comprehensive dark mode di SEMUA komponen
  - ☀️ Light Mode - Terang & nyaman untuk siang hari
  - 🌙 Dark Mode - Gelap & hemat baterai untuk malam
  - 🔄 Auto Mode - Ikuti pengaturan sistem
  - ✨ Instant switching tanpa restart
  - 🎨 WCAG AAA compliant (contrast 7:1+)
  - ✅ 13+ screens fully theme-aware
  - ✅ 7 widgets theme-compatible
  - ✅ 0 hardcoded colors (verified with flutter analyze)

### Phase 2 (🔜 Upcoming)

- 🔜 Pelacakan Lokasi Background
- 🔜 Tombol Darurat dengan notifikasi
- 🔜 Map View untuk Keluarga
- 🔜 Push Notifications via FCM

### Phase 3 (🔮 Future)

- 🔮 Face Recognition dengan ML
- 🔮 Pengelolaan Orang Dikenal
- 🔮 ML Model Integration (GhostFaceNet)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ^3.9.2
- Dart SDK ^3.9.2
- Android Studio / VS Code dengan Flutter extension
- Supabase Account (gratis di [supabase.com](https://supabase.com))

### Installation

1. **Clone Repository**

   ```bash
   git clone https://github.com/MIkhsanPasaribu/project_aivia.git
   cd project_aivia
   ```

2. **Setup Environment Variables**

   ```bash
   # Windows PowerShell
   Copy-Item .env.example .env

   # Git Bash / Linux / MacOS
   cp .env.example .env
   ```

3. **Edit `.env` dengan Kredensial Supabase Anda**

   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-anon-key
   ENVIRONMENT=development
   ```

4. **Install Dependencies**

   ```bash
   flutter pub get
   ```

5. **Setup Supabase Database**

   - Baca panduan lengkap di [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)
   - Jalankan SQL schema untuk membuat tabel

6. **Run Aplikasi**
   ```bash
   flutter run
   ```

---

## 📁 Struktur Proyek

```
lib/
├── core/
│   ├── config/
│   │   ├── supabase_config.dart    # Konfigurasi Supabase (baca dari .env)
│   │   └── theme_config.dart       # Tema Material Design 3
│   ├── constants/
│   │   ├── app_colors.dart         # Pallet warna terapeutik
│   │   ├── app_strings.dart        # 100+ string Bahasa Indonesia
│   │   ├── app_dimensions.dart     # Spacing, sizes, elevations
│   │   └── app_routes.dart         # Route names
│   └── utils/
│       ├── validators.dart         # Form validators
│       └── date_formatter.dart     # Utility format tanggal Indonesia
│
├── data/
│   ├── models/
│   │   ├── user_profile.dart       # Model User dengan enum Role
│   │   └── activity.dart           # Model Activity lengkap
│   ├── repositories/               # (Coming soon)
│   └── services/                   # (Coming soon)
│
├── presentation/
│   ├── providers/                  # (Coming soon - Riverpod providers)
│   ├── screens/
│   │   ├── splash/
│   │   ├── auth/
│   │   └── patient/
│   └── widgets/                    # (Coming soon)
│
└── main.dart                       # App entry point
```

---

## 🎨 Design System

### Pallet Warna Terapeutik

| Jenis          | Warna         | Hex       | Makna Psikologis                   |
| -------------- | ------------- | --------- | ---------------------------------- |
| **Primary**    | Sky Blue      | `#A8DADC` | Menenangkan, mengurangi kecemasan  |
| **Secondary**  | Soft Green    | `#B7E4C7` | Keseimbangan, kehidupan            |
| **Accent**     | Warm Sand     | `#F6E7CB` | Hangat, rasa aman                  |
| **Text**       | Charcoal Gray | `#333333` | Kontras tinggi, tidak menyilaukan  |
| **Background** | Ivory White   | `#FFFDF5` | Cerah, lembut, tidak membuat lelah |

### Prinsip Desain untuk Pengguna dengan Gangguan Kognitif

- ✅ Font Poppins ukuran minimum 18sp
- ✅ Touch target minimum 48x48dp (aksesibilitas)
- ✅ Warna lembut dan menenangkan
- ✅ Satu fokus per layar
- ✅ Spacing cukup antar elemen (16-24dp)
- ✅ Feedback visual untuk setiap aksi

---

## 🗄️ Database Schema

Aplikasi menggunakan **Supabase (PostgreSQL)** dengan Row Level Security (RLS).

### Tabel Utama:

1. **profiles** - Data profil user (1:1 dengan auth.users)
2. **patient_family_links** - Relasi many-to-many pasien-keluarga
3. **activities** - Jurnal aktivitas harian
4. **known_persons** - Data orang dikenal untuk face recognition (dengan pgvector)
5. **locations** - Tracking lokasi historis (dengan PostGIS)
6. **emergency_alerts** - Log peringatan darurat
7. **emergency_contacts** - Kontak darurat pasien

**Detail Schema:** Lihat [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)

---

## 🔐 Security & Environment

### File `.env` (⚠️ JANGAN COMMIT!)

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
ENVIRONMENT=development
```

File `.env` sudah otomatis di-ignore oleh git untuk keamanan.

**Detail:** Lihat [ENVIRONMENT.md](./ENVIRONMENT.md)

### Row Level Security (RLS)

- ✅ Anon key aman digunakan di client karena RLS
- ✅ User hanya bisa akses data mereka sendiri
- ✅ Family hanya bisa akses data pasien yang di-link
- ✅ Semua tabel protected dengan RLS policies

---

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Widget Tests

```bash
flutter test test/widget/
```

### Integration Tests (Patrol)

```bash
flutter test integration_test/
```

---

## 📚 Dokumentasi

- **[SUPABASE_SETUP.md](./SUPABASE_SETUP.md)** - Panduan setup Supabase lengkap dengan SQL schema
- **[ENVIRONMENT.md](./ENVIRONMENT.md)** - Panduan environment variables & security
- **[MVP_PHASE1_COMPLETED.md](./MVP_PHASE1_COMPLETED.md)** - Progress dan checklist MVP Phase 1
- **[.github/copilot-instructions.md](./.github/copilot-instructions.md)** - Arsitektur lengkap untuk developer

---

## 🛠️ Tech Stack

| Category             | Technology                  |
| -------------------- | --------------------------- |
| **Framework**        | Flutter ^3.9.2              |
| **Language**         | Dart ^3.9.2                 |
| **State Management** | Riverpod 2.6.1              |
| **Backend**          | Supabase (PostgreSQL)       |
| **Database ORM**     | Supabase Dart Client        |
| **Environment**      | flutter_dotenv 5.2.1        |
| **Routing**          | go_router 14.8.1            |
| **Notifications**    | awesome_notifications 0.9.3 |
| **Localization**     | intl 0.19.0 (id_ID)         |

---

## 📱 Screenshots

_(Coming soon - ambil screenshot setelah UI selesai)_

---

## 🤝 Contributing

1. Fork repository ini
2. Buat branch baru (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Team

- **Developer** - [Mikhsan Pasaribu](https://github.com/MIkhsanPasaribu)
- **Assistant** - GitHub Copilot

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Supabase](https://supabase.com/) - Backend platform
- [Riverpod](https://riverpod.dev/) - State management
- [Material Design 3](https://m3.material.io/) - Design system
- Font Poppins dari Google Fonts

---

**Created**: 8 Oktober 2025  
**Version**: 0.1.0  
**Status**: 🚧 In Active Development (MVP Phase 1 Complete)
