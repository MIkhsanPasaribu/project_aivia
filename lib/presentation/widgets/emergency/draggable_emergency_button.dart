import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_button.dart';

/// Draggable Emergency Button Widget
///
/// FAB darurat yang bisa digeser ke mana saja di layar
/// Posisi disimpan secara persisten menggunakan SharedPreferences
///
/// Features:
/// - Draggable dengan smooth animation
/// - Save & restore position
/// - Visual feedback saat dragging
/// - Pulse animation tetap berjalan
/// - Default position: bottom-left (tidak menimpa bottom nav)
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     // Main content
///     Scaffold(...),
///
///     // Draggable emergency button
///     DraggableEmergencyButton(
///       patientId: userId,
///       onAlertCreated: () { ... },
///     ),
///   ],
/// )
/// ```
class DraggableEmergencyButton extends ConsumerStatefulWidget {
  final String patientId;
  final VoidCallback? onAlertCreated;
  final bool requireConfirmation;

  const DraggableEmergencyButton({
    super.key,
    required this.patientId,
    this.onAlertCreated,
    this.requireConfirmation = true,
  });

  @override
  ConsumerState<DraggableEmergencyButton> createState() =>
      _DraggableEmergencyButtonState();
}

class _DraggableEmergencyButtonState
    extends ConsumerState<DraggableEmergencyButton> {
  static const String _posXKey = 'emergency_button_pos_x';
  static const String _posYKey = 'emergency_button_pos_y';

  // Default position: bottom-left dengan padding
  static const double _defaultBottomPadding = 80.0; // Above bottom nav
  static const double _defaultLeftPadding = 16.0;

  late Offset _position;
  bool _isDragging = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeDefaultPosition();
      _isInitialized = true;
    }
  }

  void _initializeDefaultPosition() {
    final size = MediaQuery.of(context).size;

    // Default: bottom-left
    _position = Offset(
      _defaultLeftPadding,
      size.height - _defaultBottomPadding - 70, // 70 = FAB size + margin
    );
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_posXKey);
      final y = prefs.getDouble(_posYKey);

      if (x != null && y != null && mounted) {
        setState(() {
          _position = Offset(x, y);
        });
      }
    } catch (e) {
      debugPrint('Error loading emergency button position: $e');
    }
  }

  Future<void> _savePosition(Offset position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_posXKey, position.dx);
      await prefs.setDouble(_posYKey, position.dy);
    } catch (e) {
      debugPrint('Error saving emergency button position: $e');
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Update position with boundary checks
      final size = MediaQuery.of(context).size;
      final fabSize = 70.0; // Approximate FAB size

      double newX = _position.dx + details.delta.dx;
      double newY = _position.dy + details.delta.dy;

      // Clamp position to screen bounds with padding
      newX = newX.clamp(0.0, size.width - fabSize);
      newY = newY.clamp(0.0, size.height - fabSize);

      _position = Offset(newX, newY);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Save position after drag ends
    _savePosition(_position);

    // Provide haptic feedback
    // HapticFeedback.lightImpact(); // Optional
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: AnimatedScale(
          scale: _isDragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _isDragging ? 0.8 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isDragging ? 0.3 : 0.2,
                    ),
                    blurRadius: _isDragging ? 12 : 8,
                    spreadRadius: _isDragging ? 2 : 0,
                  ),
                ],
              ),
              child: EmergencyButton(
                patientId: widget.patientId,
                onAlertCreated: widget.onAlertCreated,
                requireConfirmation: widget.requireConfirmation,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
