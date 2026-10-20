import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import 'zone_format.dart';

const _pillText = TextStyle(
  fontFamily: 'Inter',
  color: Color(0xFF475569),
  fontSize: 14,
);
const _pillHint = TextStyle(
  fontFamily: 'Inter',
  color: Color(0xFF94A3B8),
  fontSize: 14,
);

/// El campo blanco redondeado de los filtros de las listas.
class ModulePill extends StatelessWidget {
  const ModulePill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      height: r.s(48),
      padding: EdgeInsets.symmetric(horizontal: r.s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.s(24)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Un filtro de lista desplegable; [value] null es "todos".
class ModuleDropdownPill<T> extends StatelessWidget {
  const ModuleDropdownPill({
    super.key,
    required this.value,
    required this.hint,
    required this.allLabel,
    required this.options,
    required this.onChanged,
  });

  final T? value;
  final String hint;

  /// El texto de la opcion que quita el filtro.
  final String allLabel;

  /// Cada opcion con su texto.
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ModulePill(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          iconEnabledColor: const Color(0xFF64748B),
          dropdownColor: Colors.white,
          style: _pillText,
          hint: Text(hint, style: _pillHint),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
            for (final (v, label) in options)
              DropdownMenuItem<T?>(value: v, child: Text(label)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Un filtro de fecha: toca para elegir el dia y la equis lo quita.
class ModuleDatePill extends StatelessWidget {
  const ModuleDatePill({
    super.key,
    required this.tooltip,
    required this.hint,
    required this.day,
    required this.onTap,
    required this.onClear,
    required this.clearKey,
  });

  final Key clearKey;
  final String tooltip;
  final String hint;
  final DateTime? day;
  final VoidCallback onTap;
  final VoidCallback onClear;

  /// El selector de dia que usan los filtros: de tres anos atras a dos
  /// adelante.
  static Future<DateTime?> pick(BuildContext context, DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(r.s(24)),
        onTap: onTap,
        child: ModulePill(
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    day == null ? hint : formatCalendarDay(context, day!),
                    style: day == null ? _pillHint : _pillText,
                  ),
                ),
              ),
              SizedBox(width: r.s(4)),
              if (day == null)
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                )
              else
                InkWell(
                  key: clearKey,
                  onTap: onClear,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
