import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../providers/activity_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';

/// Screen untuk menambah aktivitas baru untuk pasien
class AddActivityScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const AddActivityScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(activityControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tambah Aktivitas'),
            Text(
              widget.patientName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          children: [
            // Title field
            CustomTextField(
              controller: _titleController,
              label: 'Judul Aktivitas',
              hint: 'Contoh: Minum Obat',
              prefixIcon: Icons.title,
              validator: (value) => Validators.validateRequired(value, 'Judul'),
              enabled: !isLoading,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Description field
            CustomTextField(
              controller: _descriptionController,
              label: 'Deskripsi (Opsional)',
              hint: 'Tambahkan detail aktivitas',
              prefixIcon: Icons.description,
              maxLines: 4,
              enabled: !isLoading,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Date picker
            _DateTimePicker(
              label: 'Tanggal',
              icon: Icons.calendar_today,
              value: _formatDate(_selectedDate),
              onTap: isLoading ? null : () => _selectDate(context),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Time picker
            _DateTimePicker(
              label: 'Waktu',
              icon: Icons.access_time,
              value: _formatTime(_selectedTime),
              onTap: isLoading ? null : () => _selectTime(context),
            ),
            const SizedBox(height: 32),

            // Submit button
            CustomButton(
              text: 'Simpan Aktivitas',
              onPressed: isLoading ? null : _submitForm,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Combine date and time
    final activityDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final controller = ref.read(activityControllerProvider.notifier);

    await controller.createActivity(
      patientId: widget.patientId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      activityTime: activityDateTime,
    );

    if (!mounted) return;

    final state = ref.read(activityControllerProvider);

    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivitas berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan aktivitas: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _DateTimePicker({
    required this.label,
    required this.icon,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey[850]
              : AppColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
