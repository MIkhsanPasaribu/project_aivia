# =========================================================
# Script Verifikasi Model TFLite untuk Face Recognition
# =========================================================

Write-Host ""
Write-Host "🔍 VERIFIKASI MODEL TFLITE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if model file exists
$modelPath = "ghostfacenet.tflite"
$modelExists = Test-Path $modelPath

if ($modelExists) {
    Write-Host "✅ Model file ditemukan!" -ForegroundColor Green
    
    # Get file info
    $fileInfo = Get-Item $modelPath
    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    Write-Host "   Nama file: $($fileInfo.Name)" -ForegroundColor White
    Write-Host "   Ukuran: $fileSizeMB MB" -ForegroundColor White
    Write-Host "   Path lengkap: $($fileInfo.FullName)" -ForegroundColor White
    Write-Host ""
    
    # Verify size is reasonable (should be ~3-7MB)
    if ($fileSizeMB -lt 1) {
        Write-Host "⚠️  WARNING: File terlalu kecil (<1MB). Mungkin corrupt atau bukan model yang benar." -ForegroundColor Yellow
    } elseif ($fileSizeMB -gt 10) {
        Write-Host "⚠️  WARNING: File terlalu besar (>10MB). Pastikan ini GhostFaceNet model." -ForegroundColor Yellow
    } else {
        Write-Host "✅ Ukuran file normal untuk TFLite model" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📋 LANGKAH SELANJUTNYA:" -ForegroundColor Cyan
    Write-Host "   1. Jalankan: flutter pub get" -ForegroundColor White
    Write-Host "   2. Jalankan: flutter run" -ForegroundColor White
    Write-Host "   3. Cek logs saat app startup untuk:" -ForegroundColor White
    Write-Host "      - '✅ GhostFaceNet model loaded successfully'" -ForegroundColor Gray
    Write-Host "      - 'Input shape: [1, 112, 112, 3]'" -ForegroundColor Gray
    Write-Host "      - 'Output shape: [1, 512]'" -ForegroundColor Gray
    Write-Host ""
    
} else {
    Write-Host "❌ Model file TIDAK ditemukan!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📥 Silakan download model terlebih dahulu:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "OPSI 1 - GitHub (Recommended):" -ForegroundColor Cyan
    Write-Host "  1. Buka: https://github.com/HuangJunJie2017/GhostFaceNets" -ForegroundColor White
    Write-Host "  2. Download/clone repository" -ForegroundColor White
    Write-Host "  3. Copy file 'model/ghostfacenet.tflite' ke folder ini" -ForegroundColor White
    Write-Host ""
    Write-Host "OPSI 2 - Alternative Sources:" -ForegroundColor Cyan
    Write-Host "  - TensorFlow Hub: https://tfhub.dev/" -ForegroundColor White
    Write-Host "  - Kaggle Datasets: https://www.kaggle.com/datasets" -ForegroundColor White
    Write-Host "  - Hugging Face: https://huggingface.co/models" -ForegroundColor White
    Write-Host ""
    Write-Host "Expected file path:" -ForegroundColor Yellow
    Write-Host "  $PWD\ghostfacenet.tflite" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "📚 INFORMASI MODEL:" -ForegroundColor Cyan
Write-Host "   Model: GhostFaceNet" -ForegroundColor White
Write-Host "   Input: 112x112x3 RGB image" -ForegroundColor White
Write-Host "   Output: 512-dimensional embedding vector" -ForegroundColor White
Write-Host "   Accuracy: 99.2% on LFW dataset" -ForegroundColor White
Write-Host "   Size: ~5MB" -ForegroundColor White
Write-Host ""
