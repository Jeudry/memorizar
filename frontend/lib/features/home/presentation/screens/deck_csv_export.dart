import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/app_state.dart';
import '../../../../core/import/csv_export.dart';

/// Exporta un mazo a un archivo CSV (compatible con la importación):
///  - en escritorio abre un "guardar como" (file_selector);
///  - en móvil escribe a temporal y abre la hoja de compartir (share_plus).
Future<void> exportDeckToCsv(BuildContext context, MemoryDeckData deck) async {
  final messenger = ScaffoldMessenger.of(context);
  if (deck.cards.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Este mazo no tiene tarjetas para exportar.')),
    );
    return;
  }

  final csv = cardsToCsv(
    deck.cards
        .map((c) => CsvExportCard(front: c.front, back: c.back))
        .toList(),
  );
  final safe = deck.title.replaceAll(RegExp(r'[^\wáéíóúüñ \-]'), '').trim();
  final fileName = '${safe.isEmpty ? 'mazo' : safe}.csv';

  try {
    if (kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Exportar CSV no está disponible en web.')),
      );
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Mazo: ${deck.title}');
    } else {
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (location == null) return; // el usuario canceló
      await File(location.path).writeAsString(csv);
      messenger.showSnackBar(
        SnackBar(content: Text('Mazo exportado: ${location.path}')),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No se pudo exportar el mazo.')),
    );
    debugPrint('Export CSV error: $e');
  }
}
