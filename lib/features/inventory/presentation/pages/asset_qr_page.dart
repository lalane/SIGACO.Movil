import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/scan/qr_scanner.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/asset_qr_cubit.dart';

/// El lector de QR del activo: la camara arriba y, abajo, que paso con lo
/// leido; si la camara no sirve, el codigo se escribe. Al encontrar el activo
/// se abre su ficha en lugar del lector.
class AssetQrPage extends StatefulWidget {
  const AssetQrPage({super.key, required this.scanner});

  final QrScanner scanner;

  @override
  State<AssetQrPage> createState() => _AssetQrPageState();
}

class _AssetQrPageState extends State<AssetQrPage> {
  final _manual = TextEditingController();
  bool _cameraFailed = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _search() {
    final text = _manual.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final cubit = context.read<AssetQrCubit>();
    cubit.reset();
    cubit.resolve(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<AssetQrCubit>();
    return BlocConsumer<AssetQrCubit, AssetQrState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        final id = state.assetId;
        if (state.status == AssetQrStatus.found && id != null) {
          context.pushReplacement('/inventory/${Uri.encodeComponent(id)}');
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: p.gradientTop,
        body: Column(
          children: [
            SigacoModuleHeader(title: l10n.invQrTitle),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: r.s(20)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r.s(24)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      KeyedSubtree(
                        key: const Key('asset-qr-camera'),
                        child: widget.scanner.build(
                          context,
                          onCode: cubit.resolve,
                          onError: () {
                            if (mounted) setState(() => _cameraFailed = true);
                          },
                        ),
                      ),
                      // El recuadro donde se pone el codigo.
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: r.s(220),
                            height: r.s(220),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r.s(20)),
                              border: Border.all(color: p.accent, width: 3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: r.s(16)),
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(12)),
              decoration: BoxDecoration(
                color: modulePaper,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(r.s(28)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Responsive.formMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Status(state: state, cameraFailed: _cameraFailed),
                        SizedBox(height: r.s(14)),
                        ModuleField(
                          label: l10n.invQrManual,
                          child: TextField(
                            key: const Key('asset-qr-manual'),
                            controller: _manual,
                            style: moduleInkStyle,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(),
                            decoration: moduleInput(
                              context,
                              hint: l10n.invQrManualHint,
                              suffix: IconButton(
                                key: const Key('asset-qr-go'),
                                tooltip: l10n.invQrManualGo,
                                onPressed: _search,
                                icon: Icon(
                                  Icons.search,
                                  color: p.accentIconOnLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Que paso con el ultimo codigo, o la indicacion de como leer uno.
class _Status extends StatelessWidget {
  const _Status({required this.state, required this.cameraFailed});

  final AssetQrState state;
  final bool cameraFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AssetQrCubit>();
    final (text, problem) = switch (state.status) {
      AssetQrStatus.scanning || AssetQrStatus.found => (
        cameraFailed ? l10n.invQrCameraError : l10n.invQrHint,
        cameraFailed,
      ),
      AssetQrStatus.resolving => (l10n.invQrResolving, false),
      AssetQrStatus.invalid => (l10n.invQrInvalid, true),
      AssetQrStatus.notFound => (l10n.invQrNotFound, true),
      AssetQrStatus.failure => (l10n.invQrFailure, true),
    };
    final retry =
        state.status == AssetQrStatus.invalid ||
        state.status == AssetQrStatus.notFound ||
        state.status == AssetQrStatus.failure;
    return Row(
      key: Key('asset-qr-status-${state.status.name}'),
      children: [
        if (state.status == AssetQrStatus.resolving)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            problem ? Icons.error_outline : Icons.qr_code_scanner,
            color: problem ? const Color(0xFFDC2626) : const Color(0xFF475569),
          ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: moduleInkStyle)),
        if (retry)
          TextButton(
            key: const Key('asset-qr-retry'),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.accentOnLight,
            ),
            onPressed: cubit.reset,
            child: Text(l10n.invQrRetry),
          ),
      ],
    );
  }
}
