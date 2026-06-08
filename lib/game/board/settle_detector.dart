/// Decides when a strike has finished: every moving piece is below [restSpeed].
class SettleDetector {
  final double restSpeed;
  const SettleDetector({this.restSpeed = 0.05});

  bool isSettled(Iterable<double> speeds) =>
      speeds.every((s) => s < restSpeed);
}
