import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/known_person.dart';

/// Screen untuk menampilkan hasil face recognition
///
/// Shows:
/// - Captured photo
/// - Recognized person info (if match found)
/// - Not recognized message (if no match)
/// - Action buttons
///
/// **For Patient (Anak) Users**
class RecognitionResultScreen extends ConsumerWidget {
  final File capturedImage;
  final KnownPerson? recognizedPerson;
  final double? similarity;
  final String patientId;

  const RecognitionResultScreen({
    super.key,
    required this.capturedImage,
    required this.recognizedPerson,
    required this.similarity,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : Colors.white,
      appBar: AppBar(
        title: const Text(
          AppStrings.recognitionResultTitle,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: recognizedPerson != null
              ? _buildRecognizedState(context, isDark)
              : _buildNotRecognizedState(context, isDark),
        ),
      ),
    );
  }

  // ====================================================
  // RECOGNIZED STATE
  // ====================================================

  Widget _buildRecognizedState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Captured Photo
        _buildCapturedPhoto(isDark),
        const SizedBox(height: AppDimensions.paddingXL),

        // 2. Success Icon & Message
        _buildSuccessHeader(),
        const SizedBox(height: AppDimensions.paddingXL),

        // 3. Recognized Person Info Card
        _buildPersonInfoCard(isDark),
        const SizedBox(height: AppDimensions.paddingL),

        // 4. Similarity Score
        if (similarity != null) _buildSimilarityScore(isDark),
        const SizedBox(height: AppDimensions.paddingL),

        // 5. Timestamp
        _buildTimestamp(isDark),
        const SizedBox(height: AppDimensions.paddingXL * 2),

        // 6. Action Buttons
        _buildActionButtons(context, isDark, isRecognized: true),
      ],
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 48,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        const Text(
          AppStrings.faceRecognized,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          AppStrings.recognizedPerson,
          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPersonInfoCard(bool isDark) {
    final person = recognizedPerson!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Person Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: person.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: person.photoUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 200,
                      height: 200,
                      color: isDark
                          ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                          : AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 200,
                      height: 200,
                      color: isDark
                          ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                          : AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : Container(
                    width: 200,
                    height: 200,
                    color: isDark
                        ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                        : AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                  ),
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // Name
          Text(
            person.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),

          // Relationship
          if (person.relationship != null && person.relationship!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.family_restroom_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    person.relationship!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppDimensions.paddingM),

          // Bio
          if (person.bio != null && person.bio!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariant.withValues(alpha: 0.2)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Text(
                person.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimilarityScore(bool isDark) {
    final percentage = (similarity! * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.2)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Text(
            '${AppStrings.similarity}: ',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(bool isDark) {
    final now = DateTime.now();
    final timeString = DateFormatter.formatTimeOnly(now);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.2)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            '${AppStrings.recognizedAt} $timeString',
            style: const TextStyle(fontSize: 16, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // NOT RECOGNIZED STATE
  // ====================================================

  Widget _buildNotRecognizedState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Captured Photo
        _buildCapturedPhoto(isDark),
        const SizedBox(height: AppDimensions.paddingXL),

        // 2. Error Icon & Message
        _buildNotFoundHeader(),
        const SizedBox(height: AppDimensions.paddingXL),

        // 3. Info Box
        _buildNotFoundInfo(isDark),
        const SizedBox(height: AppDimensions.paddingXL * 2),

        // 4. Action Buttons
        _buildActionButtons(context, isDark, isRecognized: false),
      ],
    );
  }

  Widget _buildNotFoundHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.question_mark_rounded,
            size: 48,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        const Text(
          AppStrings.faceNotRecognized,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildNotFoundInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          const Text(
            AppStrings.notRecognizedMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.info,
                  size: 24,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Text(
                    AppStrings.notRecognizedSuggestion,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.info.withValues(alpha: 0.9)
                          : AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // SHARED COMPONENTS
  // ====================================================

  Widget _buildCapturedPhoto(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Image.file(
          capturedImage,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isDark, {
    required bool isRecognized,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action button
        ElevatedButton.icon(
          onPressed: () {
            // Pop twice to go back to camera
            Navigator.pop(context);
            // Camera will automatically restart detection
          },
          icon: const Icon(Icons.camera_alt_rounded, size: 24),
          label: Text(
            isRecognized ? AppStrings.recognizeAgain : AppStrings.tryAgain,
            style: const TextStyle(fontSize: 20),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingL,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),

        // Secondary action button
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Navigate to known persons list (family feature)
            // For now, just show info dialog
            _showKnownPersonsInfo(context);
          },
          icon: const Icon(Icons.people_rounded, size: 24),
          label: const Text(
            AppStrings.viewAllKnownPersons,
            style: TextStyle(fontSize: 18),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingL,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        ),
      ],
    );
  }

  void _showKnownPersonsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: const Text(
          'Fitur melihat daftar orang dikenal hanya tersedia untuk akun keluarga/wali.\n\n'
          'Minta keluarga Anda untuk menambahkan orang-orang yang sering Anda temui '
          'ke dalam database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
