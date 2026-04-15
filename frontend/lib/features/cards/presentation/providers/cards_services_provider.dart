import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/cards/services/cards_session_service.dart';

final cardsSessionServiceProvider = Provider<CardsSessionService>((ref) {
  return const CardsSessionService();
});
