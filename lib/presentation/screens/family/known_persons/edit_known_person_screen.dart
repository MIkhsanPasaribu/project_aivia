import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/known_person.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../providers/face_recognition_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/confirmation_dialog.dart';

/// Screen untuk edit orang dikenal (Family)
///
/// Features:
/// - Pre-filled form (nama, hubungan, bio)
/// - Photo read-only (tidak bisa diubah)
/// - Warning: Embedding tidak bisa diubah
/// - Update button
/// - Delete button
class EditKnownPersonScreen extends ConsumerStatefulWidget {
  final KnownPerson person;

  const EditKnownPersonScreen({super.key, required this.person});

  @override
  ConsumerState<EditKnownPersonScreen> createState() =>
      _EditKnownPersonScreenState();
}

class _EditKnownPersonScreenState extends ConsumerState<EditKnownPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late String _selectedRelationship;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.fullName);
    _bioController = TextEditingController(text: widget.person.bio ?? '');
    _selectedRelationship = widget.person.relationship ?? 'Keluarga';
  }

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
      appBar: AppBar(
        title: const Text('Edit Orang Dikenal'),
        actions: [
          // Delete button
          IconButton(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_rounded),
            color: AppColors.error,
          ),
        ],
      ),
      body: notifierState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo (read-only)
                    _buildPhotoSection(isDark),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Warning box
                    _buildWarningBox(isDark),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Nama field
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
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
                      hint: 'Contoh: Ibu yang suka masak',
                      prefixIcon: Icons.info_outline_rounded,
                      maxLines: 4,
                      maxLength: 200,
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Stats info
                    _buildStatsInfo(isDark),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Update button
                    CustomButton(
                      text: 'Perbarui',
                      onPressed: _submitForm,
                      leadingIcon: Icons.check_rounded,
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
          'Foto tidak dapat diubah untuk menjaga konsistensi data pengenalan wajah.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Photo preview
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          child: widget.person.photoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.person.photoUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: isDark
                        ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                        : AppColors.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: isDark
                        ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                        : AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppColors.error,
                    ),
                  ),
                )
              : Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                        : AppColors.surfaceVariant,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWarningBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(
          color: isDark
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDark
                ? AppColors.warning.withValues(alpha: 0.8)
                : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Anda hanya dapat mengubah nama, hubungan, dan informasi tambahan. Foto dan data pengenalan wajah tidak dapat diubah.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.warning.withValues(alpha: 0.8)
                    : AppColors.warning,
              ),
            ),
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

  Widget _buildStatsInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.visibility_rounded,
              label: 'Dikenali',
              value: '${widget.person.recognitionCount}x',
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark
                ? AppColors.divider.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.access_time_rounded,
              label: 'Terakhir Dilihat',
              value: widget.person.lastSeenText,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.8)
              : AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(knownPersonNotifierProvider.notifier);
    final result = await notifier.updateKnownPerson(
      personId: widget.person.id,
      fullName: _nameController.text.trim(),
      relationship: _selectedRelationship,
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Orang Dikenal?',
        description:
            'Apakah Anda yakin ingin menghapus ${widget.person.fullName}? Data pengenalan wajah akan hilang permanen.',
        confirmText: 'Hapus',
        cancelText: 'Batal',
        isDestructive: true,
        onConfirm: _deletePerson,
      ),
    );
  }

  Future<void> _deletePerson() async {
    final notifier = ref.read(knownPersonNotifierProvider.notifier);
    final result = await notifier.deleteKnownPerson(widget.person.id);

    if (!mounted) return;

    result.fold(
      onSuccess: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop(); // Close edit screen
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }
}
