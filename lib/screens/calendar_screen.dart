import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_session.dart';
import 'session_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!.docs.map((doc) {
          return WorkoutSession.fromMap(
            doc.id,
            doc.data()! as Map<String, dynamic>,
          );
        }).toList();

        // Group sessions by calendar date
        final sessionsByDate = <DateTime, List<WorkoutSession>>{};
        for (final session in sessions) {
          final date = session.calendarDate;
          if (date == null) continue;
          final key = DateTime(date.year, date.month, date.day);
          sessionsByDate.putIfAbsent(key, () => []).add(session);
        }

        // Sessions for selected date
        final selectedSessions = sessionsByDate[_selectedDate] ?? [];

        return Column(
          children: [
            _MonthHeader(
              month: _focusedMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            _CalendarGrid(
              month: _focusedMonth,
              selectedDate: _selectedDate,
              sessionsByDate: sessionsByDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),
            const Divider(height: 1),
            Expanded(
              child: _DaySessionList(sessions: selectedSessions),
            ),
          ],
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            '${_monthNames[month.month - 1]} ${month.year}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Map<DateTime, List<WorkoutSession>> sessionsByDate;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.month,
    required this.selectedDate,
    required this.sessionsByDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    // Monday = 1, so offset is (weekday - 1) to start on Monday
    final startOffset = (firstDay.weekday - 1) % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Day-of-week headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            d,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Calendar cells
          ...List.generate(
            ((startOffset + lastDay.day + 6) ~/ 7),
            (week) {
              return Row(
                children: List.generate(7, (weekday) {
                  final dayIndex = week * 7 + weekday - startOffset + 1;
                  if (dayIndex < 1 || dayIndex > lastDay.day) {
                    return const Expanded(child: SizedBox(height: 44));
                  }
                  final date = DateTime(month.year, month.month, dayIndex);
                  final sessions = sessionsByDate[date];
                  final isSelected = date == selectedDate;
                  final isToday = date == todayKey;
                  final hasCompleted =
                      sessions?.any((s) => s.isCompleted) ?? false;
                  final hasScheduled =
                      sessions?.any((s) => s.isScheduled) ?? false;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDateSelected(date),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(40)
                              : null,
                          border: isToday
                              ? Border.all(
                                  color: theme.colorScheme.primary, width: 1.5)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayIndex',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight:
                                    isSelected ? FontWeight.bold : null,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            if (hasCompleted || hasScheduled)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasCompleted)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  if (hasCompleted && hasScheduled)
                                    const SizedBox(width: 2),
                                  if (hasScheduled)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.colorScheme.tertiary,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DaySessionList extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _DaySessionList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      'No sessions on this day',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Sort: scheduled first, then by time
    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) {
        if (a.isScheduled != b.isScheduled) {
          return a.isScheduled ? -1 : 1;
        }
        final aTime = a.calendarDate ?? DateTime(0);
        final bTime = b.calendarDate ?? DateTime(0);
        return aTime.compareTo(bTime);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final session = sorted[index];
        return _CalendarSessionTile(session: session);
      },
    );
  }
}

class _CalendarSessionTile extends StatelessWidget {
  final WorkoutSession session;

  const _CalendarSessionTile({required this.session});

  Future<void> _deleteSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(session.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isScheduled = session.isScheduled;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          isScheduled ? Icons.event : Icons.fitness_center,
          color: isScheduled
              ? theme.colorScheme.tertiary
              : theme.colorScheme.primary,
        ),
        title: Text(
          session.planName ?? 'Quick Workout',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isScheduled ? 'Scheduled' : 'Completed',
          style: TextStyle(
            color: isScheduled
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.journalEntry != null)
              Icon(Icons.book, size: 18, color: Colors.grey[500]),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _deleteSession(context),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          );
        },
      ),
    );
  }
}
