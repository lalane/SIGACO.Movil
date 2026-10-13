import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/files/local_file_store.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/documents/data/repositories/sample_documents_repository.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_preview.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_upload.dart';
import 'package:sigaco_movil/features/documents/presentation/bloc/document_upload_cubit.dart';

import '../../support/fakes.dart';

UploadItem _item(String file, {int size = 1000, String path = '/tmp/x'}) =>
    UploadItem.fromFile(path: path, fileName: file, sizeBytes: size);

void main() {
  group('reglas de carga (D-03-46, D-03-75, D-03-79)', () {
    test('separa el nombre editable de la extension real', () {
      final i = _item('acta final.v2.PDF');
      expect(i.baseName, 'acta final.v2');
      expect(i.extension, '.PDF');
      expect(i.name, 'acta final.v2.PDF');
      expect(i.format, 'pdf');
    });

    test('sin extension, o con un nombre que solo empieza con punto', () {
      expect(_item('LEEME').extension, '');
      expect(_item('LEEME').format, '');
      expect(_item('.gitignore').baseName, '.gitignore');
      expect(_item('.gitignore').extension, '');
      expect(_item('termina.').extension, '');
    });

    test('el nombre se recorta y conserva la extension real', () {
      final i = _item('foto.jpg').withBaseName('  obra norte ');
      expect(i.name, 'obra norte.jpg');
    });

    test('una extension bloqueada se rechaza sin importar mayusculas', () {
      for (final f in ['virus.exe', 'VIRUS.EXE', 'a.Ps1', 'b.apk', 'c.lnk']) {
        expect(
          DocumentUploadRules.itemIssues(_item(f)),
          contains(UploadIssue.blockedExtension),
          reason: f,
        );
      }
      expect(DocumentUploadRules.itemIssues(_item('plano.dwg')), isEmpty);
      expect(DocumentUploadRules.blockedExtensions, hasLength(25));
    });

    test('un archivo vacio se rechaza', () {
      expect(DocumentUploadRules.itemIssues(_item('a.pdf', size: 0)), [
        UploadIssue.emptyFile,
      ]);
    });

    test('nombres invalidos', () {
      for (final base in [
        '',
        '   ',
        '...',
        'a<b',
        'a:b',
        'a"b',
        'a/b',
        'a\\b',
      ]) {
        expect(
          DocumentUploadRules.nameIssues(_item('x.pdf').withBaseName(base)),
          isNotEmpty,
          reason: '«$base»',
        );
      }
      expect(DocumentUploadRules.nameIssues(_item('x.pdf').withBaseName('')), [
        UploadIssue.nameEmpty,
      ]);
      for (final base in ['a|b', 'a?b', 'a*b', 'a\u0007b']) {
        expect(
          DocumentUploadRules.nameIssues(_item('x.pdf').withBaseName(base)),
          [UploadIssue.nameInvalid],
          reason: base,
        );
      }
      // Punto final: sin extension, el nombre termina en punto.
      expect(
        DocumentUploadRules.nameIssues(_item('doc.').withBaseName('doc.')),
        [UploadIssue.nameInvalid],
      );
    });

    test('se conservan acentos y caracteres Unicode', () {
      expect(
        DocumentUploadRules.nameIssues(
          _item('x.pdf').withBaseName('Inspección ñandú 日本'),
        ),
        isEmpty,
      );
    });

    test('255 caracteres con la extension caben; 256 no', () {
      final ok = _item('x.pdf').withBaseName('a' * 251);
      expect(ok.name.length, 255);
      expect(DocumentUploadRules.nameIssues(ok), isEmpty);
      final long = _item('x.pdf').withBaseName('a' * 252);
      expect(DocumentUploadRules.nameIssues(long), [UploadIssue.nameTooLong]);
    });

    test('se cuentan caracteres, no unidades UTF-16', () {
      // Cada emoji es un caracter pero dos unidades.
      final i = _item('x.pdf').withBaseName('😀' * 251);
      expect(DocumentUploadRules.nameIssues(i), isEmpty);
    });

    test('el tipo es obligatorio y la categoria no', () {
      expect(DocumentUploadRules.metadataIssues(const UploadMetadata()), [
        UploadIssue.typeMissing,
      ]);
      expect(
        DocumentUploadRules.metadataIssues(
          const UploadMetadata(typeCode: 'TD02'),
        ),
        isEmpty,
      );
    });

    test(
      'el tipo Otro pide una descripcion de 10 a 2000 caracteres utiles',
      () {
        UploadMetadata other(String d) =>
            UploadMetadata(typeCode: 'TD12', description: d);
        expect(DocumentUploadRules.metadataIssues(other('')), [
          UploadIssue.descriptionRequired,
        ]);
        // Los espacios de los extremos no cuentan.
        expect(DocumentUploadRules.metadataIssues(other('  corto   ')), [
          UploadIssue.descriptionRequired,
        ]);
        expect(DocumentUploadRules.metadataIssues(other('x' * 9)), isNotEmpty);
        expect(DocumentUploadRules.metadataIssues(other('x' * 10)), isEmpty);
        expect(DocumentUploadRules.metadataIssues(other('x' * 2000)), isEmpty);
        expect(DocumentUploadRules.metadataIssues(other('x' * 2001)), [
          UploadIssue.descriptionTooLong,
        ]);
      },
    );

    test('otros tipos no exigen descripcion pero la limitan', () {
      expect(
        DocumentUploadRules.metadataIssues(
          const UploadMetadata(typeCode: 'TD02', description: ''),
        ),
        isEmpty,
      );
      expect(
        DocumentUploadRules.metadataIssues(
          UploadMetadata(typeCode: 'TD02', description: 'x' * 2001),
        ),
        [UploadIssue.descriptionTooLong],
      );
    });
  });

  group('que se puede ver en la app (D-03-45)', () {
    test('imagenes, PDF y Office convertido; el resto no', () {
      expect(PreviewKind.forFormat('png'), PreviewKind.image);
      expect(PreviewKind.forFormat('jpg'), PreviewKind.image);
      expect(PreviewKind.forFormat('jpeg'), PreviewKind.image);
      expect(PreviewKind.forFormat('pdf'), PreviewKind.pdf);
      expect(PreviewKind.forFormat('docx'), PreviewKind.pdf);
      expect(PreviewKind.forFormat('xlsx'), PreviewKind.pdf);
      expect(PreviewKind.forFormat('pptx'), PreviewKind.pdf);
      expect(PreviewKind.forFormat('dwg'), PreviewKind.unsupported);
      expect(PreviewKind.forFormat(''), PreviewKind.unsupported);
    });
  });

  group('DocumentUploadCubit (072, 073, 082, 083)', () {
    late FakeSyncCubit sync;
    late FakeFileSource files;
    late MemoryFileStore store;
    late DocumentUploadCubit cubit;

    const scope = OfflineScope(userId: 'u1', concessionId: 'c0');

    setUp(() async {
      sync = FakeSyncCubit();
      await sync.setScope(scope);
      files = FakeFileSource();
      store = MemoryFileStore();
      cubit = DocumentUploadCubit(
        repository: SampleDocumentsRepository(
          clock: () => DateTime.utc(2026, 10, 12),
        ),
        sync: sync,
        files: files,
        store: store,
      );
    });
    tearDown(() async {
      await cubit.close();
      await sync.close();
    });

    const acta = SelectedFile(name: 'acta.pdf', path: '/tmp/a', sizeBytes: 500);
    const foto = SelectedFile(name: 'foto.jpg', path: '/tmp/b', sizeBytes: 900);

    test('los catalogos salen del servidor', () async {
      await cubit.loadCatalogs();
      expect(cubit.state.catalogs.types, hasLength(12));
    });

    test('elegir archivos los suma y no repite el mismo', () async {
      files.files = [acta, foto];
      await cubit.pickFiles();
      await cubit.pickFiles();
      expect(cubit.state.items.map((i) => i.name), ['acta.pdf', 'foto.jpg']);
    });

    test('cancelar el selector no cambia nada', () async {
      await cubit.pickFiles();
      await cubit.takePhoto();
      expect(cubit.state.items, isEmpty);
    });

    test(
      'la foto de la camara entra como cualquier archivo (regla 5)',
      () async {
        files.photo = foto;
        await cubit.takePhoto();
        expect(cubit.state.items.single.name, 'foto.jpg');
        expect(files.photos, 1);
      },
    );

    test('guardar sin nada muestra los errores y no guarda', () async {
      await cubit.submit();
      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.metadataIssues, [UploadIssue.typeMissing]);
      expect(sync.enqueued, isEmpty);
    });

    test('con errores conserva lo capturado para corregirlo (CA-02)', () async {
      files.files = [
        acta,
        const SelectedFile(name: 'virus.exe', path: '/tmp/v', sizeBytes: 10),
      ];
      await cubit.pickFiles();
      cubit.setType('TD02');
      cubit.setDescription('nota');
      await cubit.submit();
      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.status, UploadStatus.editing);
      expect(cubit.state.items, hasLength(2));
      expect(cubit.state.metadata.description, 'nota');
      expect(cubit.state.itemIssues[1], [UploadIssue.blockedExtension]);
      expect(sync.enqueued, isEmpty);
      expect(store.kept, isEmpty);
    });

    test(
      'guarda cada archivo en el telefono y lo encola con su metadato',
      () async {
        files.files = [acta, foto];
        await cubit.pickFiles();
        cubit.rename(0, '  Acta de obra ');
        cubit.setType('TD08');
        cubit.setCategory('CAT01');
        cubit.setFolder('Legal');
        cubit.setDescription('  Reunion de avance ');
        await cubit.submit();

        expect(cubit.state.status, UploadStatus.done);
        expect(cubit.state.saved, 2);
        expect(cubit.state.items, isEmpty);
        expect(sync.enqueued, hasLength(2));

        final first = sync.enqueued.first;
        expect(first.entity, 'documento');
        expect(first.kind, OperationKind.insert);
        expect(first.payload['name'], 'Acta de obra.pdf');
        expect(first.payload['typeCode'], 'TD08');
        expect(first.payload['categoryCode'], 'CAT01');
        expect(first.payload['folder'], 'Legal');
        expect(first.payload['description'], 'Reunion de avance');
        expect(first.payload['format'], 'pdf');
        expect(first.payload['sizeBytes'], 500);
        // Lo que viaja es la copia del telefono, no el temporal del selector.
        expect(first.payload['localPath'], store.kept.keys.first);
        expect(store.kept.values, ['/tmp/a', '/tmp/b']);
        expect(sync.enqueued[1].payload['name'], 'foto.jpg');
      },
    );

    test('la categoria y la carpeta son opcionales', () async {
      files.files = [acta];
      await cubit.pickFiles();
      cubit.setType('TD02');
      await cubit.submit();
      final p = sync.enqueued.single.payload;
      expect(p['categoryCode'], isNull);
      expect(p['folder'], isNull);
      expect(p['description'], '');
    });

    test(
      'un archivo que no se guarda en el telefono se queda en el formulario',
      () async {
        files.files = [acta, foto];
        await cubit.pickFiles();
        cubit.setType('TD02');
        store.failNames.add('acta.pdf');
        await cubit.submit();
        expect(cubit.state.status, UploadStatus.editing);
        expect(cubit.state.saved, 1);
        expect(cubit.state.saveFailed, isTrue);
        expect(cubit.state.items.single.name, 'acta.pdf');
        expect(sync.enqueued.single.payload['name'], 'foto.jpg');
        // Se puede reintentar y solo se guarda lo que faltaba.
        store.failNames.clear();
        await cubit.submit();
        expect(cubit.state.status, UploadStatus.done);
        expect(cubit.state.saved, 2);
        expect(sync.enqueued, hasLength(2));
      },
    );

    test(
      'sin cola donde guardar, no queda archivo huerfano ni se da por guardado',
      () async {
        sync.failEnqueue = true;
        files.files = [acta];
        await cubit.pickFiles();
        cubit.setType('TD02');
        await cubit.submit();
        expect(cubit.state.status, UploadStatus.editing);
        expect(cubit.state.saved, 0);
        expect(cubit.state.saveFailed, isTrue);
        expect(cubit.state.items, hasLength(1));
        expect(store.kept, isEmpty);
        expect(store.removed, hasLength(1));
      },
    );

    test(
      'quitar un archivo y renombrar con indices fuera de rango no falla',
      () async {
        files.files = [acta, foto];
        await cubit.pickFiles();
        cubit.removeAt(5);
        cubit.rename(-1, 'x');
        expect(cubit.state.items, hasLength(2));
        cubit.removeAt(0);
        expect(cubit.state.items.single.name, 'foto.jpg');
      },
    );

    test('dos toques seguidos en guardar no duplican', () async {
      files.files = [acta];
      await cubit.pickFiles();
      cubit.setType('TD02');
      await Future.wait([cubit.submit(), cubit.submit()]);
      expect(sync.enqueued, hasLength(1));
    });
  });

  group('DiskLocalFileStore', () {
    late Directory root;
    late Directory source;
    late DiskLocalFileStore store;

    setUp(() {
      root = Directory.systemTemp.createTempSync('sigaco_store_');
      source = Directory.systemTemp.createTempSync('sigaco_src_');
      store = DiskLocalFileStore(root: root);
    });
    tearDown(() {
      root.deleteSync(recursive: true);
      source.deleteSync(recursive: true);
    });

    File write(String name, String text) =>
        File('${source.path}/$name')..writeAsStringSync(text);

    test('copia el archivo a un lugar propio', () async {
      final original = write('acta.pdf', 'contenido');
      final kept = await store.keep(original.path, name: 'acta.pdf');
      expect(kept.startsWith(root.path), isTrue);
      expect(File(kept).readAsStringSync(), 'contenido');
      // El original sigue donde estaba.
      expect(original.existsSync(), isTrue);
    });

    test('dos archivos con el mismo nombre no se pisan', () async {
      final a = await store.keep(write('x.pdf', 'uno').path, name: 'x.pdf');
      final b = await store.keep(write('x.pdf', 'dos').path, name: 'x.pdf');
      expect(a, isNot(b));
      expect(File(a).readAsStringSync(), 'uno');
      expect(File(b).readAsStringSync(), 'dos');
    });

    test('un nombre con carpetas no sale de la carpeta propia', () async {
      final kept = await store.keep(
        write('x.pdf', 'z').path,
        name: '../../fuera.pdf',
      );
      expect(kept.startsWith(root.path), isTrue);
      expect(kept.endsWith('fuera.pdf'), isTrue);
    });

    test('si el origen no existe falla y no deja carpetas vacias', () async {
      await expectLater(
        store.keep('${source.path}/no_existe.pdf', name: 'a.pdf'),
        throwsA(isA<FileSystemException>()),
      );
      expect(root.listSync(), isEmpty);
    });

    test(
      'quitar borra el archivo y su carpeta; quitar dos veces no falla',
      () async {
        final kept = await store.keep(write('x.pdf', 'z').path, name: 'x.pdf');
        await store.remove(kept);
        expect(File(kept).existsSync(), isFalse);
        expect(root.listSync(), isEmpty);
        await store.remove(kept);
      },
    );
  });
}
