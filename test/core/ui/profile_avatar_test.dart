import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/profile/profile_photo.dart';
import 'package:sigaco_movil/core/profile/profile_photo_cubit.dart';
import 'package:sigaco_movil/core/ui/profile_avatar.dart';

class _Store implements ProfilePhotoStore {
  _Store(this.path);

  String? path;

  @override
  Future<String?> read(String userId) async => path;

  @override
  Future<String> save(String userId, String sourcePath) async => sourcePath;

  @override
  Future<void> remove(String userId) async => path = null;
}

/// El circulo de la persona (cuenta e inicio): su foto si la tiene y, si no, las
/// iniciales (APP-MOB-01, MOB-002).
void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('av_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Lo recoge el sistema.
      }
    });
  });

  Future<ProfilePhotoCubit> pump(WidgetTester tester, String? path) async {
    final cubit = ProfilePhotoCubit(store: _Store(path));
    await tester.runAsync(() => cubit.load('u1'));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: ProfileAvatar(
              initials: 'AT',
              radius: 32,
              background: Colors.green,
              foreground: Colors.white,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
    return cubit;
  }

  CircleAvatar circle(WidgetTester tester) =>
      tester.widget<CircleAvatar>(find.byType(CircleAvatar));

  testWidgets('sin foto se ven las iniciales', (tester) async {
    await pump(tester, null);
    expect(find.text('AT'), findsOneWidget);
    expect(circle(tester).backgroundImage, isNull);
  });

  testWidgets('con foto se ve la imagen y no las iniciales', (tester) async {
    final photo = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
    await pump(tester, photo.path);
    expect(find.text('AT'), findsNothing);
    expect(circle(tester).backgroundImage, isA<FileImage>());
  });

  testWidgets(
    'una foto que ya no esta en el disco se ve como si no existiera',
    (tester) async {
      await pump(tester, '${dir.path}/borrada.jpg');
      expect(find.text('AT'), findsOneWidget);
      expect(circle(tester).backgroundImage, isNull);
    },
  );

  testWidgets('al quitar la foto vuelve a las iniciales', (tester) async {
    final photo = File('${dir.path}/b.jpg')..writeAsBytesSync([9]);
    final cubit = await pump(tester, photo.path);
    expect(find.text('AT'), findsNothing);
    cubit.clear();
    await tester.pump();
    expect(find.text('AT'), findsOneWidget);
  });
}
