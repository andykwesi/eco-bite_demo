class User {
  final String id;
  final String email;
  final String name;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;
  final int wasteReduction; // Carbon footprint reduction in grams
  final int moneySaved; // Money saved in cents

  User({
    required this.id,
    required this.email,
    required this.name,
    this.firstName,
    this.lastName,
    required this.createdAt,
    this.wasteReduction = 0,
    this.moneySaved = 0,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      createdAt: DateTime.parse(map['createdAt']),
      wasteReduction: map['wasteReduction'] ?? 0,
      moneySaved: map['moneySaved'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt.toIso8601String(),
      'wasteReduction': wasteReduction,
      'moneySaved': moneySaved,
    };
  }
}
