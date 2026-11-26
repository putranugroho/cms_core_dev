import 'package:flutter/foundation.dart';

@immutable
class HrisEmployeeModel {
  const HrisEmployeeModel({
    required this.id,
    required this.employeeNo,
    required this.name,
    required this.phone,
    required this.nik,
    required this.employeeStatus,
    required this.officeId,
    required this.officeCode,
    required this.officeName,
    required this.officeType,
  });

  final String id;
  final String employeeNo;
  final String name;
  final String phone;
  final String nik;
  final String employeeStatus;
  final String officeId;
  final String officeCode;
  final String officeName;
  final String officeType;

  static String _s(dynamic value) => value?.toString() ?? '';

  factory HrisEmployeeModel.fromJson(Map<String, dynamic> json) {
    final office = json['office'] is Map ? Map<String, dynamic>.from(json['office'] as Map) : <String, dynamic>{};
    return HrisEmployeeModel(
      id: _s(json['id']),
      employeeNo: _s(json['employee_no']),
      name: _s(json['name']),
      phone: _s(json['phone']),
      nik: _s(json['nik']),
      employeeStatus: _s(json['employee_status']),
      officeId: _s(office['id']),
      officeCode: _s(office['branch_code']),
      officeName: _s(office['name']),
      officeType: _s(office['branch_type']),
    );
  }

  String get title {
    final no = employeeNo.trim().isEmpty ? '-' : employeeNo.trim();
    final nm = name.trim().isEmpty ? '-' : name.trim();
    return '$no - $nm';
  }

  String get officeText {
    if (officeCode.trim().isEmpty && officeName.trim().isEmpty) return '-';
    if (officeCode.trim().isEmpty) return officeName;
    if (officeName.trim().isEmpty) return officeCode;
    return '$officeCode - $officeName';
  }
}
