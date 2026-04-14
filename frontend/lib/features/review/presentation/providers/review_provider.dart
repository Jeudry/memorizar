import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/review/data/models/review_rating.dart';

part 'review_provider.freezed.dart';

@freezed
class ReviewSessionState with _$ReviewSessionState {
  const factory ReviewSessionState({
    required List<Item> queue,
    required int currentIndex,
    required bool isRevealed,
    required List<Item> completed,
    required bool isFinished,
    required bool isLoading,
  }) = _ReviewSessionState;
}

extension ReviewSessionStateX on ReviewSessionState {
  Item? get currentItem => currentIndex < queue.length ? queue[currentIndex] : null;
  int get remaining => queue.length - currentIndex;
  double get progress => queue.isEmpty ? 1.0 : currentIndex / queue.length;
}

class ReviewSessionNotifier extends StateNotifier<ReviewSessionState> {
  ReviewSessionNotifier()
      : super(const ReviewSessionState(
          queue: [],
          currentIndex: 0,
          isRevealed: false,
          completed: [],
          isFinished: false,
          isLoading: true,
        ));

  void loadItems(List<Item> items) {
    state = ReviewSessionState(
      queue: List.from(items),
      currentIndex: 0,
      isRevealed: false,
      completed: [],
      isFinished: items.isEmpty,
      isLoading: false,
    );
  }

  void reveal() {
    state = state.copyWith(isRevealed: true);
  }

  void rate(ReviewRating rating) {
    final item = state.currentItem;
    if (item == null) return;

    final updatedItem = _applySm2(item, rating);
    final newCompleted = [...state.completed, updatedItem];
    final nextIndex = state.currentIndex + 1;
    final isFinished = nextIndex >= state.queue.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      isRevealed: false,
      completed: newCompleted,
      isFinished: isFinished,
    );
  }

  // SM-2 algorithm
  Item _applySm2(Item item, ReviewRating rating) {
    final q = rating.quality;
    double ef = item.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ef < 1.3) ef = 1.3;

    int interval;
    int reps;

    if (q < 3) {
      interval = 1;
      reps = 0;
    } else {
      reps = item.repetitions + 1;
      interval = switch (reps) {
        1 => 1,
        2 => 6,
        _ => (item.interval * ef).round(),
      };
    }

    final nextReview = DateTime.now().add(Duration(days: interval));

    return item.copyWith(
      easeFactor: ef,
      interval: interval,
      repetitions: reps,
      nextReviewAt: nextReview,
      lastReviewedAt: DateTime.now(),
    );
  }
}

final reviewSessionProvider = StateNotifierProvider.autoDispose
    .family<ReviewSessionNotifier, ReviewSessionState, String>(
  (ref, deckId) {
    final notifier = ReviewSessionNotifier();
    final dueItemsAsync = ref.watch(dueItemsProvider(deckId));
    final items = dueItemsAsync.valueOrNull ?? [];
    notifier.loadItems(items);
    return notifier;
  },
);