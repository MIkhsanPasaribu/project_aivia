import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/known_person.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Card untuk menampilkan Known Person
///
/// Features:
/// - Photo dengan cached network image
/// - Nama dan hubungan
/// - Last seen badge
/// - Recognition count
/// - Tap to edit
class KnownPersonCard extends StatelessWidget {
  final KnownPerson person;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const KnownPersonCard({
    super.key,
    required this.person,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo dengan aspect ratio 1:1
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.borderRadiusMedium),
                ),
                child: _buildPhoto(isDark),
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  Text(
                    person.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Hubungan
                  Text(
                    person.displayRelationship,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Badges row
                  Row(
                    children: [
                      // Last seen badge
                      if (person.lastSeenAt != null)
                        Expanded(
                          child: _buildBadge(
                            context,
                            icon: Icons.access_time_rounded,
                            text: person.lastSeenText,
                            color: AppColors.info,
                            isDark: isDark,
                          ),
                        ),

                      if (person.lastSeenAt != null) const SizedBox(width: 4),

                      // Recognition count badge
                      _buildBadge(
                        context,
                        icon: Icons.visibility_rounded,
                        text: '${person.recognitionCount}x',
                        color: AppColors.secondary,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(bool isDark) {
    if (person.photoUrl.isEmpty) {
      // Placeholder avatar
      return Container(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.surfaceVariant,
        child: const Icon(
          Icons.person_rounded,
          size: 64,
          color: AppColors.textTertiary,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: person.photoUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.surfaceVariant,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: isDark
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.surfaceVariant,
        child: const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? color.withValues(alpha: 0.9) : color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? color.withValues(alpha: 0.9) : color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
