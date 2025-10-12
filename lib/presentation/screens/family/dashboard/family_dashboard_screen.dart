import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/patient_family_link.dart';
import '../../../providers/patient_family_provider.dart';
import '../../../providers/activity_provider.dart';
import '../../../providers/location_provider.dart';
import '../patients/link_patient_screen.dart';
import '../patients/patient_detail_screen.dart';

/// Dashboard utama untuk Family Member
///
/// Fitur:
/// - List semua pasien yang di-link
/// - Quick stats per pasien (activities, last location)
/// - Quick access ke fitur monitoring
/// - Tombol untuk add patient baru
class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedPatientsAsync = ref.watch(linkedPatientsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.familyDashboard,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: linkedPatientsAsync.when(
        data: (links) {
          if (links.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildPatientsList(context, ref, links);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate ke Link Patient Screen
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const LinkPatientScreen()),
          );

          // Jika berhasil link patient, show snackbar
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Pasien berhasil ditambahkan!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Pasien'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add, size: 120, color: AppColors.textTertiary),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              'Belum Ada Pasien',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'Anda belum menambahkan pasien untuk dimonitor.\n'
              'Tekan tombol "Tambah Pasien" untuk menghubungkan dengan pasien.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingXL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LinkPatientScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                  vertical: AppDimensions.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text(
                'Tambah Pasien Pertama',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              error,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger refresh by invalidating provider
                // ref.invalidate(linkedPatientsStreamProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsList(
    BuildContext context,
    WidgetRef ref,
    List<PatientFamilyLink> links,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate providers untuk refresh data
        // This will trigger re-fetch of activities and locations
        for (final link in links) {
          // Invalidate activity provider for this patient
          ref.invalidate(todayActivitiesProvider(link.patientId));

          // Invalidate location provider for this patient
          ref.invalidate(formattedLastLocationProvider(link.patientId));
        }

        // Wait a bit untuk animation
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        itemCount: links.length,
        itemBuilder: (context, index) {
          final link = links[index];
          return _buildPatientCard(context, link);
        },
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, PatientFamilyLink link) {
    final patient = link.patientProfile;

    if (patient == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailScreen(patient: patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Name + Relationship
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: patient.avatarUrl != null
                        ? NetworkImage(patient.avatarUrl!)
                        : null,
                    child: patient.avatarUrl == null
                        ? Text(
                            patient.fullName.isNotEmpty
                                ? patient.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppDimensions.paddingM),

                  // Name + Relationship
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.family_restroom,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              RelationshipTypes.getLabel(link.relationshipType),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Primary Caregiver Badge
                  if (link.isPrimaryCaregiver)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Utama',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingM),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppDimensions.paddingM),

              // Quick Stats
              Row(
                children: [
                  // Activities Count
                  Expanded(
                    child: _buildStatItemWithWidget(
                      icon: Icons.event_note,
                      label: 'Aktivitas Hari Ini',
                      valueWidget: _ActivityCountWidget(
                        patientId: link.patientId,
                      ),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),

                  // Last Location Update
                  Expanded(
                    child: _buildStatItemWithWidget(
                      icon: Icons.location_on,
                      label: 'Lokasi Terakhir',
                      valueWidget: _LastLocationWidget(
                        patientId: link.patientId,
                      ),
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingM),

              // Action Buttons
              Row(
                children: [
                  // View Activities
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: link.canEditActivities
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PatientDetailScreen(patient: patient),
                                ),
                              );
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text(
                        'Aktivitas',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),

                  // View Location
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: link.canViewLocation
                          ? () {
                              // TODO: Navigate to map
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur peta akan segera tersedia',
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                      ),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Peta', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Variant of _buildStatItem that accepts a widget for the value
  Widget _buildStatItemWithWidget({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                valueWidget,
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Consumer widget untuk menampilkan aktivitas count real-time
class _ActivityCountWidget extends ConsumerWidget {
  final String patientId;

  const _ActivityCountWidget({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayActivitiesAsync = ref.watch(todayActivitiesProvider(patientId));

    return todayActivitiesAsync.when(
      data: (activities) {
        return Text(
          activities.length.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => const Text(
        '-',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Consumer widget untuk menampilkan last location real-time
class _LastLocationWidget extends ConsumerWidget {
  final String patientId;

  const _LastLocationWidget({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedLocationAsync = ref.watch(
      formattedLastLocationProvider(patientId),
    );

    return formattedLocationAsync.when(
      data: (location) {
        return Text(
          location,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => const Text(
        'Unknown',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
