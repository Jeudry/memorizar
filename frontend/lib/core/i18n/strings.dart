import 'package:flutter/widgets.dart';

import '../app_state.dart';

/// Tabla de strings localizadas. Mantenemos un mapa por locale en código (no
/// arb) para no tener que generar nada en build. Cuando crezca, migramos a
/// gen_l10n. Por ahora ES (default) y EN.
class AppStrings {
  static const supportedLocales = <Locale>[Locale('es'), Locale('en')];

  static const Map<String, Map<String, String>> _table = {
    'es': {
      // Login
      'login.title': 'Memorizar',
      'login.subtitle':
          'Inicia sesión para guardar tu progreso, sincronizar mazos\ny conectarte con amigos.',
      'login.continueGoogle': 'Continuar con Google',
      'login.continueApple': 'Continuar con Apple',
      'login.continueFacebook': 'Continuar con Facebook',
      'login.continueGuest': 'Continuar como invitado',
      'login.guestNote':
          'Como invitado tu contenido vive solo en este dispositivo. '
              'Si reinstalas la app sin haber iniciado sesión antes, se pierde.',
      'login.or': 'o',
      'login.legal': 'Términos · Privacidad · Comunidad',
      'login.tabSocial': 'Redes',
      'login.tabEmail': 'Correo',
      'login.email': 'Correo',
      'login.password': 'Contraseña',
      'login.displayName': 'Tu nombre',
      'login.signIn': 'Iniciar sesión',
      'login.signUp': 'Crear cuenta',
      'login.toggleToSignUp': '¿Sin cuenta? Crear una',
      'login.toggleToSignIn': '¿Ya tienes cuenta? Iniciar sesión',
      // Stats
      'stats.title': 'Tus stats',
      'stats.streak': 'Racha',
      'stats.streakDays': 'días',
      'stats.totalDecks': 'Mazos',
      'stats.totalCards': 'Tarjetas',
      'stats.weakCards': 'Débiles',
      'stats.avgRetention': 'Retención prom.',
      'stats.correctVsWrong': 'Aciertos / Errores',
      'stats.byDeck': 'Por mazo',
      'stats.empty': 'Crea tu primer mazo para ver tus números aquí.',
      // Account
      'account.title': 'Mi cuenta',
      'account.editProfile': 'Editar perfil',
      'account.signOut': 'Cerrar sesión',
      'account.deleteAccount': 'Borrar cuenta',
      'account.deleteConfirmTitle': '¿Borrar tu cuenta?',
      'account.deleteConfirmBody':
          'Esto elimina tu perfil, mazos sincronizados, amigos y progreso. '
              'No se puede deshacer.',
      'account.deleteConfirmCta': 'Sí, borrar',
      'account.cancel': 'Cancelar',
      'account.theme': 'Apariencia',
      'account.themeLight': 'Claro',
      'account.themeDark': 'Oscuro',
      'account.themeSystem': 'Sistema',
      'account.language': 'Idioma',
      'account.langEs': 'Español',
      'account.langEn': 'English',
      // Inbox
      'inbox.title': 'Compartidos conmigo',
      'inbox.import': 'Importar a mis mazos',
      'inbox.empty': 'Cuando un amigo te comparta un mazo aparecerá aquí.',
      // Misc
      'common.refresh': 'Actualizar',
      'common.save': 'Guardar',
    },
    'en': {
      'login.title': 'Memorizar',
      'login.subtitle':
          'Sign in to save your progress, sync your decks\nand connect with friends.',
      'login.continueGoogle': 'Continue with Google',
      'login.continueApple': 'Continue with Apple',
      'login.continueFacebook': 'Continue with Facebook',
      'login.continueGuest': 'Continue as guest',
      'login.guestNote':
          'As a guest, your content only lives on this device. '
              'If you reinstall the app without having signed in, it will be lost.',
      'login.or': 'or',
      'login.legal': 'Terms · Privacy · Community',
      'login.tabSocial': 'Social',
      'login.tabEmail': 'Email',
      'login.email': 'Email',
      'login.password': 'Password',
      'login.displayName': 'Your name',
      'login.signIn': 'Sign in',
      'login.signUp': 'Create account',
      'login.toggleToSignUp': "Don't have an account? Create one",
      'login.toggleToSignIn': 'Already have an account? Sign in',
      'stats.title': 'Your stats',
      'stats.streak': 'Streak',
      'stats.streakDays': 'days',
      'stats.totalDecks': 'Decks',
      'stats.totalCards': 'Cards',
      'stats.weakCards': 'Weak',
      'stats.avgRetention': 'Avg retention',
      'stats.correctVsWrong': 'Correct / Wrong',
      'stats.byDeck': 'By deck',
      'stats.empty': 'Create your first deck to see your numbers here.',
      'account.title': 'My account',
      'account.editProfile': 'Edit profile',
      'account.signOut': 'Sign out',
      'account.deleteAccount': 'Delete account',
      'account.deleteConfirmTitle': 'Delete your account?',
      'account.deleteConfirmBody':
          'This removes your profile, synced decks, friends and progress. '
              'It cannot be undone.',
      'account.deleteConfirmCta': 'Yes, delete',
      'account.cancel': 'Cancel',
      'account.theme': 'Theme',
      'account.themeLight': 'Light',
      'account.themeDark': 'Dark',
      'account.themeSystem': 'System',
      'account.language': 'Language',
      'account.langEs': 'Spanish',
      'account.langEn': 'English',
      'inbox.title': 'Shared with me',
      'inbox.import': 'Import to my decks',
      'inbox.empty': 'When a friend shares a deck with you, it will appear here.',
      'common.refresh': 'Refresh',
      'common.save': 'Save',
    },
  };

  static String t(BuildContext context, String key) {
    final loc = AppScope.of(context).locale;
    final dict = _table[loc] ?? _table['es']!;
    return dict[key] ?? _table['es']?[key] ?? key;
  }
}
