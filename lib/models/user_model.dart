class User {
  final String? id;
  final String? passengerName;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? userType;
  final String? password;
  final double? userLatitude;
  final double? userLongitude;
  final double? heading;

  const User({
    this.id,
    this.passengerName,
    this.email,
    this.firstName,
    this.lastName,
    this.password,
    this.userType = 'passenger',
    this.userLatitude,
    this.userLongitude,
    this.heading,
  });

  factory User.fromJson(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      passengerName: data['passengerName'],
      email: data['email'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      password: data['password'],
      userType: data['userType'],
      userLatitude: data['userLatitude'],
      userLongitude: data['userLongitude'],
      heading: data['heading'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {};

    void addNonNull(String key, dynamic value) {
      if (value != null) {
        data[key] = value;
      }
    }

    addNonNull('id', id);
    addNonNull('passengerName', passengerName);
    addNonNull('email', email);
    addNonNull('firstName', firstName);
    addNonNull('lastName', lastName);
    addNonNull('password', password);
    addNonNull('userType', userType);
    addNonNull('userLatitude', userLatitude);
    addNonNull('userLongitude', userLongitude);
    addNonNull('heading', heading);

    return data;
  }
}
