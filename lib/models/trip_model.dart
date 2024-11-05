import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  String? id;
  String? passengerId;
  String? toda;
  String? driverId;
  String? passengerName;
  String? todaName;
  String? todaLocation;
  String? driverName;
  String? pickupAddress;
  String? destinationAddress;
  String? finalDestinationAddress;
  String? tricycleColor;
  String? report;
  String? feedbackComment;
  double? pickupLatitude;
  double? pickupLongitude;
  double? destinationLatitude;
  double? destinationLongitude;
  double? finalDestinationLatitude;
  double? finalDestinationLongitude;
  double? feedback;
  int? passengerCount;
  double? distance;
  double? time;
  double? cost;
  double? rate;
  bool? rideShare;
  bool? accepted;
  bool? started;
  bool? canceled;
  bool? arrived;
  bool? arrivedToFinalDestination;
  bool? reachedDestination;
  bool? tripCompleted;
  Timestamp? currentDate; // Field for current date as Timestamp

  Trip({
    this.id,
    this.passengerId,
    this.toda,
    this.driverId,
    this.passengerName,
    this.driverName,
    this.todaName,
    this.todaLocation,
    this.pickupAddress,
    this.destinationAddress,
    this.finalDestinationAddress,
    this.feedbackComment,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.finalDestinationLatitude,
    this.finalDestinationLongitude,
    this.tricycleColor,
    this.report,
    this.feedback,
    this.passengerCount,
    this.distance,
    this.time,
    this.cost,
    this.rate,
    this.accepted = false,
    this.started,
    this.canceled = false,
    this.arrived,
    this.arrivedToFinalDestination,
    this.reachedDestination,
    this.tripCompleted,
    this.rideShare,
    Timestamp? currentDate, // Constructor parameter for current date as Timestamp
  }) : currentDate = currentDate ?? Timestamp.now(); // Initialize current date in constructor as current timestamp

  factory Trip.fromJson(Map<String, dynamic> data) => Trip(
        id: data['id'],
        passengerId: data['passengerId'],
        toda: data['toda'],
        driverId: data['driverId'],
        passengerName: data['passengerName'],
        driverName: data['driverName'],
        todaName: data['todaName'],
        todaLocation: data['todaLocation'],
        pickupAddress: data['pickupAddress'],
        destinationAddress: data['destinationAddress'],
        finalDestinationAddress: data['finalDestinationAddress'],
        pickupLatitude: data['pickupLatitude'],
        pickupLongitude: data['pickupLongitude'],
        destinationLatitude: data['destinationLatitude'],
        destinationLongitude: data['destinationLongitude'],
        finalDestinationLatitude: data['finalDestinationLatitude'],
        finalDestinationLongitude: data['finalDestinationLongitude'],
        feedbackComment: data['feedbackComment'],
        tricycleColor: data['tricycleColor'],
        report: data['report'],
        passengerCount: data['passengerCount'],
        distance: data['distance'],
        feedback: data['feedback'],
        time: data['time'],
        cost: data['cost'],
        rate: data['rate'],
        accepted: data['accepted'],
        started: data['started'],
        canceled: data['canceled'],
        arrived: data['arrived'],
        arrivedToFinalDestination: data['arrivedToFinalDestination'],
        reachedDestination: data['reachedDestination'],
        tripCompleted: data['tripCompleted'],
        rideShare: data['rideShare'],
        currentDate: data['currentDate'] ?? Timestamp.now(), // Initialize current date from JSON as Timestamp
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
    addNonNull('toda', toda);
    addNonNull('driverId', driverId);
    addNonNull('passengerName', passengerName);
    addNonNull('driverName', driverName);
    addNonNull('todaName', todaName);
    addNonNull('todaLocation', todaLocation);
    addNonNull('pickupAddress', pickupAddress);
    addNonNull('destinationAddress', destinationAddress);
    addNonNull('finalDestinationAddress', finalDestinationAddress);
    addNonNull('pickupLatitude', pickupLatitude);
    addNonNull('pickupLongitude', pickupLongitude);
    addNonNull('destinationLatitude', destinationLatitude);
    addNonNull('destinationLongitude', destinationLongitude);
    addNonNull('finalDestinationLatitude', finalDestinationLatitude);
    addNonNull('finalDestinationLongitude', finalDestinationLongitude);
    addNonNull('tricycleColor', tricycleColor);
    addNonNull('passengerCount', passengerCount);
    addNonNull('distance', distance);
    addNonNull('feedbackComment', feedbackComment);
    addNonNull('feedback', feedback);
    addNonNull('report', report);
    addNonNull('time', time);
    addNonNull('cost', cost);
    addNonNull('rate', rate);
    addNonNull('accepted', accepted);
    addNonNull('started', started);
    addNonNull('canceled', canceled);
    addNonNull('arrived', arrived);
    addNonNull('arrivedToFinalDestination', arrivedToFinalDestination);
    addNonNull('reachedDestination', reachedDestination);
    addNonNull('tripCompleted', tripCompleted);
    addNonNull('rideShare', rideShare);
    addNonNull('currentDate', currentDate);

    return data;
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      // Add other properties from your map
    );
  }
}
