import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../providers/face_recognition_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/loading_indicator.dart';

/// Screen untuk menambah orang dikenal baru (Family)
///
/// Features:
/// - Photo picker (camera/gallery)
/// - Face detection preview
/// - Form: Nama, Hubungan, Bio
/// - Loading state saat generate embedding
/// - Validation & error handling
class AddKnownPersonScreen extends ConsumerStatefulWidget {
  final String patientId;

  const AddKnownPersonScreen({super.key, required this.patientId});

  @override
  ConsumerState<AddKnownPersonScreen> createState() =>
      _AddKnownPersonScreenState();
}

class _AddKnownPersonScreenState extends ConsumerState<AddKnownPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  String _selectedRelationship = 'Keluarga';
  bool _isProcessing = false;
  int? _detectedFaceCount;

  final List<String> _relationships = [
    'Ibu',
    'Ayah',
    'Anak',
    'Kakak',
    'Adik',
    'Suami',
    'Istri',
    'Kakek',
    'Nenek',
    'Paman',
    'Bibi',
    'Sepupu',
    'Teman',
    'Tetangga',
    'Pengasuh',
    'Dokter',
    'Perawat',
    'Keluarga',
    'Lainnya',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifierState = ref.watch(knownPersonNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Orang Dikenal')),
      body: notifierState.isLoading || _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Memproses foto...\nHarap tunggu sebentar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo picker section
                    _buildPhotoSection(isDark),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Nama field
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      hint: 'Contoh: Ibu Siti',
                      prefixIcon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama harus diisi';
                        }
                        if (value.trim().length < 2) {
                          return 'Nama minimal 2 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Relationship dropdown
                    _buildRelationshipDropdown(isDark),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Bio field
                    CustomTextField(
                      controller: _bioController,
                      label: 'Informasi Tambahan (Opsional)',
                      hint:
                          'Contoh: Ibu yang suka masak. Sering mengajak jalan-jalan.',
                      prefixIcon: Icons.info_outline_rounded,
                      maxLines: 4,
                      maxLength: 200,
                    ),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Info box
                    _buildInfoBox(isDark),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Submit button
                    CustomButton(
                      text: 'Simpan',
                      onPressed: _selectedImage != null ? _submitForm : null,
                      leadingIcon: Icons.save_rounded,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Foto Wajah',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Ambil foto wajah orang yang ingin ditambahkan. Pastikan hanya ada 1 wajah dalam foto.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Photo preview or placeholder
        if (_selectedImage != null)
          _buildPhotoPreview(isDark)
        else
          _buildPhotoPlaceholder(isDark),

        const SizedBox(height: 16),

        // Photo picker buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(bool isDark) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          child: Image.file(
            _selectedImage!,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        // Face count badge
        if (_detectedFaceCount != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _detectedFaceCount == 1
                    ? AppColors.success
                    : AppColors.error,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _detectedFaceCount == 1
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _detectedFaceCount == 1
                        ? '1 Wajah'
                        : '$_detectedFaceCount Wajah',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Delete button
        Positioned(
          top: 12,
          left: 12,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedImage = null;
                  _detectedFaceCount = null;
                });
              },
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusMedium,
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(bool isDark) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(
          color: isDark
              ? AppColors.divider.withValues(alpha: 0.3)
              : AppColors.divider,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_rounded,
            size: 64,
            color: isDark
                ? AppColors.textTertiary.withValues(alpha: 0.5)
                : AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada foto',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih kamera atau galeri untuk mengambil foto',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRelationship,
      decoration: InputDecoration(
        labelText: 'Hubungan',
        prefixIcon: const Icon(Icons.family_restroom_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
      ),
      items: _relationships.map((relationship) {
        return DropdownMenuItem(value: relationship, child: Text(relationship));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRelationship = value);
        }
      },
    );
  }

  Widget _buildInfoBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(
          color: isDark
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: isDark
                ? AppColors.info.withValues(alpha: 0.8)
                : AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tips: Ambil foto dengan pencahayaan yang baik dan pastikan wajah terlihat jelas untuk hasil pengenalan yang lebih akurat.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.info.withValues(alpha: 0.8)
                    : AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        debugPrint('ℹ️ User cancelled photo selection');
        return;
      }

      debugPrint('📷 Photo selected: ${pickedFile.path}');

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isProcessing = true;
        _detectedFaceCount = null;
      });

      // Detect faces untuk validation dengan retry logic yang lebih robust
      final faceService = ref.read(faceRecognitionServiceProvider);
      int faceCount = 0;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          debugPrint('🔍 Detecting faces (attempt ${retryCount + 1})...');
          faceCount = await faceService.getFaceCount(_selectedImage!);
          debugPrint('✅ Face detection successful: $faceCount face(s)');
          break; // Success
        } catch (e) {
          retryCount++;
          debugPrint('⚠️ Face detection failed (attempt $retryCount): $e');

          if (retryCount < maxRetries) {
            // Wait before retry with exponential backoff
            final delayMs = 500 * retryCount;
            debugPrint('   Retrying in ${delayMs}ms...');
            await Future.delayed(Duration(milliseconds: delayMs));
          } else {
            // Max retries reached
            setState(() {
              _isProcessing = false;
              _selectedImage = null; // Clear failed image
            });
            _showError(
              'Gagal mendeteksi wajah setelah $maxRetries percobaan.\n'
              'Pastikan foto jelas dan pencahayaan cukup.\n\n'
              'Detail: ${e.toString()}',
            );
            return;
          }
        }
      }

      setState(() {
        _detectedFaceCount = faceCount;
        _isProcessing = false;
      });

      if (faceCount == 0) {
        _showError(
          'Tidak ada wajah terdeteksi dalam foto.\n'
          'Pastikan wajah terlihat jelas dan coba lagi.',
        );
      } else if (faceCount > 1) {
        _showError(
          'Terdeteksi $faceCount wajah dalam foto.\n'
          'Pastikan hanya ada 1 orang dan coba lagi.',
        );
      } else {
        debugPrint('✅ Photo validation successful: 1 face detected');
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      setState(() {
        _isProcessing = false;
        _selectedImage = null;
      });
      _showError(
        'Gagal mengambil foto.\nSilakan coba lagi.\n\nError: ${e.toString()}',
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      _showError('Silakan pilih foto terlebih dahulu');
      return;
    }
    if (_detectedFaceCount != 1) {
      _showError('Foto harus memiliki tepat 1 wajah');
      return;
    }

    final notifier = ref.read(knownPersonNotifierProvider.notifier);
    final result = await notifier.addKnownPerson(
      patientId: widget.patientId,
      fullName: _nameController.text.trim(),
      relationship: _selectedRelationship,
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      photoFile: _selectedImage!,
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      },
      onFailure: (failure) {
        _showError(failure.message);
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}
