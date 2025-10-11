import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Help Screen untuk panduan penggunaan aplikasi
///
/// Menampilkan:
/// - Cara Menggunakan (step by step)
/// - FAQ (Frequently Asked Questions)
/// - Tentang Aplikasi
/// - Kontak Support
/// - Versi Aplikasi
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bantuan & Panduan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          // Header Card
          _buildHeaderCard(),
          const SizedBox(height: AppDimensions.paddingM),

          // Cara Menggunakan
          _buildSectionTitle('📖 Cara Menggunakan'),
          _buildGuideCard(
            title: 'Untuk Pasien',
            items: [
              'Lihat daftar aktivitas harian Anda di Beranda',
              'Gunakan fitur "Kenali Wajah" untuk mengingat orang terdekat',
              'Tekan tombol Darurat jika membutuhkan bantuan segera',
              'Periksa profil Anda untuk informasi pribadi',
            ],
            icon: Icons.person,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          _buildGuideCard(
            title: 'Untuk Keluarga',
            items: [
              'Monitor aktivitas pasien melalui Dashboard',
              'Lacak lokasi pasien secara real-time',
              'Kelola aktivitas harian pasien',
              'Tambahkan kontak darurat',
              'Terima notifikasi jika pasien membutuhkan bantuan',
            ],
            icon: Icons.family_restroom,
            color: AppColors.secondary,
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // FAQ Section
          _buildSectionTitle('❓ Pertanyaan Umum (FAQ)'),
          _buildFAQItem(
            context: context,
            question: 'Bagaimana cara menghubungkan pasien dengan keluarga?',
            answer:
                'Keluarga dapat menambahkan pasien melalui menu "Tambah Pasien" di Dashboard. '
                'Masukkan email pasien yang sudah terdaftar, lalu pasien akan menerima notifikasi untuk menerima permintaan.',
          ),
          _buildFAQItem(
            context: context,
            question: 'Apakah aplikasi melacak lokasi pasien?',
            answer:
                'Ya, untuk keamanan pasien. Lokasi hanya dapat dilihat oleh keluarga yang terhubung. '
                'Data lokasi dienkripsi dan hanya disimpan untuk keperluan keamanan.',
          ),
          _buildFAQItem(
            context: context,
            question: 'Bagaimana cara kerja tombol darurat?',
            answer:
                'Tekan tombol darurat merah di layar utama. Semua kontak darurat akan langsung menerima notifikasi '
                'beserta lokasi Anda saat itu. Fitur ini dapat menyelamatkan nyawa!',
          ),
          _buildFAQItem(
            context: context,
            question: 'Apakah data saya aman?',
            answer:
                'Ya, semua data dienkripsi end-to-end. Kami menggunakan Supabase dengan Row Level Security (RLS) '
                'untuk memastikan hanya Anda dan keluarga yang terhubung yang dapat mengakses data.',
          ),
          _buildFAQItem(
            context: context,
            question: 'Bagaimana cara logout?',
            answer:
                'Buka menu Pengaturan (Settings) dari layar Profil, lalu pilih "Keluar" di bagian bawah.',
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // About Section
          _buildSectionTitle('ℹ️ Tentang Aplikasi'),
          _buildAboutCard(),

          const SizedBox(height: AppDimensions.paddingL),

          // Contact Support
          _buildSectionTitle('📞 Hubungi Kami'),
          _buildContactCard(),

          const SizedBox(height: AppDimensions.paddingXL),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          children: [
            const Icon(Icons.help_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'Selamat Datang di Pusat Bantuan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Temukan panduan lengkap dan jawaban atas pertanyaan Anda',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingS,
        bottom: AppDimensions.paddingS,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),
            ...items.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}. ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required BuildContext context,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppDimensions.paddingM,
            right: AppDimensions.paddingM,
            bottom: AppDimensions.paddingM,
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AIVIA - Alzheimer Assistant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'Aplikasi pendamping untuk pasien Alzheimer dan keluarga mereka. '
              'AIVIA membantu meningkatkan keamanan dan kualitas hidup melalui fitur '
              'pelacakan lokasi, pengingat aktivitas, dan sistem darurat.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.paddingM),
            _buildInfoRow('Versi', 'v1.0.0 (MVP)'),
            _buildInfoRow('Platform', 'Android'),
            _buildInfoRow('Teknologi', 'Flutter + Supabase'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            _buildContactItem(
              icon: Icons.email,
              label: 'Email Support',
              value: 'support@aivia.app',
              color: AppColors.primary,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildContactItem(
              icon: Icons.phone,
              label: 'Telepon',
              value: '+62 812-3456-7890',
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildContactItem(
              icon: Icons.language,
              label: 'Website',
              value: 'www.aivia.app',
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
