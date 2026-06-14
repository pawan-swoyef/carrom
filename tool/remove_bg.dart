// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps
// Removes the (near-white) background from the goti renders and writes
// transparent PNGs to assets/images/. Run: dart run tool/remove_bg.dart
import 'dart:io';
import 'package:image/image.dart' as img;

const _names = ['white', 'black', 'queen', 'striker'];

/// A pixel counts as background if it is near-white (incl. the soft grey shadow).
bool _isBg(num r, num g, num b) => r > 200 && g > 200 && b > 200;

void main() {
  Directory('assets/images').createSync(recursive: true);

  for (final name in _names) {
    final inFile = File('assets/$name.png');
    if (!inFile.existsSync()) {
      stderr.writeln('skip $name: assets/$name.png not found');
      continue;
    }
    final decoded = img.decodeImage(inFile.readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('skip $name: could not decode');
      continue;
    }
    // Ensure RGBA so we can write alpha.
    final image =
        decoded.numChannels == 4 ? decoded : decoded.convert(numChannels: 4);
    final w = image.width;
    final h = image.height;

    // Flood-fill the background starting from every border pixel, so interior
    // highlights of the coin (enclosed by its coloured rim) are preserved.
    final visited = List<bool>.filled(w * h, false);
    final stack = <int>[];

    void seed(int x, int y) {
      final p = image.getPixel(x, y);
      if (_isBg(p.r, p.g, p.b)) {
        final i = y * w + x;
        if (!visited[i]) {
          visited[i] = true;
          stack.add(i);
        }
      }
    }

    for (var x = 0; x < w; x++) {
      seed(x, 0);
      seed(x, h - 1);
    }
    for (var y = 0; y < h; y++) {
      seed(0, y);
      seed(w - 1, y);
    }

    var cleared = 0;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % w;
      final y = i ~/ w;
      final p = image.getPixel(x, y);
      image.setPixelRgba(x, y, p.r, p.g, p.b, 0); // make transparent
      cleared++;
      const neighbours = [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ];
      for (final d in neighbours) {
        final nx = x + d[0];
        final ny = y + d[1];
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        final ni = ny * w + nx;
        if (visited[ni]) continue;
        final np = image.getPixel(nx, ny);
        if (_isBg(np.r, np.g, np.b)) {
          visited[ni] = true;
          stack.add(ni);
        }
      }
    }

    // Crop to the visible (non-transparent) content.
    final trimmed = img.trim(image, mode: img.TrimMode.transparent);

    final out = File('assets/images/$name.png');
    out.writeAsBytesSync(img.encodePng(trimmed));
    print('$name: ${w}x$h -> ${trimmed.width}x${trimmed.height} '
        '(${cleared} px cleared)');
  }
}
