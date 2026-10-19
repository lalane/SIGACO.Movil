import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';
import 'module_style.dart';
import 'module_widgets.dart';

const _label = Color(0xFF8B95A7);
const _ink = Color(0xFF1E293B);

/// Marco de los formularios del mockup: fondo claro, tarjeta blanca con los
/// campos, fotos debajo y el boton principal fijo abajo.
class ModuleFormScaffold extends StatelessWidget {
  const ModuleFormScaffold({
    super.key,
    required this.header,
    required this.fields,
    required this.photos,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onSubmit,
    required this.saving,
    this.submitKey,
  });

  final Widget header;
  final List<Widget> fields;
  final Widget photos;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onSubmit;
  final bool saving;
  final Key? submitKey;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Scaffold(
      backgroundColor: modulePaper,
      body: Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    r.s(20),
                    r.s(20),
                    r.s(20),
                    r.s(24),
                  ),
                  children: [
                    Container(
                      padding: EdgeInsets.all(r.s(20)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(r.s(28)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: fields,
                      ),
                    ),
                    SizedBox(height: r.s(20)),
                    photos,
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(12), r.s(16), r.s(12)),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Responsive.formMaxWidth,
                  ),
                  child: FilledButton.icon(
                    key: submitKey,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(r.s(56)),
                      shape: const StadiumBorder(),
                      textStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: r.s(17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: saving ? null : onSubmit,
                    icon: saving
                        ? SizedBox(
                            width: r.s(18),
                            height: r.s(18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(buttonIcon),
                    label: Text(buttonLabel),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un campo con su etiqueta gris encima.
class ModuleField extends StatelessWidget {
  const ModuleField({
    super.key,
    required this.label,
    required this.child,
    this.error,
  });

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _label,
              fontWeight: FontWeight.w700,
              fontSize: r.s(13),
            ),
          ),
          SizedBox(height: r.s(8)),
          child,
          if (error != null)
            Padding(
              padding: EdgeInsets.only(top: r.s(6), left: r.s(4)),
              child: Text(
                error!,
                style: TextStyle(
                  color: const Color(0xFFDC2626),
                  fontSize: r.s(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// El campo redondeado del mockup. Colores fijos: la tarjeta es blanca en
/// cualquier apariencia de la app.
InputDecoration moduleInput(
  BuildContext context, {
  String? hint,
  Widget? suffix,
  bool error = false,
}) {
  final r = context.responsive;
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(r.s(26)),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: moduleHintStyle,
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    contentPadding: EdgeInsets.symmetric(
      horizontal: r.s(20),
      vertical: r.s(16),
    ),
    enabledBorder: border(
      error ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
    ),
    focusedBorder: border(
      error ? const Color(0xFFDC2626) : context.palette.accentIconOnLight,
    ),
    border: border(const Color(0xFFE2E8F0)),
  );
}

/// Texto de los campos y su sugerencia, con la fuente de la app: los menus
/// desplegables no heredan la del tema.
const moduleInkStyle = TextStyle(
  fontFamily: 'Inter',
  color: _ink,
  fontSize: 16,
);
const moduleHintStyle = TextStyle(
  fontFamily: 'Inter',
  color: Color(0xFFA3ABBA),
  fontSize: 16,
);

/// Un campo que solo se toca para abrir un selector (fecha u hora).
class ModulePickerField extends StatelessWidget {
  const ModulePickerField({
    super.key,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hint,
  });

  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.s(26)),
      child: InputDecorator(
        decoration: moduleInput(
          context,
          suffix: Icon(icon, color: const Color(0xFF64748B)),
        ),
        child: Text(
          value ?? hint ?? '',
          style: value == null ? moduleHintStyle : moduleInkStyle,
        ),
      ),
    );
  }
}

/// Los huecos para fotos: cada uno abre la camara; con foto, se ve y se quita
/// con la X.
class ModulePhotoSlots extends StatelessWidget {
  const ModulePhotoSlots({
    super.key,
    required this.photos,
    required this.onPick,
    required this.onRemove,
    this.keyPrefix = 'module-photo',
  });

  /// Las llaves de los huecos son `$keyPrefix-$i` y `$keyPrefix-remove-$i`.
  final String keyPrefix;
  final List<String?> photos;
  final ValueChanged<int> onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.followUpPhotos,
          style: TextStyle(
            color: _label,
            fontWeight: FontWeight.w700,
            fontSize: r.s(13),
          ),
        ),
        SizedBox(height: r.s(12)),
        Row(
          children: [
            for (var i = 0; i < photos.length; i++) ...[
              if (i > 0) SizedBox(width: r.s(14)),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _Slot(
                    keyPrefix: keyPrefix,
                    index: i,
                    path: photos[i],
                    onPick: () => onPick(i),
                    onRemove: () => onRemove(i),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.keyPrefix,
    required this.index,
    required this.path,
    required this.onPick,
    required this.onRemove,
  });

  final String keyPrefix;
  final int index;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final radius = BorderRadius.circular(r.s(24));
    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: moduleSurface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('$keyPrefix-$index'),
            onTap: onPick,
            child: path != null
                ? ModulePhoto(path: path)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: r.s(34),
                        color: const Color(0xFF94A3B8),
                      ),
                      SizedBox(height: r.s(6)),
                      Text(
                        l10n.followUpPhoto(index + 1),
                        style: TextStyle(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w700,
                          fontSize: r.s(13),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (path != null)
          Positioned(
            top: r.s(4),
            right: r.s(4),
            child: IconButton.filled(
              key: Key('$keyPrefix-remove-$index'),
              tooltip: l10n.followUpPhotoRemove,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
      ],
    );
  }
}
