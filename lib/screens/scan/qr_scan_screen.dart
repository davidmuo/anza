import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../checkin/checkin_screen.dart';
import '../event_detail/event_detail_screen.dart';

/// Camera-based QR scanner for Anza's own codes:
///
///  - `anza://event?id=...` — opens that event's detail page (from a
///    student sharing an event with a friend).
///  - `anza://checkin?event=...&code=...` — jumps to check-in for that
///    event with the code pre-filled (from an organizer's door QR).
///
/// Anything else shows an "unrecognized code" message so the camera stays
/// open for another attempt.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

enum _PermissionState { checking, granted, denied, permanentlyDenied }

class _QrScanScreenState extends State<QrScanScreen> with WidgetsBindingObserver {
  final _controller = MobileScannerController();
  bool _handled = false;
  String? _statusMessage;
  _PermissionState _permission = _PermissionState.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user comes back from the system settings screen.
    if (state == AppLifecycleState.resumed && _permission != _PermissionState.granted) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;

    if (status.isGranted) {
      setState(() => _permission = _PermissionState.granted);
      return;
    }

    final result = await Permission.camera.request();
    if (!mounted) return;

    setState(() {
      _permission = result.isGranted
          ? _PermissionState.granted
          : result.isPermanentlyDenied
              ? _PermissionState.permanentlyDenied
              : _PermissionState.denied;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null) return;

    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'anza') {
      setState(() => _statusMessage = "That doesn't look like an Anza code.");
      return;
    }

    if (uri.host == 'event') {
      final id = uri.queryParameters['id'];
      if (id == null) {
        setState(() => _statusMessage = 'Event code is missing an id.');
        return;
      }
      _handled = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: id)),
      );
      return;
    }

    if (uri.host == 'checkin') {
      final eventId = uri.queryParameters['event'];
      final code = uri.queryParameters['code'];
      if (eventId == null || code == null) {
        setState(() => _statusMessage = 'Check-in code is incomplete.');
        return;
      }
      _handled = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CheckInScreen(eventId: eventId, scannedCode: code),
        ),
      );
      return;
    }

    setState(() => _statusMessage = "That doesn't look like an Anza code.");
  }

  Future<void> _enterCodeManually() async {
    final controller = TextEditingController();
    final code = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter code', style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text(
              "Type an event's check-in code or share code instead of "
              'scanning its QR.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.h2.copyWith(letterSpacing: 6),
              textAlign: TextAlign.center,
              onSubmitted: (value) => Navigator.of(sheetContext).pop(value),
              decoration: const InputDecoration(hintText: 'A1B2C3'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Continue',
              onPressed: () => Navigator.of(sheetContext).pop(controller.text),
            ),
          ],
        ),
      ),
    );

    if (code == null || code.trim().isEmpty || !mounted) return;
    _handleCode(code);
  }

  void _handleCode(String code) {
    final match = context.read<EventsProvider>().eventByCode(code);
    if (match == null) {
      setState(
        () => _statusMessage = "We couldn't find an event with that code.",
      );
      return;
    }

    _handled = true;
    if (match.isCheckInCode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CheckInScreen(
            eventId: match.event.id,
            scannedCode: match.event.checkInCode,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(eventId: match.event.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan Anza QR code'),
        actions: [
          if (_permission == _PermissionState.granted)
            IconButton(
              icon: const Icon(Icons.flash_on_rounded),
              tooltip: 'Toggle flash',
              onPressed: () => _controller.toggleTorch(),
            ),
        ],
      ),
      body: switch (_permission) {
        _PermissionState.checking => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        _PermissionState.granted => _scannerView(),
        _PermissionState.denied => _permissionMessage(
            title: 'Camera access needed',
            message: 'Anza needs your camera to scan event and check-in QR codes.',
            buttonLabel: 'Grant camera access',
            onPressed: _checkPermission,
          ),
        _PermissionState.permanentlyDenied => _permissionMessage(
            title: 'Camera access needed',
            message: 'Camera permission was denied. Enable it for Anza in your '
                'phone\'s app settings to scan codes.',
            buttonLabel: 'Open settings',
            onPressed: openAppSettings,
          ),
      },
    );
  }

  Widget _permissionMessage({
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: buttonLabel, onPressed: onPressed),
          ],
        ),
      ),
    );
  }

  Widget _scannerView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return _permissionMessage(
              title: "Couldn't start the camera",
              message: error.errorDetails?.message ??
                  'Something went wrong opening the camera. Make sure no other '
                      'app is using it and try again.',
              buttonLabel: 'Try again',
              onPressed: () => _controller.start(),
            );
          },
        ),
        // Scan-frame overlay so it's obvious where to point the camera.
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                Text(
                  'Point your camera at an event QR code or an organizer\'s '
                  'check-in code.',
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _enterCodeManually,
                  icon: const Icon(Icons.keyboard_rounded, color: Colors.white),
                  label: const Text(
                    'Enter code instead',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
