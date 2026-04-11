import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/core/models/reminder_model.dart';
import 'package:myapp/core/network/api_client.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/services/notification_service.dart';
import 'package:myapp/core/services/reminder_service.dart';
import 'package:myapp/screen/auth/login_screen.dart';

enum AlarmCategory { medicine, study, personal, work }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialUserName});

  final String? initialUserName;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ReminderService _reminderService = ReminderService();
  final AuthService _authService = AuthService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<ReminderModel> _alarms = <ReminderModel>[];
  final Set<String> _firedReminderKeys = <String>{};
  String userName = '';
  String userEmail = '';
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isAlarmDialogOpen = false;
  Timer? _alarmCheckTimer;

  static const String _alarmAssetPath = 'audio 2.wav';

  @override
  void initState() {
    super.initState();
    userName = widget.initialUserName?.trim() ?? '';
    _startAlarmWatcher();
    _bootstrap();
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await ApiClient.hydrateTokenFromStorage();
    await loadUserName();
    await _fetchReminders();
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName =
        prefs.getString('name') ??
        prefs.getString('userName') ??
        prefs.getString('fullname') ??
        '';
    final savedEmail = prefs.getString('userEmail') ?? '';

    if (!mounted) return;
    setState(() {
      if (savedName.isNotEmpty) {
        userName = savedName;
      }
      userEmail = savedEmail;
    });
  }

  Future<void> _fetchReminders() async {
    try {
      final reminders = await _reminderService.getReminders();
      reminders.sort((a, b) => a.time.compareTo(b.time));

      if (!mounted) return;
      setState(() {
        _alarms
          ..clear()
          ..addAll(reminders);
        _isLoading = false;
      });
      await NotificationService.instance.scheduleAllFromReminders(_alarms);
      _checkDueAlarms();
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }

      setState(() {
        _isLoading = false;
      });
      _showSnack(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                  'Failed to load reminders')
            : 'Failed to load reminders',
      );
    }
  }

  Future<void> _handleUnauthorized() async {
    await _authService.logout();
    if (!mounted) return;

    _showSnack('Session expired. Please login again.');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const loginPage()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const loginPage()),
      (route) => false,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startAlarmWatcher() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkDueAlarms();
    });
  }

  void _checkDueAlarms() {
    if (!mounted || _isAlarmDialogOpen) return;

    final now = DateTime.now();

    for (final reminder in _alarms) {
      if (!reminder.isActive) continue;

      final diffSeconds = now.difference(reminder.time).inSeconds;
      final reminderKey = '${reminder.id}_${reminder.time.toIso8601String()}';

      if (diffSeconds >= 0 && diffSeconds <= 30) {
        if (_firedReminderKeys.contains(reminderKey)) {
          continue;
        }

        _firedReminderKeys.add(reminderKey);
        _ringAlarm(reminder);
        break;
      }
    }
  }

  Future<void> _ringAlarm(ReminderModel reminder) async {
    if (!mounted) return;

    _isAlarmDialogOpen = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(_alarmAssetPath));
    } catch (_) {
      _showSnack('Alarm sound could not be played');
      _isAlarmDialogOpen = false;
      return;
    }

    if (!mounted) {
      _isAlarmDialogOpen = false;
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alarm Ringing'),
          content: Text('${reminder.title} is ringing now.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    _isAlarmDialogOpen = false;
  }

  Future<void> _toggleReminder(ReminderModel alarm, bool value) async {
    final oldValue = alarm.isActive;
    setState(() {
      alarm.isActive = value;
    });

    try {
      final updated = await _reminderService.updateReminder(
        id: alarm.id,
        isActive: value,
      );

      final index = _alarms.indexWhere((r) => r.id == alarm.id);
      if (index != -1 && mounted) {
        setState(() {
          _alarms[index] = updated;
        });
        await NotificationService.instance.scheduleReminder(updated);
      }
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        alarm.isActive = oldValue;
      });
      _showSnack('Failed to update reminder');
    }
  }

  Future<void> _deleteReminder(ReminderModel alarm) async {
    try {
      await _reminderService.deleteReminder(alarm.id);

      if (!mounted) return;
      setState(() {
        _alarms.removeWhere((r) => r.id == alarm.id);
      });
      await NotificationService.instance.cancelReminder(alarm.id);
      _showSnack('Reminder deleted');
    } on DioException catch (_) {
      if (!mounted) return;
      _showSnack('Failed to delete reminder');
    }
  }

  Future<void> _showDeleteConfirm(ReminderModel alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete reminder?'),
          content: Text('Delete "${alarm.title}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteReminder(alarm);
    }
  }

  Future<void> _showAddReminderSheet() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String repeat = 'none';
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setSheetState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text('Time: ${selectedTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: repeat,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Repeat',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Once')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() {
                          repeat = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) {
                                _showSnack('Title is required');
                                return;
                              }

                              setSheetState(() {
                                submitting = true;
                              });

                              final now = DateTime.now();
                              var scheduled = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                              if (scheduled.isBefore(now)) {
                                scheduled = scheduled.add(
                                  const Duration(days: 1),
                                );
                              }

                              try {
                                final created = await _reminderService
                                    .createReminder(
                                      title: title,
                                      description:
                                          descriptionController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : descriptionController.text.trim(),
                                      time: scheduled,
                                      repeat: repeat,
                                    );

                                if (!mounted) return;
                                setState(() {
                                  _alarms.add(created);
                                  _alarms.sort(
                                    (a, b) => a.time.compareTo(b.time),
                                  );
                                });
                                await NotificationService.instance
                                    .scheduleReminder(created);
                                Navigator.pop(ctx);
                                _showSnack('Reminder created');
                              } on DioException catch (e) {
                                _showSnack(
                                  e.response?.data is Map
                                      ? (e.response?.data['message']
                                                ?.toString() ??
                                            'Failed to create reminder')
                                      : 'Failed to create reminder',
                                );
                                setSheetState(() {
                                  submitting = false;
                                });
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Reminder'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ReminderModel? get _nextAlarm {
    final now = DateTime.now();
    final enabled = _alarms.where((a) => a.isActive).toList();
    if (enabled.isEmpty) return null;

    enabled.sort((a, b) {
      var aDiff = a.time.difference(now).inMinutes;
      var bDiff = b.time.difference(now).inMinutes;
      if (aDiff < 0) aDiff += 1440;
      if (bDiff < 0) bDiff += 1440;
      return aDiff.compareTo(bDiff);
    });

    return enabled.first;
  }

  int _minutesUntil(DateTime t) {
    final now = DateTime.now();
    var diff = t.difference(now).inMinutes;
    if (diff < 0) {
      diff += 1440;
    }
    return diff;
  }

  List<ReminderModel> get _historyReminders {
    final now = DateTime.now();
    final items = _alarms.where((r) => r.time.isBefore(now)).toList();
    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  List<ReminderModel> get _upcomingReminders {
    final now = DateTime.now();
    final items = _alarms.where((r) => r.time.isAfter(now)).toList();
    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  Widget _buildAlarmView() {
    final upcoming = _upcomingReminders;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSectionLabel('Alarm List'),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Text(
                'No upcoming alarms.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ...upcoming.map(_buildAlarmTile),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSectionLabel('Settings'),
          _buildSettingTile(
            icon: Icons.person_outline,
            title: 'Account',
            subtitle: userName.isEmpty ? 'Guest' : userName,
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: userEmail.isEmpty ? 'Not available' : userEmail,
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.refresh,
            title: 'Refresh reminders',
            subtitle: 'Sync latest reminder list',
            onTap: _fetchReminders,
          ),
          _buildSettingTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from this device',
            onTap: _logout,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    final history = _historyReminders;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSectionLabel('History'),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Text(
                'No history yet.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ...history.map(_buildHistoryTile),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return RefreshIndicator(
      onRefresh: _fetchReminders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildNextAlarmCard(),
            _buildStatsRow(),
            _buildSectionLabel('Today\'s alarms'),
            if (_alarms.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: Text(
                  'No reminders yet. Tap + to create one.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            ..._alarms.map(_buildAlarmTile),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyForTab() {
    if (_selectedIndex == 1) {
      return _buildAlarmView();
    }
    if (_selectedIndex == 2) {
      return _buildHistoryView();
    }
    if (_selectedIndex == 3) {
      return _buildSettingsView();
    }
    return _buildHomeView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildBodyForTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName.isEmpty ? 'Guest' : userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                userName.isNotEmpty
                    ? userName
                          .trim()
                          .split(' ')
                          .where((part) => part.isNotEmpty)
                          .take(2)
                          .map((part) => part[0])
                          .join()
                          .toUpperCase()
                    : 'G',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAlarmCard() {
    final next = _nextAlarm;
    if (next == null) return const SizedBox.shrink();

    final mins = _minutesUntil(next.time);
    final inText = mins < 60
        ? 'in $mins min'
        : 'in ${mins ~/ 60}h ${mins % 60}m';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -10,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _categoryLabel(
                        _categoryFromTitle(next.title),
                      ).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        inText,
                        style: const TextStyle(
                          color: Color(0xFFC4B5FD),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  TimeOfDay(
                    hour: next.time.hour,
                    minute: next.time.minute,
                  ).format(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final counts = {
      AlarmCategory.medicine: 0,
      AlarmCategory.study: 0,
      AlarmCategory.personal: 0,
      AlarmCategory.work: 0,
    };

    for (final a in _alarms) {
      final category = _categoryFromTitle(a.title);
      counts[category] = counts[category]! + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          _statCard(
            '💊',
            counts[AlarmCategory.medicine].toString(),
            'Medicine',
            const Color(0xFF4ADE80),
            const Color(0xFF052E16),
          ),
          const SizedBox(width: 10),
          _statCard(
            '📖',
            counts[AlarmCategory.study].toString(),
            'Study',
            const Color(0xFF818CF8),
            const Color(0xFF1E1B4B),
          ),
          const SizedBox(width: 10),
          _statCard(
            '🎯',
            counts[AlarmCategory.personal].toString(),
            'Personal',
            const Color(0xFFFB923C),
            const Color(0xFF431407),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String icon,
    String value,
    String label,
    Color iconColor,
    Color iconBg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildAlarmTile(ReminderModel alarm) {
    final category = _categoryFromTitle(alarm.title);
    final colors = _categoryColors(category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: alarm.isActive
              ? Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.$1.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _categoryEmoji(category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alarm.description?.isNotEmpty == true
                        ? alarm.description!
                        : 'No description',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  alarm.timeOfDay.format(context),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alarm.repeatLabel,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showDeleteConfirm(alarm),
              icon: const Icon(Icons.delete_outline, color: Color(0xFF94A3B8)),
            ),
            Switch(
              value: alarm.isActive,
              onChanged: (v) => _toggleReminder(alarm, v),
              activeThumbColor: const Color(0xFF6366F1),
              activeTrackColor: const Color(0xFF6366F1).withOpacity(0.4),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF334155),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(ReminderModel reminder) {
    final category = _categoryFromTitle(reminder.title);
    final colors = _categoryColors(category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.$1.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _categoryEmoji(category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reminder.time.day}/${reminder.time.month}/${reminder.time.year}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              reminder.timeOfDay.format(context),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _showAddReminderSheet,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.alarm_rounded, 'Alarms'),
      (Icons.history_rounded, 'History'),
      (Icons.settings_rounded, 'Settings'),
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$1,
                    color: selected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF475569),
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF475569),
                      fontSize: 10,
                    ),
                  ),
                  if (selected)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  AlarmCategory _categoryFromTitle(String title) {
    final text = title.toLowerCase();
    if (text.contains('med') ||
        text.contains('pill') ||
        text.contains('dose')) {
      return AlarmCategory.medicine;
    }
    if (text.contains('study') ||
        text.contains('exam') ||
        text.contains('read')) {
      return AlarmCategory.study;
    }
    if (text.contains('work') ||
        text.contains('meeting') ||
        text.contains('office')) {
      return AlarmCategory.work;
    }
    return AlarmCategory.personal;
  }

  String _categoryLabel(AlarmCategory cat) {
    return switch (cat) {
      AlarmCategory.medicine => 'Medicine reminder',
      AlarmCategory.study => 'Study session',
      AlarmCategory.personal => 'Personal',
      AlarmCategory.work => 'Work',
    };
  }

  String _categoryEmoji(AlarmCategory cat) {
    return switch (cat) {
      AlarmCategory.medicine => '💊',
      AlarmCategory.study => '📖',
      AlarmCategory.personal => '🎯',
      AlarmCategory.work => '💼',
    };
  }

  (Color, Color) _categoryColors(AlarmCategory cat) {
    return switch (cat) {
      AlarmCategory.medicine => (
        const Color(0xFF4ADE80),
        const Color(0xFF052E16),
      ),
      AlarmCategory.study => (const Color(0xFF818CF8), const Color(0xFF1E1B4B)),
      AlarmCategory.personal => (
        const Color(0xFFFB923C),
        const Color(0xFF431407),
      ),
      AlarmCategory.work => (const Color(0xFF38BDF8), const Color(0xFF0C4A6E)),
    };
  }
}
