import 'package:flutter/material.dart';

class Alarm {
  final String name;
  final TimeOfDay time;

  Alarm(this.name, this.time);

  @override
  String toString() {
    return 'Alarm{name: $name, time: $time}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alarm &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          time == other.time;

  @override
  int get hashCode => name.hashCode ^ time.hashCode;

  // check if it's empty
  bool isEmpty() {
    return name.isEmpty && time == const TimeOfDay(hour: 0, minute: 0);
  }
}