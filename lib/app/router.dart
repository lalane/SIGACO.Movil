import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/credential_store.dart';
import '../features/auth/presentation/account/account_cubit.dart';
import '../features/auth/presentation/account/account_page.dart';
import '../features/auth/presentation/account/account_mfa_page.dart';
import '../features/auth/presentation/account/account_password_page.dart';
import '../features/auth/presentation/account/mfa_setup_cubit.dart';
import '../features/auth/presentation/account/change_password_cubit.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/change_password_page.dart';
import '../features/auth/presentation/pages/concession_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/mfa_enroll_page.dart';
import '../features/auth/presentation/pages/mfa_page.dart';
import '../features/auth/presentation/pages/recovery_page.dart';
import '../features/documents/domain/entities/document_access.dart';
import '../features/documents/domain/repositories/documents_repository.dart';
import '../core/files/file_source.dart';
import '../core/files/local_file_store.dart';
import '../core/offline/sync_cubit.dart';
import '../features/documents/presentation/bloc/document_detail_cubit.dart';
import '../features/documents/presentation/bloc/document_preview_cubit.dart';
import '../features/documents/presentation/bloc/document_upload_cubit.dart';
import '../features/documents/presentation/pages/document_preview_page.dart';
import '../features/documents/presentation/pages/document_upload_page.dart';
import '../features/documents/presentation/bloc/documents_cubit.dart';
import '../features/documents/presentation/pages/document_detail_page.dart';
import '../features/documents/presentation/pages/documents_page.dart';
import '../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/sync/presentation/conflict_page.dart';
import '../features/sync/presentation/sync_page.dart';
import 'shell/home_page.dart';

String _routeFor(AuthStep step) => switch (step) {
  AuthStep.signedOut => '/login',
  AuthStep.mfa => '/mfa',
  AuthStep.mfaEnroll => '/mfa-enroll',
  AuthStep.changePassword => '/change-password',
  AuthStep.concession => '/concession',
  AuthStep.signedIn => '/home',
};

/// Avisa al router cuando cambia el paso del acceso.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream
        .map((s) => s.step)
        .distinct()
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthStep> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Lo que el usuario puede hacer en el gestor documental, segun los permisos
/// de su sesion; se recalcula si el menu cambia mientras la pantalla esta abierta.
DocumentAccess _documentAccess(BuildContext context) =>
    DocumentAccess.fromPermissions(
      context.select((NavigationBloc b) => b.state.menu.permissions),
    );

GoRouter createRouter(AuthBloc auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final step = auth.state.step;
      final loc = state.matchedLocation;
      if (step == AuthStep.signedOut) {
        return (loc == '/login' || loc == '/recovery' || loc == '/splash')
            ? null
            : '/login';
      }
      if (step == AuthStep.signedIn) {
        return (loc == '/home' ||
                loc.startsWith('/account') ||
                loc.startsWith('/sync') ||
                loc.startsWith('/documents'))
            ? null
            : '/home';
      }
      final target = _routeFor(step);
      return loc == target ? null : target;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(
        path: '/login',
        // `sigaco://app/login?reset=ok`: regreso del navegador tras restablecer.
        builder: (_, state) => LoginPage(
          passwordResetReturned: state.uri.queryParameters['reset'] == 'ok',
        ),
      ),
      GoRoute(path: '/recovery', builder: (_, _) => const RecoveryPage()),
      GoRoute(path: '/mfa', builder: (_, _) => const MfaPage()),
      GoRoute(path: '/mfa-enroll', builder: (_, _) => const MfaEnrollPage()),
      GoRoute(
        path: '/change-password',
        builder: (_, _) => const ChangePasswordPage(),
      ),
      GoRoute(path: '/concession', builder: (_, _) => const ConcessionPage()),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(
        path: '/documents',
        builder: (context, _) => BlocProvider(
          create: (_) => DocumentsCubit(context.read<DocumentsRepository>()),
          child: Builder(
            builder: (context) =>
                DocumentsPage(access: _documentAccess(context)),
          ),
        ),
        routes: [
          // Antes que ':id', o "upload" se tomaria por un documento.
          GoRoute(
            path: 'upload',
            builder: (context, _) => BlocProvider(
              create: (_) => DocumentUploadCubit(
                repository: context.read<DocumentsRepository>(),
                sync: context.read<SyncCubit>(),
                files: context.read<FileSource>(),
                store: context.read<LocalFileStore>(),
              ),
              child: Builder(
                builder: (context) =>
                    DocumentUploadPage(access: _documentAccess(context)),
              ),
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => DocumentDetailCubit(
                context.read<DocumentsRepository>(),
                state.pathParameters['id']!,
                sync: context.read<SyncCubit>(),
              ),
              child: Builder(
                builder: (context) =>
                    DocumentDetailPage(access: _documentAccess(context)),
              ),
            ),
            routes: [
              GoRoute(
                path: 'preview',
                builder: (context, state) => BlocProvider(
                  create: (_) => DocumentPreviewCubit(
                    context.read<DocumentsRepository>(),
                    state.pathParameters['id']!,
                  ),
                  child: Builder(
                    builder: (context) =>
                        DocumentPreviewPage(access: _documentAccess(context)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/sync',
        builder: (_, _) => const SyncPage(),
        routes: [
          GoRoute(
            path: 'conflict/:id',
            builder: (_, state) =>
                ConflictPage(operationId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        builder: (context, _) => BlocProvider(
          create: (_) => AccountCubit(context.read<AuthRepository>())..load(),
          child: const AccountPage(),
        ),
        routes: [
          GoRoute(
            path: 'password',
            builder: (context, _) => BlocProvider(
              create: (_) => ChangePasswordCubit(
                context.read<AuthRepository>(),
                context.read<CredentialStore>(),
              ),
              child: const AccountPasswordPage(),
            ),
          ),
          GoRoute(
            path: 'mfa',
            builder: (context, _) => BlocProvider(
              create: (_) => MfaSetupCubit(context.read<AuthRepository>()),
              child: const AccountMfaPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
