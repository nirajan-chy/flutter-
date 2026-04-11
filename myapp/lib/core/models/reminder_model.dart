import 'package:flutter/material.dart';

class ReminderModel {
  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.time,
    required this.repeat,
    required this.repeatDays,
    required this.timezone,
    required this.isActive,
    required this.snoozeMinutes,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime time;
  final String repeat;
  final List<String> repeatDays;
  final String timezone;
  bool isActive;
  final int snoozeMinutes;

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    final repeatDaysRaw = json['repeatDays'];

    return ReminderModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      time: DateTime.parse(json['time'].toString()).toLocal(),
      repeat: json['repeat']?.toString() ?? 'none',
      repeatDays: repeatDaysRaw is List
          ? repeatDaysRaw.map((e) => e.toString()).toList()
          : const <String>[],
      timezone: json['timezone']?.toString() ?? 'UTC',
      isActive: json['isActive'] == true,
      snoozeMinutes: (json['snoozeMinutes'] as num?)?.toInt() ?? 5,
    );
  }

  String get repeatLabel {
    switch (repeat) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return repeatDays.isEmpty ? 'Weekly' : repeatDays.join(', ');
      default:
        return 'Once';
    }
  }

  TimeOfDay get timeOfDay => TimeOfDay(hour: time.hour, minute: time.minute);

  ReminderModel copyWith({
    bool? isActive,
    DateTime? time,
    String? title,
    String? description,
    String? repeat,
    List<String>? repeatDays,
  }) {
    return ReminderModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      repeat: repeat ?? this.repeat,
      repeatDays: repeatDays ?? this.repeatDays,
      timezone: timezone,
      isActive: isActive ?? this.isActive,
      snoozeMinutes: snoozeMinutes,
    );
  }
}
