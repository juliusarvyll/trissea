import 'package:cloud_firestore/cloud_firestore.dart';

class TerminalTrip {
  final String id;
  final String terminalName;
  final String location;
  final String passengerId;
  final String passengerName;
  final int cost;
  final Timestamp timestamp;
  bool accepted;
  bool cancelled;
  bool ended;


  TerminalTrip({
    required this.id,
    required this.terminalName,
    required this.location,
    required this.passengerId,
    required this.passengerName,
    required this.cost,
    required this.timestamp,
    this.accepted = false,
    this.cancelled = false,
    this.ended = false,
  });

  // Convert a TerminalTrip object to a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'terminalName': terminalName,
      'location': location,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'cost': cost,
      'timestamp': timestamp,
      'accepted': accepted,
      'ended': ended,
      'cancelled': cancelled,
    };
  }

  // Create a TerminalTrip object from a Map object
  factory TerminalTrip.fromMap(Map<String, dynamic> map) {
    return TerminalTrip(
      id: map['id'],
      terminalName: map['terminalName'],
      location: map['location'],
      passengerId: map['passengerId'],
      passengerName: map['passengerName'],
      cost: map['cost'],
      timestamp: map['timestamp'],
      accepted: map['accepted'] ?? false,
      ended: map['ended'] ?? false,
      cancelled: map['cancelled'] ?? false,
    );
  }
}
