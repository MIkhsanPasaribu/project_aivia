import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/known_person.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../providers/face_recognition_provider.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/known_person/person_card.dart';
import '../../../widgets/common/confirmation_dialog.dart';
import 'add_known_person_screen.dart';
import 'edit_known_person_screen.dart';

/// Screen untuk menampilkan daftar orang dikenal (Family View)
///
/// Features:
/// - Grid view dengan person cards
/// - Search functionality
/// - Pull to refresh
/// - Add FAB (if not read-only)
/// - Edit on tap (if not read-only)
/// - Delete on long press (if not read-only)
///
/// **Modes**:
/// - Family Mode (isReadOnly = false): Full CRUD operations
/// - Patient Mode (isReadOnly = true): View only, no edit/delete
class KnownPersonsListScreen extends ConsumerStatefulWidget {
  final String patientId;
  final bool isReadOnly;

  const KnownPersonsListScreen({
    super.key,
    required this.patientId,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<KnownPersonsListScreen> createState() =>
      _KnownPersonsListScreenState();
}

class _KnownPersonsListScreenState
    extends ConsumerState<KnownPersonsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final knownPersonsAsync = ref.watch(
      knownPersonsStreamProvider(widget.patientId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReadOnly ? 'Lihat Orang Dikenal' : 'Orang Dikenal',
        ),
        actions: [
          // Stats badge (only for Family mode)
          if (!widget.isReadOnly) _buildStatsBadge(isDark),
          if (!widget.isReadOnly) const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (knownPersonsAsync.maybeWhen(
            data: (persons) => persons.isNotEmpty,
            orElse: () => false,
          ))
            _buildSearchBar(isDark),

          // Content
          Expanded(
            child: knownPersonsAsync.when(
              data: (persons) => _buildContent(persons, isDark),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => Center(
                child: CustomErrorWidget(
                  message: 'Gagal memuat data orang dikenal',
                  onRetry: () =>
                      ref.refresh(knownPersonsStreamProvider(widget.patientId)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isReadOnly
          ? null // Hide FAB in read-only mode (Patient)
          : FloatingActionButton.extended(
              onPressed: _navigateToAddPerson,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah Orang'),
              backgroundColor: AppColors.primary,
            ),
    );
  }

  Widget _buildStatsBadge(bool isDark) {
    final statsAsync = ref.watch(knownPersonsStatsProvider(widget.patientId));

    return statsAsync.when(
      data: (stats) {
        final total = stats['total'] as int? ?? 0;
        if (total == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.secondary.withValues(alpha: 0.2)
                : AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_rounded,
                size: 18,
                color: isDark
                    ? AppColors.secondary.withValues(alpha: 0.9)
                    : AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$total',
                style: TextStyle(
                  color: isDark
                      ? AppColors.secondary.withValues(alpha: 0.9)
                      : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama atau hubungan...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? AppColors.surfaceVariant.withValues(alpha: 0.3)
              : AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildContent(List<KnownPerson> allPersons, bool isDark) {
    // Filter berdasarkan search query
    final filteredPersons = _searchQuery.isEmpty
        ? allPersons
        : allPersons.where((person) {
            return person.fullName.toLowerCase().contains(_searchQuery) ||
                (person.relationship?.toLowerCase().contains(_searchQuery) ??
                    false);
          }).toList();

    if (allPersons.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.person_off_rounded,
        title: widget.isReadOnly
            ? 'Belum Ada Orang Dikenal'
            : 'Belum Ada Orang Dikenal',
        description: widget.isReadOnly
            ? 'Minta keluarga Anda untuk menambahkan orang-orang yang sering Anda temui'
            : 'Tambahkan orang-orang terdekat pasien agar mereka bisa dikenali',
        actionButtonText: widget.isReadOnly ? null : 'Tambah Sekarang',
        onActionButtonTap: widget.isReadOnly ? null : _navigateToAddPerson,
      );
    }

    if (filteredPersons.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'Tidak Ditemukan',
        description: 'Tidak ada hasil untuk "$_searchQuery"',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(knownPersonsStreamProvider(widget.patientId));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppDimensions.paddingMedium,
          mainAxisSpacing: AppDimensions.paddingMedium,
        ),
        itemCount: filteredPersons.length,
        itemBuilder: (context, index) {
          final person = filteredPersons[index];
          return KnownPersonCard(
            person: person,
            onTap: widget.isReadOnly
                ? () =>
                      _showPersonDetails(person) // View details in dialog
                : () => _navigateToEditPerson(person), // Edit
            onLongPress: widget.isReadOnly
                ? null // Disable delete for Patient
                : () => _showDeleteConfirmation(person),
          );
        },
      ),
    );
  }

  void _navigateToAddPerson() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddKnownPersonScreen(patientId: widget.patientId),
      ),
    );
  }

  void _navigateToEditPerson(KnownPerson person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditKnownPersonScreen(person: person),
      ),
    );
  }

  /// Show person details in dialog (read-only mode for Patient)
  void _showPersonDetails(KnownPerson person) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingL),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo
              if (person.photoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: Image.network(
                    person.photoUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
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
                ),
              const SizedBox(height: AppDimensions.paddingM),

              // Name
              Text(
                person.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),

              // Relationship
              if (person.relationship != null &&
                  person.relationship!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Text(
                    person.relationship!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
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
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(KnownPerson person) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Orang Dikenal?',
        description:
            'Apakah Anda yakin ingin menghapus ${person.fullName}? Data pengenalan wajah akan hilang.',
        confirmText: 'Hapus',
        cancelText: 'Batal',
        isDestructive: true,
        onConfirm: () => _deletePerson(person.id),
      ),
    );
  }

  Future<void> _deletePerson(String personId) async {
    final notifier = ref.read(knownPersonNotifierProvider.notifier);
    final result = await notifier.deleteKnownPerson(personId);

    if (!mounted) return;

    result.fold(
      onSuccess: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
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
