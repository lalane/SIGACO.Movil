/// `KM 150+200`; con kilometro final distinto, `KM 150+200 - 151+000`. Null si no
/// hay kilometro inicial.
String? kmLabel(double? start, double? end) {
  if (start == null) return null;
  String km(double v) {
    final meters = (v * 1000).round();
    return '${meters ~/ 1000}+${(meters % 1000).toString().padLeft(3, '0')}';
  }

  final from = km(start);
  if (end == null || km(end) == from) return 'KM $from';
  return 'KM $from - ${km(end)}';
}

/// El kilometro de un texto como `KM 513+615`, `513+615` o `513.615`, en
/// kilometros (`513.615`). Null si no se reconoce.
double? parseKm(String? text) {
  final t = text?.trim();
  if (t == null || t.isEmpty) return null;
  final plus = RegExp(r'(\d+)\s*\+\s*(\d{1,3})\b').firstMatch(t);
  if (plus != null) {
    final km = int.parse(plus.group(1)!);
    final meters = int.parse(plus.group(2)!);
    return km + meters / 1000;
  }
  final decimal = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(t);
  if (decimal == null) return null;
  return double.tryParse(decimal.group(1)!.replaceAll(',', '.'));
}
