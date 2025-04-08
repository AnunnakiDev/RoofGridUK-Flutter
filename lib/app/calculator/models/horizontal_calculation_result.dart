class HorizontalCalculationResult {
  final int width;
  final String solution;
  final int newWidth;
  final int? lhOverhang;
  final int? rhOverhang;
  final int? cutTile;
  final int firstMark;
  final int? secondMark;
  final String marks;
  final String? splitMarks;

  const HorizontalCalculationResult({
    required this.width,
    required this.solution,
    required this.newWidth,
    this.lhOverhang,
    this.rhOverhang,
    this.cutTile,
    required this.firstMark,
    this.secondMark,
    required this.marks,
    this.splitMarks,
  });

  factory HorizontalCalculationResult.fromJson(Map<String, dynamic> json) {
    return HorizontalCalculationResult(
      width: json['Width'],
      solution: json['Solution'],
      newWidth: json['New Width'],
      lhOverhang: json['LH Overhang'],
      rhOverhang: json['RH Overhang'],
      cutTile: json['Cut Tile'],
      firstMark: json['1st Mark'],
      secondMark: json['2nd Mark'],
      marks: json['Marks'],
      splitMarks: json['Split Marks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Width': width,
      'Solution': solution,
      'New Width': newWidth,
      if (lhOverhang != null) 'LH Overhang': lhOverhang,
      if (rhOverhang != null) 'RH Overhang': rhOverhang,
      if (cutTile != null) 'Cut Tile': cutTile,
      '1st Mark': firstMark,
      if (secondMark != null) '2nd Mark': secondMark,
      'Marks': marks,
      if (splitMarks != null) 'Split Marks': splitMarks,
    };
  }
}
