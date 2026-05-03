import 'package:flutter/widgets.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/ui_screens.dart';
import '../../features/home/presentation/screens/exercise_flow_screen.dart';

class AppRoutes {
  static const home = '/';
  static const biblia = '/biblia';
  static const especificar = '/especificar';
  static const iniciar = '/iniciar';
  static const repasar = '/repasar';
  static const comunidad = '/comunidad';
  static const amigos = '/amigos';
  static const stats = '/stats';
  static const cooperativo = '/cooperativo';
  static const cooperativoJuego = '/cooperativo/juego';
  static const cooperativoLogrado = '/cooperativo/logrado';
  static const ejercicios = '/ejercicios';
  static const flashcards = '/flashcards';
  static const flow = '/ejercicios-flow';
  static const bgNocturnoMate = '/preview/background/nocturno-mate';
  static const bgVinoAhumado = '/preview/background/vino-ahumado';
  static const bgTintaProfunda = '/preview/background/tinta-profunda';
  static const bgBrasaSuave = '/preview/background/brasa-suave';
  static const bgCarbonAmbar = '/preview/background/carbon-ambar';
  static const bgCiruelaTostada = '/preview/background/ciruela-tostada';
  static const bgPetroleoDorado = '/preview/background/petroleo-dorado';
  static const bgNaranjaNocturno = '/preview/background/naranja-nocturno';
  static const bgActualSuave = '/preview/background/actual-suave';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomeScreen(),
    bgNocturnoMate: (_) =>
        const HomeScreen(backgroundVariant: HomeBackgroundVariant.nocturnoMate),
    bgVinoAhumado: (_) =>
        const HomeScreen(backgroundVariant: HomeBackgroundVariant.vinoAhumado),
    bgTintaProfunda: (_) => const HomeScreen(
      backgroundVariant: HomeBackgroundVariant.tintaProfunda,
    ),
    bgBrasaSuave: (_) =>
        const HomeScreen(backgroundVariant: HomeBackgroundVariant.brasaSuave),
    bgCarbonAmbar: (_) =>
        const HomeScreen(backgroundVariant: HomeBackgroundVariant.carbonAmbar),
    bgCiruelaTostada: (_) => const HomeScreen(
      backgroundVariant: HomeBackgroundVariant.ciruelaTostada,
    ),
    bgPetroleoDorado: (_) => const HomeScreen(
      backgroundVariant: HomeBackgroundVariant.petroleoDorado,
    ),
    bgNaranjaNocturno: (_) => const HomeScreen(
      backgroundVariant: HomeBackgroundVariant.naranjaNocturno,
    ),
    bgActualSuave: (_) =>
        const HomeScreen(backgroundVariant: HomeBackgroundVariant.actualSuave),
    especificar: (_) => const EspecificarScreen(),
    iniciar: (_) => const IniciarScreen(),
    repasar: (_) => const RepasarScreen(),
    comunidad: (_) => const ComunidadScreen(),
    amigos: (_) => const AmigosScreen(),
    stats: (_) => const StatsScreen(),
    cooperativo: (_) => const CooperativoScreen(),
    cooperativoJuego: (_) => const CooperativoGameScreen(),
    cooperativoLogrado: (_) => const CooperativoSuccessScreen(),
    ejercicios: (_) => ExerciseFlowScreen(data: flowScreens.first),
    flashcards: (_) => const FlashcardsScreen(),
    for (final screen in flowScreens)
      '$flow/${screen.slug}': (_) => ExerciseFlowScreen(data: screen),
  };
}
