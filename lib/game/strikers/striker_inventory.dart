import 'striker_skin.dart';

/// The player's owned striker ids and the equipped one. The default striker is
/// always owned.
class StrikerInventory {
  final Set<String> owned;
  final String equipped;

  const StrikerInventory({
    this.owned = const {kDefaultStrikerId},
    this.equipped = kDefaultStrikerId,
  });

  bool isOwned(String id) => owned.contains(id);
  bool isEquipped(String id) => equipped == id;

  StrikerInventory copyWith({Set<String>? owned, String? equipped}) =>
      StrikerInventory(
        owned: owned ?? this.owned,
        equipped: equipped ?? this.equipped,
      );

  Map<String, dynamic> toJson() => {
        'owned': owned.toList(),
        'equipped': equipped,
      };

  factory StrikerInventory.fromJson(Map<String, dynamic> json) {
    final owned = {
      kDefaultStrikerId,
      ...((json['owned'] as List?) ?? const []).map((e) => e as String),
    };
    final equipped = (json['equipped'] as String?) ?? kDefaultStrikerId;
    return StrikerInventory(
      owned: owned,
      equipped: owned.contains(equipped) ? equipped : kDefaultStrikerId,
    );
  }
}
