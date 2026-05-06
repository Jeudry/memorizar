enum ReviewRating {
  again,
  hard,
  good,
  easy;

  String get label {
    switch (this) {
      case ReviewRating.again:
        return 'De nuevo';
      case ReviewRating.hard:
        return 'Difícil';
      case ReviewRating.good:
        return 'Bien';
      case ReviewRating.easy:
        return 'Fácil';
    }
  }

  // SM-2 quality score (0-5)
  int get quality {
    switch (this) {
      case ReviewRating.again:
        return 0;
      case ReviewRating.hard:
        return 2;
      case ReviewRating.good:
        return 4;
      case ReviewRating.easy:
        return 5;
    }
  }
}
