class Unit {
  final int id;
  final String name;
  final String state;
  final List<PointOfContact> contacts;

  Unit({
    required this.id,
    required this.name,
    required this.state,
    this.contacts = const [],
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    final contacts = json['contacts'] as List<dynamic>? ?? [];
    return Unit(
      id: json['id'],
      name: json['name'],
      state: json['state'],
      contacts: contacts
          .map((c) => PointOfContact.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PointOfContact {
  final int id;
  final String name;
  final String position;
  final String? phone;
  final String? email;

  PointOfContact({
    required this.id,
    required this.name,
    required this.position,
    this.phone,
    this.email,
  });

  factory PointOfContact.fromJson(Map<String, dynamic> json) {
    return PointOfContact(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      phone: json['phone'],
      email: json['email'],
    );
  }
}
