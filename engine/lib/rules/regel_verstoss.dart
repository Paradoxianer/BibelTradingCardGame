/// Wird geworfen, wenn ein Command gegen REGELWERK.md verstößt.
class RegelVerstoss implements Exception {
  final String nachricht;

  const RegelVerstoss(this.nachricht);

  @override
  String toString() => 'RegelVerstoss: $nachricht';
}
