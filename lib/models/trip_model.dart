class Trip {
  String? id;
  String? passengerId;
  String? driverId;
  String? passengerName;
  String? driverName;
  String? pickupAddress;
  String? destinationAddress;
  double? pickupLatitude;
  double? pickupLongitude;
  double? destinationLatitude;
  double? destinationLongitude;
  double? distance;
  double? time;
  double? cost;
  bool? accepted;
  bool? started;
  bool? canceled;
  bool? arrived;
  bool? reachedDestination;
  bool? tripCompleted;

  Trip({
    this.id,
    this.passengerId,
    this.driverId,
    this.passengerName,
    this.driverName,
    this.pickupAddress,
    this.destinationAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.distance,
    this.time,
    this.cost,
    this.accepted = false,
    this.started,
    this.canceled = false,
    this.arrived,
    this.reachedDestination,
    this.tripCompleted,
  });

  factory Trip.fromJson(Map<String, dynamic> data) => Trip(
        id: data['id'],
        passengerId: data['passengerId'],
        driverId: data['driverId'],
        passengerName: data['passengerName'],
        driverName: data['driverName'],
        pickupAddress: data['pickupAddress'],
        destinationAddress: data['destinationAddress'],
        pickupLatitude: data['pickupLatitude'],
        pickupLongitude: data['pickupLongitude'],
        destinationLatitude: data['destinationLatitude'],
        destinationLongitude: data['destinationLongitude'],
        distance: data['distance'],
        time: data['time'],
        cost: data['cost'],
        accepted: data['accepted'],
        started: data['started'],
        canceled: data['canceled'],
        arrived: data['arrived'],
        reachedDestination: data['reachedDestination'],
        tripCompleted: data['tripCompleted'],
      );

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {};

    void addNonNull(String key, dynamic value) {
      if (value != null) {
        data[key] = value;
      }
    }

    addNonNull('id', id);
    addNonNull('passengerId', passengerId);
    addNonNull('driverId', driverId);
    addNonNull('passengerName', passengerName);
    addNonNull('driverName', driverName);
    addNonNull('pickupAddress', pickupAddress);
    addNonNull('destinationAddress', destinationAddress);
    addNonNull('pickupLatitude', pickupLatitude);
    addNonNull('pickupLongitude', pickupLongitude);
    addNonNull('destinationLatitude', destinationLatitude);
    addNonNull('destinationLongitude', destinationLongitude);
    addNonNull('distance', distance);
    addNonNull('time', time);
    addNonNull('cost', cost);
    addNonNull('accepted', accepted);
    addNonNull('started', started);
    addNonNull('canceled', canceled);
    addNonNull('arrived', arrived);
    addNonNull('reachedDestination', reachedDestination);
    addNonNull('tripCompleted', tripCompleted);

    return data;
  }
}
