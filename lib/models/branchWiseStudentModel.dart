class BranchWiseStudentModel {
  final String? studentEnrolmentNumber;
  final String studentName;
  final String companyName;

  BranchWiseStudentModel({
    this.studentEnrolmentNumber,
    required this.studentName,
    required this.companyName
  });

  factory BranchWiseStudentModel.fromJson(Map<String, dynamic> _json) {
    return BranchWiseStudentModel(
      studentEnrolmentNumber: _json['studentEnrolmentNumber']?.toString(),
      studentName: _json['studentName'] ?? '',
      companyName: _json['companyName'] ?? ''
    );
  }
}