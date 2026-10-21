import '../../domain/entities/auth_entities.dart';

ConcessionSummary concessionFromJson(Map<String, dynamic> j) =>
    ConcessionSummary(
      id: j['id'] as String,
      code: (j['code'] ?? '') as String,
      name: (j['name'] ?? '') as String,
    );

CurrentUser userFromJson(Map<String, dynamic> j) => CurrentUser(
  id: j['id'] as String,
  username: (j['username'] ?? '') as String,
  fullName: (j['fullName'] ?? '') as String,
  email: (j['email'] ?? '') as String,
  organizationArea: j['organizationArea'] as String?,
  jobTitle: _text(j['jobTitle']),
  companyName: _text(j['companyName']),
);

/// Un texto vacio o de espacios cuenta como ausente.
String? _text(Object? v) {
  final s = v is String ? v.trim() : null;
  return s == null || s.isEmpty ? null : s;
}

/// Devuelve el resultado y el token de acceso de la respuesta de login.
(LoginOutcome, String) loginFromJson(Map<String, dynamic> j) => (
  LoginOutcome(
    user: userFromJson(j['user'] as Map<String, dynamic>),
    concessions: ((j['concessions'] ?? const []) as List)
        .map((e) => concessionFromJson(e as Map<String, dynamic>))
        .toList(),
    activeConcessionId: j['activeConcessionId'] as String?,
    idleTimeoutMinutes: (j['idleTimeoutMinutes'] ?? 10) as int,
    mfaRequired: (j['mfaRequired'] ?? false) as bool,
    mfaEnrollmentRequired: (j['mfaEnrollmentRequired'] ?? false) as bool,
    forcePasswordChange: (j['forcePasswordChange'] ?? false) as bool,
    expiresAt: DateTime.tryParse((j['expiresAt'] ?? '') as String)?.toUtc(),
  ),
  j['accessToken'] as String,
);

SessionRevalidation sessionRevalidationFromJson(Map<String, dynamic> j) {
  final navigation = j['navigation'] as Map<String, dynamic>?;
  List<String> texts(Object? v) => [
    for (final e in (v ?? const []) as List)
      if (e is String) e,
  ];
  return SessionRevalidation(
    accountStatus: (j['accountStatus'] ?? '') as String,
    expiresAt: DateTime.parse(j['expiresAt'] as String).toUtc(),
    idleTimeoutMinutes: (j['idleTimeoutMinutes'] as num?)?.toInt() ?? 10,
    serverTime: DateTime.parse(j['serverTime'] as String).toUtc(),
    activeConcessionId: j['activeConcessionId'] as String?,
    mfaPending: (j['mfaPending'] ?? false) as bool,
    forcePasswordChange: (j['forcePasswordChange'] ?? false) as bool,
    permissions: texts(navigation?['permissions']),
    modules: [
      for (final m in (navigation?['modules'] ?? const []) as List)
        if (m is Map && m['code'] is String) m['code'] as String,
    ],
  );
}

MyProfile profileFromJson(Map<String, dynamic> j) {
  final account = j['account'] as Map<String, dynamic>;
  final ctx =
      (j['context'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
  final active = ctx['activeConcession'] as Map<String, dynamic>?;
  final profile = ctx['profile'] as Map<String, dynamic>?;
  return MyProfile(
    user: userFromJson(account),
    activeConcession: active == null ? null : concessionFromJson(active),
    profile: profile == null
        ? null
        : ProfileSummary(
            code: (profile['code'] ?? '') as String,
            nameEs: (profile['nameEs'] ?? '') as String,
            namePt: profile['namePt'] as String?,
          ),
    roads: ((ctx['roads'] ?? const []) as List)
        .map((e) => e as Map<String, dynamic>)
        .map(
          (r) => RoadSummary(
            id: r['id'] as String,
            code: (r['code'] ?? '') as String,
            name: (r['name'] ?? '') as String,
          ),
        )
        .toList(),
    availableConcessions: ((ctx['availableConcessions'] ?? const []) as List)
        .map((e) => concessionFromJson(e as Map<String, dynamic>))
        .toList(),
    mfa: j['mfa'] is Map<String, dynamic>
        ? mfaStatusFromJson(j['mfa'] as Map<String, dynamic>)
        : null,
  );
}

SessionRequirement? requirementForCode(String code) => switch (code) {
  'MFA_REQUIRED' => SessionRequirement.mfa,
  'MFA_ENROLLMENT_REQUIRED' => SessionRequirement.mfaEnrollment,
  'PASSWORD_CHANGE_REQUIRED' => SessionRequirement.passwordChange,
  'CONTEXT_REQUIRED' => SessionRequirement.concession,
  _ => null,
};

MfaStatus mfaStatusFromJson(Map<String, dynamic> j) => MfaStatus(
  required: (j['required'] ?? false) as bool,
  active: (j['active'] ?? false) as bool,
  recoveryCodesRemaining: (j['recoveryCodesRemaining'] as num?)?.toInt() ?? 0,
);

/// Los codigos de recuperacion de la respuesta, sin vacios.
List<String> recoveryCodesFromJson(Map<String, dynamic>? j) => [
  for (final c in (j?['recoveryCodes'] ?? const []) as List)
    if (c is String && c.trim().isNotEmpty) c.trim(),
];

MfaEnrollment mfaEnrollmentFromJson(Map<String, dynamic> j) => MfaEnrollment(
  secret: j['secret'] as String,
  otpAuthUri: (j['otpAuthUri'] ?? '') as String,
);
