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
);

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
  ),
  j['accessToken'] as String,
);

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
  );
}

SessionRequirement? requirementForCode(String code) => switch (code) {
  'MFA_REQUIRED' => SessionRequirement.mfa,
  'MFA_ENROLLMENT_REQUIRED' => SessionRequirement.mfaEnrollment,
  'PASSWORD_CHANGE_REQUIRED' => SessionRequirement.passwordChange,
  'CONTEXT_REQUIRED' => SessionRequirement.concession,
  _ => null,
};

MfaEnrollment mfaEnrollmentFromJson(Map<String, dynamic> j) => MfaEnrollment(
  secret: j['secret'] as String,
  otpAuthUri: (j['otpAuthUri'] ?? '') as String,
);
