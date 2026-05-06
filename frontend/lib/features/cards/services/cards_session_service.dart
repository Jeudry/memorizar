import 'dart:math';

import 'package:memorizar/features/decks/data/models/item.dart';

class MatchingChallenge {
  const MatchingChallenge({
    required this.items,
    required this.contents,
  });

  final List<Item> items;
  final List<String> contents;
}

class IntruderChallenge {
  const IntruderChallenge({
    required this.options,
    required this.intruderId,
  });

  final List<Item> options;
  final String intruderId;
}

class CardsSessionService {
  const CardsSessionService();

  List<Item> selectFlashcards(List<Item> items, {int count = 5}) {
    if (items.length <= count) return [...items];
    return items.take(count).toList();
  }

  MatchingChallenge buildMatchingChallenge(List<Item> items) {
    final cluster = _pickNearbyCluster(items, desired: 4);
    final contents = cluster.map((item) => item.back).toList()..shuffle(Random(cluster.length));
    return MatchingChallenge(items: cluster, contents: contents);
  }

  IntruderChallenge buildIntruderChallenge(List<Item> items) {
    final cluster = _pickNearbyCluster(items, desired: 4);
    final intruder = _pickIntruder(items, cluster);
    final options = [...cluster, intruder]..shuffle(Random(intruder.id.hashCode));
    return IntruderChallenge(options: options, intruderId: intruder.id);
  }

  List<Item> _pickNearbyCluster(List<Item> items, {required int desired}) {
    if (items.length <= desired) return [...items];
    final random = Random(items.length * 31);
    final maxStart = max(0, items.length - desired);
    final start = random.nextInt(maxStart + 1);
    return items.skip(start).take(desired).toList();
  }

  Item _pickIntruder(List<Item> items, List<Item> cluster) {
    final clusterIds = cluster.map((item) => item.id).toSet();
    final outsider = items.where((item) => !clusterIds.contains(item.id)).toList();
    if (outsider.isNotEmpty) return outsider.last;
    return cluster.first;
  }
}
