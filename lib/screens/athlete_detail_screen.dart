import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_program.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
import '../models/workout_plan.dart';
import '../widgets/workout_card.dart';
import '../widgets/plan_card.dart';
import '../widgets/session_card.dart';
import '../widgets/video_player.dart';
import '../widgets/recorded_video_tile.dart';

class AthleteDetailScreen extends StatelessWidget {
  final String athleteUid;
  final String athleteName;

  const AthleteDetailScreen({
    super.key,
    required this.athleteUid,
    required this.athleteName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(athleteName),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.folder_copy), text: 'Programs'),
              Tab(icon: Icon(Icons.assignment), text: 'Plans'),
              Tab(icon: Icon(Icons.history), text: 'Sessions'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AthleteProgramsTab(athleteUid: athleteUid),
            _AthletePlansTab(athleteUid: athleteUid),
            _AthleteSessionsTab(athleteUid: athleteUid),
            _AthleteCalendarTab(athleteUid: athleteUid),
          ],
        ),
      ),
    );
  }
}

// ── Programs tab ──────────────────────────────────────────────────────────────

class _AthleteProgramsTab extends StatelessWidget {
  final String athleteUid;
  const _AthleteProgramsTab({required this.athleteUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(athleteUid)
          .collection('programs')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No programs', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final program = WorkoutProgram.fromMap(
                docs[index].id, docs[index].data() as Map<String, dynamic>);
            return _ProgramTile(program: program, athleteUid: athleteUid);
          },
        );
      },
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final WorkoutProgram program;
  final String athleteUid;
  const _ProgramTile({required this.program, required this.athleteUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.folder, color: Colors.teal),
        title: Text(program.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: program.description != null
            ? Text(program.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(athleteUid)
                .collection('workouts')
                .where('programId', isEqualTo: program.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No workouts in this program',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final workout = Workout.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>);
                  return WorkoutCard(
                    workout: workout,
                    readOnly: true,
                    athleteUid: athleteUid,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Plans tab ─────────────────────────────────────────────────────────────────

class _AthletePlansTab extends StatelessWidget {
  final String athleteUid;
  const _AthletePlansTab({required this.athleteUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(athleteUid)
          .collection('plans')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No plans', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final plan = WorkoutPlan.fromMap(
                docs[index].id, docs[index].data() as Map<String, dynamic>);
            return PlanCard(plan: plan, readOnly: true);
          },
        );
      },
    );
  }
}

// ── Sessions tab ──────────────────────────────────────────────────────────────

class _AthleteSessionsTab extends StatelessWidget {
  final String athleteUid;
  const _AthleteSessionsTab({required this.athleteUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(athleteUid)
          .collection('sessions')
          .orderBy('startedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No sessions yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final session = WorkoutSession.fromMap(
                docs[index].id, docs[index].data() as Map<String, dynamic>);
            return SessionCard(
              session: session,
              readOnly: true,
              athleteUid: athleteUid,
            );
          },
        );
      },
    );
  }
}

// ── Calendar tab ──────────────────────────────────────────────────────────────

class _AthleteCalendarTab extends StatefulWidget {
  final String athleteUid;
  const _AthleteCalendarTab({required this.athleteUid});

  @override
  State<_AthleteCalendarTab> createState() => _AthleteCalendarTabState();
}

class _AthleteCalendarTabState extends State<_AthleteCalendarTab> {
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.athleteUid)
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
              child: _CalendarDayList(
                sessions: selectedSessions,
                athleteUid: widget.athleteUid,
              ),
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

class _CalendarDayList extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final String athleteUid;

  const _CalendarDayList({required this.sessions, required this.athleteUid});

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
        return _CalendarSessionTile(
          session: session,
          athleteUid: athleteUid,
        );
      },
    );
  }
}

class _CalendarSessionTile extends StatelessWidget {
  final WorkoutSession session;
  final String athleteUid;

  const _CalendarSessionTile({required this.session, required this.athleteUid});

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
        trailing: session.journalEntry != null
            ? Icon(Icons.book, size: 18, color: Colors.grey[500])
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(
                session: session,
                readOnly: true,
                athleteUid: athleteUid,
              ),
            ),
          );
        },
      ),
    );
  }
}
