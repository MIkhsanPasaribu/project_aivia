# 🔐 Environment Variables - AIVIA

## 📋 File Structure

```
project_aivia/
├── .env                 # ❌ JANGAN COMMIT! Kredensial asli
├── .env.example         # ✅ Template untuk tim
└── .gitignore           # ✅ .env sudah ada di sini
```

---

## 🚀 Quick Start

### 1. Copy Template
```bash
# Untuk Windows PowerShell
Copy-Item .env.example .env

# Untuk Git Bash / Linux / MacOS
cp .env.example .env
```

### 2. Edit `.env`
Buka file `.env` dan isi dengan kredensial Supabase Anda:

```env
SUPABASE_URL=https://your-actual-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-actual-anon-key
ENVIRONMENT=development
```

### 3. Jangan Commit!
File `.env` sudah otomatis di-ignore oleh git.

**Check dengan:**
```bash
git status
```

Pastikan `.env` **TIDAK MUNCUL** di list file yang akan di-commit.

---

## 📝 Environment Variables

| Variable | Deskripsi | Wajib? | Example |
|----------|-----------|--------|---------|
| `SUPABASE_URL` | URL project Supabase | ✅ Ya | `https://abc123.supabase.co` |
| `SUPABASE_ANON_KEY` | Public anon key Supabase | ✅ Ya | `eyJhbGciOi...` |
| `ENVIRONMENT` | Mode aplikasi | ❌ Opsional | `development` / `production` |

---

## 🔒 Security Best Practices

### ✅ DO (Lakukan)
- Simpan kredensial di `.env`
- Commit `.env.example` sebagai template
- Share kredensial via secure channel (LastPass, 1Password, etc.)
- Gunakan project Supabase berbeda untuk dev/prod

### ❌ DON'T (Jangan)
- Commit file `.env` ke git
- Hardcode kredensial di code
- Share kredensial via chat/email tanpa enkripsi
- Gunakan production credentials untuk development

---

## 🔄 Untuk Tim Development

### Onboarding Developer Baru

1. Clone repository:
   ```bash
   git clone https://github.com/MIkhsanPasaribu/project_aivia.git
   cd project_aivia
   ```

2. Copy template environment:
   ```bash
   Copy-Item .env.example .env
   ```

3. Minta kredensial dari team lead (via secure channel)

4. Isi file `.env` dengan kredensial yang diberikan

5. Install dependencies:
   ```bash
   flutter pub get
   ```

6. Run aplikasi:
   ```bash
   flutter run
   ```

---

## 🏗️ Development vs Production

### Development Environment
```env
SUPABASE_URL=https://dev-project.supabase.co
SUPABASE_ANON_KEY=eyJ...dev-anon-key...
ENVIRONMENT=development
```

### Production Environment
```env
SUPABASE_URL=https://prod-project.supabase.co
SUPABASE_ANON_KEY=eyJ...prod-anon-key...
ENVIRONMENT=production
```

**Cara switch:**
1. Ganti value di `.env`
2. Stop aplikasi
3. Run ulang: `flutter run`

---

## 🧪 Testing

### Check Environment Loading
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  
  print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
  print('ENVIRONMENT: ${dotenv.env['ENVIRONMENT']}');
}
```

### Test Supabase Connection
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void testConnection() async {
  final supabase = Supabase.instance.client;
  
  // Test simple query
  final response = await supabase.from('profiles').select().limit(1);
  print('Connection OK: $response');
}
```

---

## 🚨 Troubleshooting

### Error: "Failed to load .env"
**Penyebab:** File `.env` tidak ada atau tidak di-load
**Solusi:**
```bash
# Check apakah file .env ada
ls -la .env

# Jika tidak ada, copy dari template
Copy-Item .env.example .env
```

### Error: "SUPABASE_URL tidak ditemukan"
**Penyebab:** Variable tidak di-set di `.env`
**Solusi:** 
- Buka `.env`
- Pastikan ada baris: `SUPABASE_URL=https://...`
- Tidak ada typo di nama variable

### Error: "Invalid API key"
**Penyebab:** Anon key salah atau expired
**Solusi:**
- Check anon key di Supabase Dashboard > Settings > API
- Copy ulang dengan benar (jangan ada spasi atau newline)

---

## 📚 References

- [flutter_dotenv Documentation](https://pub.dev/packages/flutter_dotenv)
- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [12 Factor App - Config](https://12factor.net/config)

---

**Last Updated:** 8 Oktober 2025  
**Maintainer:** Development Team
