import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';
import '../profile/profile_controller.dart';
import 'striker_inventory.dart';
import 'striker_skin.dart';

/// Owns the player's striker inventory: buying (spends via ProfileController),
/// equipping, persistence.
class StrikerController extends ChangeNotifier {
  static const _key = 'strikers';

  final StorageService _storage;
  final ProfileController _profile;
  StrikerInventory _inv;

  StrikerController(this._storage, this._profile) : _inv = _read(_storage);

  static StrikerInventory _read(StorageService s) {
    final json = s.getJson(_key);
    return json == null
        ? const StrikerInventory()
        : StrikerInventory.fromJson(json);
  }

  StrikerInventory get inventory => _inv;
  StrikerSkin get equippedSkin => skinById(_inv.equipped);
  bool isOwned(String id) => _inv.isOwned(id);
  bool isEquipped(String id) => _inv.isEquipped(id);

  Future<bool> buy(StrikerSkin skin) async {
    if (_inv.isOwned(skin.id)) return false;
    final paid = await _profile.spend(skin.price);
    if (!paid) return false;
    _inv = _inv.copyWith(owned: {..._inv.owned, skin.id});
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> equip(String id) async {
    if (!_inv.isOwned(id)) return;
    _inv = _inv.copyWith(equipped: id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _storage.setJson(_key, _inv.toJson());
}
