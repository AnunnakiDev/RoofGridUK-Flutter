class VerticalCalculationInput {
  final List<double> rafterHeights;
  final double gutterOverhang;
  final String materialType;
  final double slateTileHeight;
  final double maxGauge;
  final double minGauge;
  final String useDryRidge;  // 'YES' or 'NO'

  const VerticalCalculationInput({
    required this.rafterHeights,
    required this.gutterOverhang,
    required this.materialType,
    required this.slateTileHeight,
    required this.maxGauge,
    required this.minGauge,
    required this.useDryRidge,
  });

  Map<String, dynamic> toJson() {
    return {
      'rafterHeights': rafterHeights,
      'gutterOverhang': gutterOverhang,
      'materialType': materialType,
      'slateTileHeight': slateTileHeight,
      'maxGauge': maxGauge,
      'minGauge': minGauge,
      'useDryRidge': useDryRidge,
    };
  }
}
