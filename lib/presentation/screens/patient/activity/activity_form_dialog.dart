import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_aivia/data/models/activity.dart';
import 'package:project_aivia/presentation/providers/activity_provider.dart';

/// Dialog untuk Add/Edit Activity
/// Mode ditentukan oleh parameter [activity] (null = Add, non-null = Edit)
class ActivityFormDialog extends ConsumerStatefulWidget {
  final Activity? activity; // Null untuk Add, non-null untuk Edit
  final String patientId;

  const ActivityFormDialog({super.key, this.activity, required this.patientId});

  @override
  ConsumerState<ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends ConsumerState<ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill jika mode Edit
    if (widget.activity != null) {
      _titleController.text = widget.activity!.title;
      _descriptionController.text = widget.activity!.description ?? '';
      _selectedDate = widget.activity!.activityTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.activity!.activityTime);
    } else {
      // Default: 1 jam dari sekarang
      final now = DateTime.now();
      _selectedDate = now.add(const Duration(hours: 1));
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(activityRepositoryProvider);

    final result = widget.activity == null
        ? await repository.createActivity(
            patientId: widget.patientId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            activityTime: _selectedDate,
          )
        : await repository.updateActivity(
            activityId: widget.activity!.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            activityTime: _selectedDate,
          );

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.activity == null
                  ? 'Aktivitas berhasil ditambahkan'
                  : 'Aktivitas berhasil diperbarui',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.activity != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit : Icons.add_circle_outline,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Aktivitas' : 'Tambah Aktivitas',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Judul Aktivitas
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Aktivitas *',
                    hintText: 'Contoh: Makan Siang',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul aktivitas harus diisi';
                    }
                    if (value.trim().length < 3) {
                      return 'Judul minimal 3 karakter';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Deskripsi
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Contoh: Jangan lupa minum obat',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Tanggal
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal *',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DateFormat(
                        'EEEE, dd MMMM yyyy',
                        'id_ID',
                      ).format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Waktu
                InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Waktu *',
                      prefixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveActivity,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEdit ? 'Simpan' : 'Tambah'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
