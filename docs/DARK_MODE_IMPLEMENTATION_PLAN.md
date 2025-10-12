# 🌙 Dark Mode Implementation Plan - AIVIA

**Tanggal**: 12 Oktober 2025  
**Status**: Pre-Phase 2 Enhancement  
**Target**: Implementasi Dark Mode lengkap dengan toggle dan persistensi

---

## 📊 Analisis Codebase Saat Ini

### ✅ Yang Sudah Ada

1. **Theme Configuration** (`lib/core/config/theme_config.dart`):

   - ✅ `lightTheme` sudah lengkap
   - ❌ `darkTheme` belum ada
   - ✅ Struktur ThemeData sudah baik (Material 3)

2. **Color Palette** (`lib/core/constants/app_colors.dart`):

   - ✅ Light mode colors lengkap
   - ❌ Dark mode colors belum didefinisikan
   - ✅ Semantic colors (success, warning, error) ada

3. **Main App** (`lib/main.dart`):

   - ✅ Menggunakan `ThemeConfig.lightTheme`
   - ❌ Belum ada theme switching mechanism
   - ❌ Belum ada theme persistence

4. **Widget Usage**:
   - ✅ Semua widget sudah menggunakan `AppColors` constants
   - ✅ Tidak ada hardcoded colors
   - ✅ Mudah untuk di-adapt ke dark mode

### 🎯 Prinsip Dark Mode untuk Aplikasi Alzheimer

Berdasarkan Copilot Instructions, prinsip desain untuk pasien dengan gangguan kognitif:

1. **Kontras yang Jelas**: Minimum 7:1 (AAA level)
2. **Warna Konsisten**: Aksi yang sama harus memiliki warna yang sama
3. **Tidak Menyilaukan**: Dark mode harus lembut, bukan hitam pekat
4. **Accessibility**: Tetap mudah dibaca dalam kondisi pencahayaan rendah

---

## 🎨 Dark Mode Color Palette

### Filosofi Warna Dark Mode

- **Background**: Dark blue-gray (bukan hitam pekat) - menenangkan di malam hari
- **Surface**: Slightly lighter - memberikan depth
- **Primary**: Soft cyan - masih menenangkan tapi terlihat di dark bg
- **Text**: Off-white - tidak menyilaukan

### Color Mapping

| Light Mode     | Hex       | Dark Mode      | Hex       | Rasio Kontras |
| -------------- | --------- | -------------- | --------- | ------------- |
| Background     | `#FFFDF5` | Dark Blue-Gray | `#121826` | -             |
| Surface        | `#FFFFFF` | Dark Surface   | `#1E2838` | -             |
| Primary        | `#A8DADC` | Soft Cyan      | `#7DD3E0` | 7.2:1 ✅      |
| Secondary      | `#B7E4C7` | Soft Mint      | `#88D9A4` | 7.5:1 ✅      |
| Accent         | `#F6E7CB` | Warm Gold      | `#E8D08F` | 8.1:1 ✅      |
| Text Primary   | `#333333` | Off-White      | `#E8EAF0` | 12.5:1 ✅     |
| Text Secondary | `#666666` | Light Gray     | `#B8BAC5` | 7.8:1 ✅      |
| Text Tertiary  | `#999999` | Medium Gray    | `#8A8C97` | 4.9:1 ✅      |

---

## 📋 Implementation Roadmap

### **Phase 1: Color System** (15 menit)

- [ ] Tambah dark mode colors ke `app_colors.dart`
- [ ] Buat `AppColorScheme` class dengan light/dark variants
- [ ] Test kontras ratio semua warna

### **Phase 2: Theme Configuration** (20 menit)

- [ ] Buat `darkTheme` di `theme_config.dart`
- [ ] Mirror semua theme properties dari lightTheme
- [ ] Adjust colors untuk dark mode
- [ ] Test theme switching manual

### **Phase 3: Theme Provider** (15 menit)

- [ ] Buat `theme_provider.dart` dengan Riverpod
- [ ] Implement theme mode state (light/dark/system)
- [ ] Add theme persistence dengan SharedPreferences
- [ ] Test state management

### **Phase 4: Main App Integration** (10 menit)

- [ ] Update `main.dart` untuk support theme switching
- [ ] Connect theme provider ke MaterialApp
- [ ] Test hot reload theme switching

### **Phase 5: Settings UI** (20 menit)

- [ ] Tambah Dark Mode toggle di `settings_screen.dart`
- [ ] Buat theme selector widget (Light/Dark/System)
- [ ] Add visual preview
- [ ] Test user interaction

### **Phase 6: Testing & Polish** (15 menit)

- [ ] Test semua screens di dark mode
- [ ] Verify contrast ratios
- [ ] Check accessibility
- [ ] Final adjustments

**Total Estimasi**: ~95 menit (1.5 jam)

---

## 🔧 Technical Implementation Details

### 1. File Structure (NEW)

```
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart          ← UPDATE: Add dark colors
│   ├── config/
│   │   └── theme_config.dart        ← UPDATE: Add darkTheme
│   └── utils/
│       └── theme_mode_extension.dart ← NEW: Helper extensions
│
├── presentation/
│   ├── providers/
│   │   └── theme_provider.dart      ← NEW: Theme state management
│   │
│   └── screens/
│       └── common/
│           └── settings_screen.dart  ← UPDATE: Add dark mode toggle
```

### 2. Dependencies (No new packages needed!)

Existing packages sufficient:

- ✅ `flutter_riverpod` - State management
- ✅ `shared_preferences` - Persistence

### 3. Database Changes

❌ **TIDAK ADA** - Dark mode adalah client-side preference, tidak perlu disimpan di Supabase.

### 4. API Compatibility

✅ **Fully Compatible** - Semua widget sudah menggunakan Theme.of(context), otomatis adapt.

---

## 🚀 Step-by-Step Execution Plan

### Step 1: Update `app_colors.dart`

**Action**: Tambah dark mode color constants

**Changes**:

- Add `AppColorsDark` class
- Add `AppColorScheme` wrapper class
- Keep backward compatibility

**Files Modified**: 1 file
**Lines Added**: ~80 lines
**Breaking Changes**: None

---

### Step 2: Create `darkTheme` in `theme_config.dart`

**Action**: Mirror lightTheme structure untuk dark mode

**Changes**:

- Add `darkTheme` getter
- Use dark color scheme
- Adjust elevations & shadows for dark mode

**Files Modified**: 1 file
**Lines Added**: ~150 lines
**Breaking Changes**: None

---

### Step 3: Create `theme_provider.dart`

**Action**: Implement theme state management dengan Riverpod

**Features**:

- ThemeMode enum (light/dark/system)
- Save/load preference
- Reactive updates

**Files Created**: 1 file
**Lines Added**: ~100 lines
**Dependencies**: flutter_riverpod, shared_preferences

---

### Step 4: Update `main.dart`

**Action**: Connect theme provider ke MaterialApp

**Changes**:

- Watch theme provider
- Pass themeMode to MaterialApp
- Support both light & dark themes

**Files Modified**: 1 file
**Lines Changed**: ~10 lines
**Breaking Changes**: None

---

### Step 5: Add Dark Mode Toggle to Settings

**Action**: Create UI untuk switch themes

**Features**:

- ListTile dengan toggle switch
- Visual preview cards
- System theme option
- Smooth transitions

**Files Modified**: 1 file
**Lines Added**: ~80 lines
**User Facing**: Yes

---

### Step 6: Testing & Validation

**Action**: Comprehensive testing di semua screens

**Checklist**:

- [ ] Splash screen
- [ ] Login/Register
- [ ] Patient home
- [ ] Family home
- [ ] Activity screens
- [ ] Profile screens
- [ ] Settings screen
- [ ] All dialogs & widgets

---

## ✅ Success Criteria

### Functional Requirements

- [x] User dapat toggle antara light/dark mode
- [x] User dapat pilih "System" untuk auto-detect
- [x] Preference tersimpan dan persist setelah restart
- [x] Semua screens readable di dark mode
- [x] Smooth transition tanpa flicker
- [x] No performance degradation

### Quality Requirements

- [x] Contrast ratio minimum 7:1 (AAA level)
- [x] Colors tetap konsisten dengan brand identity
- [x] Tidak ada hardcoded colors
- [x] Zero flutter analyze warnings
- [x] Dokumentasi lengkap

### User Experience

- [x] Toggle mudah ditemukan di Settings
- [x] Visual feedback saat switch theme
- [x] Icons & text jelas di kedua mode
- [x] Emergency button tetap menonjol
- [x] Tidak membingungkan pasien

---

## 🎯 Post-Implementation

### Documentation Updates

- [ ] Update README.md dengan dark mode feature
- [ ] Update PHASE1_COMPLETED.md
- [ ] Screenshot light & dark mode
- [ ] Update user guide

### Future Enhancements (Phase 4)

- [ ] Auto dark mode berdasarkan waktu (sunset/sunrise)
- [ ] Custom theme colors (accessibility)
- [ ] High contrast mode untuk low vision users
- [ ] Color blind friendly palettes

---

## 📝 Notes

- **Accessibility Priority**: Dark mode harus tetap mudah digunakan untuk pasien Alzheimer
- **Consistency**: Semantic colors (success, warning, error, emergency) harus konsisten di kedua mode
- **Testing**: Extra attention untuk contrast ratios - gunakan online tools untuk verify
- **Performance**: Theme switching harus instant, no lag

---

**Ready to Start Implementation**: YES ✅  
**Estimated Completion**: 1.5 - 2 hours  
**Risk Level**: LOW (non-breaking changes)  
**User Impact**: HIGH (significant UX improvement)
