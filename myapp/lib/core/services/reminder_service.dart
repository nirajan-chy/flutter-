import 'package:dio/dio.dart';

import '../models/reminder_model.dart';
import '../network/api_client.dart';

class ReminderService {
  final Dio _dio = ApiClient.instance;

  Future<List<ReminderModel>> getReminders() async {
    final response = await _dio.get('/reminder/getAll');
    final data = response.data;

    if (data is Map && data['data'] is List) {
      final rows = List<Map<String, dynamic>>.from(data['data'] as List);
      return rows.map(ReminderModel.fromJson).toList();
    }

    return <ReminderModel>[];
  }

  Future<ReminderModel> createReminder({
    required String title,
    String? description,
    required DateTime time,
    String repeat = 'none',
    List<String> repeatDays = const <String>[],
    String timezone = 'UTC',
    int snoozeMinutes = 5,
  }) async {
    final response = await _dio.post(
      '/reminder/create',
      data: {
        'title': title,
        'description': description,
        'time': time.toUtc().toIso8601String(),
        'repeat': repeat,
        'repeatDays': repeatDays,
        'timezone': timezone,
        'snoozeMinutes': snoozeMinutes,
      },
    );

    final payload = Map<String, dynamic>.from(response.data as Map);
    return ReminderModel.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<ReminderModel> updateReminder({
    required String id,
    String? title,
    String? description,
    DateTime? time,
    String? repeat,
    List<String>? repeatDays,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};

    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (time != null) body['time'] = time.toUtc().toIso8601String();
    if (repeat != null) body['repeat'] = repeat;
    if (repeatDays != null) body['repeatDays'] = repeatDays;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _dio.patch('/reminder/update/$id', data: body);
    final payload = Map<String, dynamic>.from(response.data as Map);

    return ReminderModel.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<void> deleteReminder(String id) async {
    await _dio.delete('/reminder/delete/$id');
  }
}
