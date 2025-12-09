import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/presentation/providers/patient_family_provider.dart';
import 'package:project_aivia/presentation/screens/family/patient_tracking/patient_map_screen.dart';
import 'package:project_aivia/presentation/widgets/common/loading_indicator.dart';

/// Wrapper untuk Patient Map Tab dengan patient selection logic
class PatientMapTabWrapper extends ConsumerWidget {
  const PatientMapTabWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedPatientsAsync = ref.watch(linkedPatientsStreamProvider);

    return linkedPatientsAsync.when(
      data: (links) {
        if (links.isEmpty) {
          return _buildEmptyState(context);
        }

        // Filter links that have patientProfile
        final linksWithProfiles = links
            .where((link) => link.patientProfile != null)
            .toList();

        if (linksWithProfiles.isEmpty) {
          return _buildEmptyState(context);
        }

        // Jika hanya 1 patient, langsung tampilkan
        if (linksWithProfiles.length == 1) {
          final patient = linksWithProfiles.first.patientProfile!;
          return PatientMapScreen(patientId: patient.id);
        }

        // Jika multiple patients, tampilkan selector
        // TODO: Implement patient selector
        // For now, default to first patient
        final patient = linksWithProfiles.first.patientProfile!;
        return PatientMapScreen(patientId: patient.id);
      },
      loading: () => const Scaffold(body: Center(child: LoadingIndicator())),
      error: (error, _) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pasien'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 100,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 24),
              Text(
                'Belum Ada Pasien Terhubung',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Anda belum terhubung dengan pasien manapun. Hubungi pasien untuk mendapatkan kode tautan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pasien'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 100, color: AppColors.error),
              const SizedBox(height: 24),
              Text(
                'Terjadi Kesalahan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
