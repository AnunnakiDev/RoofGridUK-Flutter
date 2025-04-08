class VerticalCalculationResult {
  final int inputRafter;
  final int totalCourses;
  final String solution;
  final int ridgeOffset;
  final int? underEaveBatten;
  final int? eaveBatten;
  final int firstBatten;
  final int? cutCourse;
  final String gauge;
  final String? splitGauge;
  final String? warning;

  const VerticalCalculationResult({
    required this.inputRafter,
    required this.totalCourses,
    required this.solution,
    required this.ridgeOffset,
    this.underEaveBatten,
    this.eaveBatten,
    required this.firstBatten,
    this.cutCourse,
    required this.gauge,
    this.splitGauge,
    this.warning,
  });

  factory VerticalCalculationResult.fromJson(Map<String, dynamic> json) {
    return VerticalCalculationResult(
      inputRafter: json['Input Rafter'],
      totalCourses: json['Total Courses'],
      solution: json['Solution'],
      ridgeOffset: json['Ridge Offset'],
      underEaveBatten: json['Under Eave Batten'],
      eaveBatten: json['Eave Batten'],
      firstBatten: json['1st Batten'],
      cutCourse: json['Cut Course'],
      gauge: json['Gauge'],
      splitGauge: json['Split Gauge'],
      warning: json['Warning'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Input Rafter': inputRafter,
      'Total Courses': totalCourses,
      'Solution': solution,
      'Ridge Offset': ridgeOffset,
      if (underEaveBatten != null) 'Under Eave Batten': underEaveBatten,
      if (eaveBatten != null) 'Eave Batten': eaveBatten,
      '1st Batten': firstBatten,
      if (cutCourse != null) 'Cut Course': cutCourse,
      'Gauge': gauge,
      if (splitGauge != null) 'Split Gauge': splitGauge,
      if (warning != null) 'Warning': warning,
    };
  }
}
