import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/ref_colors.dart';
import '../../../cooperativo/data/coop_service.dart';

/// Renderiza el recap de la sesión cooperativa a una imagen PNG (fuera de
/// pantalla) y abre la hoja de compartir del sistema. No requiere cuenta.
Future<void> shareCoopRecapAsImage(BuildContext context) async {
  final coop = CoopService.active;
  final state = coop?.state;
  final answerLog = coop?.answerLog ?? const <CoopAnswerRecord>[];
  final myCorrect = answerLog.where((r) => r.wasCorrect).length;
  final teamCorrect = (state?.scores.values ?? const <int>[])
      .fold<int>(0, (sum, v) => sum + v);

  final card = _CoopRecapShareImage(
    deckName: state?.lobbyDeckName ?? 'Mazo',
    roomCode: state?.code ?? '',
    players: state?.memberIds.length ?? 0,
    myCorrect: myCorrect,
    myTotal: answerLog.length,
    teamCorrect: teamCorrect,
  );

  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await ScreenshotController().captureFromWidget(
      card,
      context: context,
      pixelRatio: 3.0,
      targetSize: const Size(380, 480),
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/memorizar_recap_${state?.code ?? 'coop'}.png',
    );
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '🎉 ¡Sesión cooperativa completada en Memorizar!',
    );
  } catch (e) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No se pudo generar la imagen.')),
    );
    debugPrint('Error compartiendo recap como imagen: $e');
  }
}

/// Tarjeta visual del recap pensada para exportar como imagen cuadrada-ish.
class _CoopRecapShareImage extends StatelessWidget {
  final String deckName;
  final String roomCode;
  final int players;
  final int myCorrect;
  final int myTotal;
  final int teamCorrect;

  const _CoopRecapShareImage({
    required this.deckName,
    required this.roomCode,
    required this.players,
    required this.myCorrect,
    required this.myTotal,
    required this.teamCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: 480,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0B2E), Color(0xFF231042), Color(0xFF0E2238)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          const Text(
            'Sesión cooperativa\ncompletada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$deckName${roomCode.isNotEmpty ? '  ·  Sala $roomCode' : ''}',
            style: const TextStyle(
              color: RefColors.cyan,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _stat('👥', '$players', players == 1 ? 'jugador' : 'jugadores'),
          const SizedBox(height: 14),
          _stat('✅', '$myCorrect/$myTotal', 'mis aciertos'),
          const SizedBox(height: 14),
          _stat('🏆', '$teamCorrect', 'aciertos del equipo'),
          const Spacer(),
          Row(
            children: const [
              Text('🧠', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text(
                'Memorizar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
