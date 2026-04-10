import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

enum AlarmCategory { medicine, study, personal, work }

class AlarmModel {
  final String id;
  final String name;
  final String subtitle;
  final TimeOfDay time;
  final AlarmCategory category;
  final String repeat;
  bool isEnabled;

  AlarmModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.time,
    required this.category,
    required this.repeat,
    this.isEnabled = true,
  });
}

// ─── Dashboard Screen ────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://localhost:5000';
    }
    return 'http://localhost:5000';
  }

  final List<AlarmModel> _alarms = [
    AlarmModel(
      id: '1',
      name: 'Morning Medicine',
      subtitle: 'Vitamin D · Omega 3',
      time: const TimeOfDay(hour: 8, minute: 30),
      category: AlarmCategory.medicine,
      repeat: 'Daily',
    ),
    AlarmModel(
      id: '2',
      name: 'Study Session',
      subtitle: 'Math · Physics',
      time: const TimeOfDay(hour: 10, minute: 0),
      category: AlarmCategory.study,
      repeat: 'Mon–Fri',
    ),
    AlarmModel(
      id: '3',
      name: 'Afternoon Dose',
      subtitle: 'Blood pressure pill',
      time: const TimeOfDay(hour: 13, minute: 0),
      category: AlarmCategory.medicine,
      repeat: 'Daily',
    ),
    AlarmModel(
      id: '4',
      name: 'Evening Walk',
      subtitle: '30 min workout',
      time: const TimeOfDay(hour: 18, minute: 30),
      category: AlarmCategory.personal,
      repeat: 'Daily',
      isEnabled: false,
    ),
    AlarmModel(
      id: '5',
      name: 'Night Medicine',
      subtitle: 'Sleep aid · Melatonin',
      time: const TimeOfDay(hour: 22, minute: 0),
      category: AlarmCategory.medicine,
      repeat: 'Daily',
    ),
  ];

  AlarmModel? get _nextAlarm {
    final now = TimeOfDay.now();
    final enabled = _alarms.where((a) => a.isEnabled).toList();
    enabled.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      final nowMin = now.hour * 60 + now.minute;
      final aDiff = (aMin - nowMin + 1440) % 1440;
      final bDiff = (bMin - nowMin + 1440) % 1440;
      return aDiff.compareTo(bDiff);
    });
    return enabled.isEmpty ? null : enabled.first;
  }

  int _minutesUntil(TimeOfDay t) {
    final now = TimeOfDay.now();
    final diff = (t.hour * 60 + t.minute) - (now.hour * 60 + now.minute);
    return diff < 0 ? diff + 1440 : diff;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildNextAlarmCard(),
                  _buildStatsRow(),
                  _buildSectionLabel('Today\'s alarms'),
                  ..._alarms.map(_buildAlarmTile),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(bottom: 90, right: 20, child: _buildFAB()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

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
                const Text(
                  'Aarav Singh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6366F1),
            child: const Text(
              'AS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Next Alarm Card ──────────────────────────────────────────────────────

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
                      _categoryLabel(next.category).toUpperCase(),
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
                  next.time.format(context),
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
                  next.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _actionPill('Snooze', false),
                    const SizedBox(width: 8),
                    _actionPill('Dismiss', true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionPill(String label, bool solid) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: solid ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: solid ? const Color(0xFF4F46E5) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final counts = {
      AlarmCategory.medicine: 0,
      AlarmCategory.study: 0,
      AlarmCategory.personal: 0,
    };
    for (final a in _alarms) {
      if (counts.containsKey(a.category))
        counts[a.category] = counts[a.category]! + 1;
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

  // ─── Section Label ────────────────────────────────────────────────────────

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

  // ─── Alarm Tile ───────────────────────────────────────────────────────────

  Widget _buildAlarmTile(AlarmModel alarm) {
    final colors = _categoryColors(alarm.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: alarm.isEnabled
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
                  _categoryEmoji(alarm.category),
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
                    alarm.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alarm.subtitle,
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
                  alarm.time.format(context),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alarm.repeat,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Switch(
              value: alarm.isEnabled,
              onChanged: (v) => setState(() => alarm.isEnabled = v),
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

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        // Navigate to add alarm screen
      },
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

  // ─── Bottom Nav ───────────────────────────────────────────────────────────

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

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
