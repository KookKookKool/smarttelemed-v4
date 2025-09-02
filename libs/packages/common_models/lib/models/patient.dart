// Patient Data Model
class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String idCard;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String address;

  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.idCard,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.address,
  });

  // Convert Patient to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'idCard': idCard,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'phoneNumber': phoneNumber,
        'address': address,
      };

  // Create Patient from JSON
  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        idCard: json['idCard'],
        dateOfBirth: DateTime.parse(json['dateOfBirth']),
        phoneNumber: json['phoneNumber'],
        address: json['address'],
      );

  // Get full name
  String get fullName => '$firstName $lastName';

  // Copy with modifications
  Patient copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? idCard,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? address,
  }) =>
      Patient(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        idCard: idCard ?? this.idCard,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        address: address ?? this.address,
      );
}