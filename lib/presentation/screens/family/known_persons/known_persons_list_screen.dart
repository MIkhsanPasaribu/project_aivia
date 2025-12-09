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
/// - Add FAB
/// - Edit on tap
/// - Delete on long press
class KnownPersonsListScreen extends ConsumerStatefulWidget {
  final String patientId;

  const KnownPersonsListScreen({super.key, required this.patientId});

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
        title: const Text('Orang Dikenal'),
        actions: [
          // Stats badge
          _buildStatsBadge(isDark),
          const SizedBox(width: 8),
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
      floatingActionButton: FloatingActionButton.extended(
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
        title: 'Belum Ada Orang Dikenal',
        description:
            'Tambahkan orang-orang terdekat pasien agar mereka bisa dikenali',
        actionButtonText: 'Tambah Sekarang',
        onActionButtonTap: _navigateToAddPerson,
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
            onTap: () => _navigateToEditPerson(person),
            onLongPress: () => _showDeleteConfirmation(person),
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
