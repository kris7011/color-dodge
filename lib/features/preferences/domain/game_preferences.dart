/// Settings that affect the player experience, independent of persistence.
class GamePreferences {
  const GamePreferences({this.reduceFlashes = false});

  final bool reduceFlashes;

  GamePreferences copyWith({bool? reduceFlashes}) =>
      GamePreferences(reduceFlashes: reduceFlashes ?? this.reduceFlashes);
}
