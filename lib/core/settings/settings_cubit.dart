import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Original = colores de marca SIGACO; Dia y Noche son fijos. El origen de los
/// colores (SIGACO o concesion) se elige aparte, con [ColorOrigin].
enum Appearance { original, day, night }

/// De donde salen los colores de marca tras iniciar sesion. Antes de iniciar
/// sesion siempre son los de SIGACO (la concesion aun no se conoce).
enum ColorOrigin { concession, sigaco }

class SettingsState extends Equatable {
  const SettingsState({
    this.locale,
    this.appearance = Appearance.original,
    this.colorOrigin = ColorOrigin.concession,
    this.brandAvailable = false,
  });

  /// null = seguir el idioma del telefono (es/pt; si no, es).
  final Locale? locale;
  final Appearance appearance;
  final ColorOrigin colorOrigin;

  /// La concesion activa tiene colores propios (no se guarda): solo entonces
  /// se ofrece elegir el origen.
  final bool brandAvailable;

  SettingsState copyWith({
    Locale? locale,
    Appearance? appearance,
    ColorOrigin? colorOrigin,
    bool? brandAvailable,
  }) => SettingsState(
    locale: locale ?? this.locale,
    appearance: appearance ?? this.appearance,
    colorOrigin: colorOrigin ?? this.colorOrigin,
    brandAvailable: brandAvailable ?? this.brandAvailable,
  );

  @override
  List<Object?> get props => [locale, appearance, colorOrigin, brandAvailable];
}

/// Idioma y apariencia elegidos por el usuario; se guardan en el dispositivo.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(_read(_prefs));

  static const supportedLocales = [Locale('es'), Locale('pt')];
  static const _kLocale = 'app_locale';
  static const _kAppearance = 'appearance';
  static const _kColorOrigin = 'color_origin';

  final SharedPreferences _prefs;

  static SettingsState _read(SharedPreferences prefs) {
    final locale = prefs.getString(_kLocale);
    final appearance = prefs.getString(_kAppearance);
    final origin = prefs.getString(_kColorOrigin);
    return SettingsState(
      locale: locale == null ? null : Locale(locale),
      appearance: Appearance.values.firstWhere(
        (a) => a.name == appearance,
        orElse: () => Appearance.original,
      ),
      colorOrigin: ColorOrigin.values.firstWhere(
        (o) => o.name == origin,
        orElse: () => ColorOrigin.concession,
      ),
    );
  }

  Future<void> setLocale(Locale locale) async {
    emit(state.copyWith(locale: locale));
    await _prefs.setString(_kLocale, locale.languageCode);
  }

  Future<void> setAppearance(Appearance appearance) async {
    emit(state.copyWith(appearance: appearance));
    await _prefs.setString(_kAppearance, appearance.name);
  }

  Future<void> setColorOrigin(ColorOrigin origin) async {
    emit(state.copyWith(colorOrigin: origin));
    await _prefs.setString(_kColorOrigin, origin.name);
  }

  /// La app avisa si la concesion activa trae colores propios.
  void setBrandAvailable(bool available) {
    if (available == state.brandAvailable) return;
    emit(state.copyWith(brandAvailable: available));
  }
}
