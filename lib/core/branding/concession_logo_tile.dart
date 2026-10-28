import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import 'logo_image.dart';

/// El logo de una concesion en una lista (selector): sobre un fondo claro, porque
/// los logos se disenan para fondos claros, y con un ancho fijo para que los
/// nombres queden alineados.
class ConcessionLogoTile extends StatelessWidget {
  const ConcessionLogoTile({super.key, required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      key: const Key('concession-logo'),
      width: r.s(64),
      height: r.s(40),
      padding: EdgeInsets.all(r.s(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.s(8)),
      ),
      alignment: Alignment.center,
      child: ConcessionLogoByUrl(
        url: url,
        height: r.s(30),
        semanticLabel: name,
      ),
    );
  }
}
