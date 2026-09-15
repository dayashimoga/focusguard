import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/focus_schedule.dart';
import '../../persistence/schedule_repository.dart';

/// Screen for managing automated recurring focus schedules with timezone & DST safety.
class SchedulesScreen extends StatefulWidget {
  final ScheduleRepository scheduleRepository;

  const SchedulesScreen({super.key, required this.scheduleRepository});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  List<FocusSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final list = await widget.scheduleRepository.getAllSchedules();
    setState(() {
      _schedules = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Schedules'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primary,
        onPressed: () => _showAddScheduleDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Schedule',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule,
                          size: 64, color: AppConstants.textSecondaryDark),
                      const SizedBox(height: 16),
                      const Text(
                        'No Schedules Configured',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Automate focus during work hours, study, or bedtime.',
                        style: TextStyle(color: AppConstants.textSecondaryDark),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => _showAddScheduleDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Schedule'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _schedules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final schedule = _schedules[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  schedule.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: schedule.isEnabled,
                                  activeColor: AppConstants.primary,
                                  onChanged: (val) async {
                                    final updated =
                                        schedule.copyWith(isEnabled: val);
                                    await widget.scheduleRepository
                                        .updateSchedule(updated);
                                    await _loadSchedules();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatTime(schedule.startHour, schedule.startMinute)} – '
                              '${_formatTime(schedule.endHour, schedule.endMinute)}'
                              '${schedule.isOvernight ? " (Overnight)" : ""}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppConstants.accent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                for (int i = 1; i <= 7; i++)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: schedule.daysOfWeek.contains(i)
                                          ? AppConstants.primary
                                          : AppConstants.darkBorder,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _dayName(i),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: schedule.daysOfWeek.contains(i)
                                            ? Colors.white
                                            : AppConstants.textSecondaryDark,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: AppConstants.error),
                                  onPressed: () async {
                                    await widget.scheduleRepository
                                        .deleteSchedule(schedule.id);
                                    await _loadSchedules();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _dayName(int day) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[day - 1];
  }

  void _showAddScheduleDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'Workday Focus');
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    final selectedDays = <int>{1, 2, 3, 4, 5}; // Mon-Fri default

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.darkCard,
            title: const Text('Add Recurring Schedule',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Schedule Name'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context, initialTime: startTime);
                            if (picked != null) {
                              setDialogState(() => startTime = picked);
                            }
                          },
                          child: Text('Start: ${startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context, initialTime: endTime);
                            if (picked != null) {
                              setDialogState(() => endTime = picked);
                            }
                          },
                          child: Text('End: ${endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Repeat Days:',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final isSelected = selectedDays.contains(dayNum);
                      return FilterChip(
                        label: Text(_dayName(dayNum)),
                        selected: isSelected,
                        onSelected: (checked) {
                          setDialogState(() {
                            if (checked) {
                              selectedDays.add(dayNum);
                            } else if (selectedDays.length > 1) {
                              selectedDays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newSchedule = FocusSchedule(
                    id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
                    profileId: 'preset_deep_work',
                    name: nameController.text.trim(),
                    startHour: startTime.hour,
                    startMinute: startTime.minute,
                    endHour: endTime.hour,
                    endMinute: endTime.minute,
                    daysOfWeek: selectedDays.toList()..sort(),
                    isEnabled: true,
                  );
                  await widget.scheduleRepository.saveSchedule(newSchedule);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  await _loadSchedules();
                },
                child: const Text('Save Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }
}
