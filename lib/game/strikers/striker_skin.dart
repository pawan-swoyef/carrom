/// A cosmetic striker skin. Colours are ARGB ints used by StrikerBody.render.
class StrikerSkin {
  final String id;
  final String name;
  final int price; // 0 = free/default
  final int fill;
  final int ring;
  final int accent;
  const StrikerSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.fill,
    required this.ring,
    required this.accent,
  });
}

const String kDefaultStrikerId = 'classic';

const List<StrikerSkin> kStrikerCatalog = [
  StrikerSkin(
      id: 'classic', name: 'Classic', price: 0,
      fill: 0xFFF5C1A0, ring: 0xFFD4915A, accent: 0xFFFBE8D8),
  StrikerSkin(
      id: 'crimson', name: 'Crimson Vibe', price: 800,
      fill: 0xFFB03048, ring: 0xFF7A1F30, accent: 0xFFF4A9B8),
  StrikerSkin(
      id: 'onyx', name: 'Onyx', price: 1200,
      fill: 0xFF2A2A2E, ring: 0xFF555560, accent: 0xFF8A8A95),
  StrikerSkin(
      id: 'royalgold', name: 'Royal Gold', price: 1500,
      fill: 0xFFE6C068, ring: 0xFFB8923E, accent: 0xFFFBE8D8),
  StrikerSkin(
      id: 'emerald', name: 'Emerald', price: 2500,
      fill: 0xFF2E8B6E, ring: 0xFF1C5A46, accent: 0xFFB8F0DC),
];

StrikerSkin skinById(String id) =>
    kStrikerCatalog.firstWhere((s) => s.id == id,
        orElse: () => kStrikerCatalog.first);
