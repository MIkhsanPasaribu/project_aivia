# ML Models Directory

## GhostFaceNet Model

**Status**: ⚠️ **MODEL FILE BELUM ADA**

### How to Download

#### Option 1: Official Repository (Recommended)

```bash
# Clone repository
git clone https://github.com/HuangJunJie2017/GhostFaceNets

# Copy model file
cp GhostFaceNets/model/ghostfacenet.tflite assets/ml_models/
```

#### Option 2: Direct Download

Download dari salah satu sumber ini:

- **GitHub Releases**: https://github.com/HuangJunJie2017/GhostFaceNets/releases
- **TensorFlow Hub**: https://tfhub.dev/ (search "GhostFaceNet")
- **Google Drive**: [Link akan di-share oleh team]

#### Option 3: Alternative Models

Jika GhostFaceNet tidak tersedia, gunakan alternatif:

**MobileFaceNet** (Lighter, 99.0% accuracy)

- Size: ~4MB
- Input: 112x112 RGB
- Output: 128-dim embedding
- Download: https://github.com/sirius-ai/MobileFaceNet_TF

**FaceNet** (Highest accuracy, larger)

- Size: ~23MB
- Input: 160x160 RGB
- Output: 512-dim embedding
- Download: https://github.com/davidsandberg/facenet

### Expected File

```
assets/ml_models/ghostfacenet.tflite
```

**File Specifications**:

- Size: ~5MB
- Format: TensorFlow Lite (.tflite)
- Input Shape: [1, 112, 112, 3] (NHWC format)
- Output Shape: [1, 512] (face embedding)
- Type: float32

### Verification

After downloading, verify the file:

```bash
# Check file exists
Test-Path assets\ml_models\ghostfacenet.tflite

# Check file size (should be ~5MB)
(Get-Item assets\ml_models\ghostfacenet.tflite).Length / 1MB

# Expected output: ~5.0
```

### Integration Status

- [x] Directory created
- [x] pubspec.yaml updated with asset path
- [ ] **MODEL FILE NOT DOWNLOADED YET** ⚠️
- [ ] TFLite loading code ready (implemented below)
- [ ] Testing pending model download

### Next Steps

1. Download model menggunakan salah satu option di atas
2. Place file di `assets/ml_models/ghostfacenet.tflite`
3. Run `flutter pub get`
4. Test dengan command: `flutter assets`
5. Run app dan verify model loads successfully

### Notes

⚠️ **IMPORTANT**: Aplikasi akan compile tanpa error meskipun model file belum ada,
tapi face recognition **TIDAK AKAN BERFUNGSI** sampai model di-download.

Code sudah di-implement dengan error handling untuk case ini. App akan show error:
"TFLite model not loaded. Please download model file."
