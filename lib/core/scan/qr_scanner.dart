import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// La camara que lee codigos QR. Cada modulo la usa a traves de esta interfaz:
/// en la app es la camara (`mobile_scanner`); en las pruebas, un sustituto.
abstract interface class QrScanner {
  /// La vista de la camara. [onCode] recibe el texto de cada QR leido (puede
  /// llegar varias veces el mismo); [onError] avisa que la camara no se pudo
  /// usar (sin permiso, sin camara).
  Widget build(
    BuildContext context, {
    required ValueChanged<String> onCode,
    required VoidCallback onError,
  });
}

/// La camara del telefono con `mobile_scanner` (solo QR).
class CameraQrScanner implements QrScanner {
  const CameraQrScanner();

  @override
  Widget build(
    BuildContext context, {
    required ValueChanged<String> onCode,
    required VoidCallback onError,
  }) => _CameraView(onCode: onCode, onError: onError);
}

class _CameraView extends StatefulWidget {
  const _CameraView({required this.onCode, required this.onError});

  final ValueChanged<String> onCode;
  final VoidCallback onError;

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _reported = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      for (final code in capture.barcodes) {
        final raw = code.rawValue;
        if (raw != null && raw.trim().isNotEmpty) widget.onCode(raw);
      }
    },
    errorBuilder: (context, error) {
      // El aviso sale una sola vez, despues de dibujar.
      if (!_reported) {
        _reported = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onError());
      }
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.no_photography_outlined, color: Colors.white54),
        ),
      );
    },
  );
}

/// Sin camara (pruebas y entornos sin plugin): solo un fondo oscuro; el codigo
/// se escribe a mano.
class NoQrScanner implements QrScanner {
  const NoQrScanner();

  @override
  Widget build(
    BuildContext context, {
    required ValueChanged<String> onCode,
    required VoidCallback onError,
  }) => const ColoredBox(
    key: Key('qr-scanner-none'),
    color: Colors.black,
    child: Center(
      child: Icon(Icons.qr_code_scanner, color: Colors.white38, size: 64),
    ),
  );
}
