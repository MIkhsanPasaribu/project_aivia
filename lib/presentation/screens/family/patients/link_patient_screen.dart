import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/patient_family_link.dart';
import '../../../providers/patient_family_provider.dart';

/// Screen untuk menambahkan link ke pasien baru
///
/// Family member bisa cari pasien berdasarkan email, pilih hubungan,
/// dan atur permissions untuk link tersebut.
class LinkPatientScreen extends ConsumerStatefulWidget {
  const LinkPatientScreen({super.key});

  @override
  ConsumerState<LinkPatientScreen> createState() => _LinkPatientScreenState();
}

class _LinkPatientScreenState extends ConsumerState<LinkPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String _selectedRelationship = 'anak';
  bool _isPrimaryCaregiver = false;
  bool _canEditActivities = true;
  bool _canViewLocation = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLinkPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller = ref.read(patientFamilyControllerProvider.notifier);
    final result = await controller.createLink(
      patientEmail: _emailController.text.trim(),
      relationshipType: _selectedRelationship,
      isPrimaryCaregiver: _isPrimaryCaregiver,
      canEditActivities: _canEditActivities,
      canViewLocation: _canViewLocation,
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Berhasil menambahkan pasien!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true = success
      },
      onFailure: (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${failure.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addPatient),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: AppDimensions.paddingL),

              // Email input
              _buildEmailField(),
              const SizedBox(height: AppDimensions.paddingM),

              // Relationship picker
              _buildRelationshipPicker(),
              const SizedBox(height: AppDimensions.paddingL),

              // Permissions section
              _buildPermissionsSection(),
              const SizedBox(height: AppDimensions.paddingXL),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.info),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Text(
              AppStrings.linkPatientDescription,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Pasien',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'contoh@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          validator: Validators.validateEmail,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildRelationshipPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hubungan Anda dengan Pasien',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        DropdownButtonFormField<String>(
          initialValue: _selectedRelationship,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.people_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          items: RelationshipTypes.all.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(RelationshipTypes.getLabel(type)),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() => _selectedRelationship = value!);
                },
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Izin Akses',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.paddingS),

        // Primary caregiver
        _buildPermissionTile(
          icon: Icons.star_outline,
          title: 'Pengasuh Utama',
          subtitle: 'Mendapat notifikasi prioritas untuk keadaan darurat',
          value: _isPrimaryCaregiver,
          onChanged: (value) {
            setState(() => _isPrimaryCaregiver = value);
          },
        ),

        const Divider(height: 1),

        // Edit activities
        _buildPermissionTile(
          icon: Icons.edit_outlined,
          title: 'Kelola Aktivitas',
          subtitle: 'Dapat menambah, mengedit, dan menghapus aktivitas pasien',
          value: _canEditActivities,
          onChanged: (value) {
            setState(() => _canEditActivities = value);
          },
        ),

        const Divider(height: 1),

        // View location
        _buildPermissionTile(
          icon: Icons.location_on_outlined,
          title: 'Lihat Lokasi',
          subtitle: 'Dapat melihat lokasi real-time pasien di peta',
          value: _canViewLocation,
          onChanged: (value) {
            setState(() => _canViewLocation = value);
          },
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: _isLoading ? null : onChanged,
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      activeTrackColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLinkPatient,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Tambahkan Pasien',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
