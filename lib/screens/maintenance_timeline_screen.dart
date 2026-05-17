import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_event.dart';
import '../providers/maintenance_provider.dart';
import '../theme/app_theme.dart';

class MaintenanceTimelineScreen extends StatelessWidget {
  const MaintenanceTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAINTENANCE TIMELINE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.electricBlue),
            tooltip: 'Add event',
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Consumer<MaintenanceProvider>(
        builder: (context, mp, _) {
          if (mp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(context, mp);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MaintenanceProvider mp) {
    final overdue  = mp.overdueEvents;
    final upcoming = mp.upcomingEvents;
    final all      = mp.events;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary row
        _buildSummaryRow(mp),
        const SizedBox(height: 20),

        // Overdue alerts
        if (overdue.isNotEmpty) ...[
          _sectionLabel('Overdue'),
          const SizedBox(height: 10),
          ...overdue.map((e) => _EventTile(
            event:    e,
            accent:   AppTheme.warning,
            onDelete: () => _deleteEvent(context, mp, e.id),
          )),
          const SizedBox(height: 20),
        ],

        // Due soon
        if (upcoming.isNotEmpty) ...[
          _sectionLabel('Due Soon'),
          const SizedBox(height: 10),
          ...upcoming.map((e) => _EventTile(
            event:    e,
            accent:   const Color(0xFFFF9500),
            onDelete: () => _deleteEvent(context, mp, e.id),
          )),
          const SizedBox(height: 20),
        ],

        // Full history
        _sectionLabel('History'),
        const SizedBox(height: 10),

        if (all.isEmpty)
          _buildEmptyState(context)
        else
          ...all.map((e) => _EventTile(
            event:    e,
            accent:   AppTheme.electricBlue,
            onDelete: () => _deleteEvent(context, mp, e.id),
          )),

        const SizedBox(height: 24),
        _buildAddButton(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSummaryRow(MaintenanceProvider mp) {
    final cost = mp.totalTrackedCost;
    return Row(
      children: [
        Expanded(child: _summaryTile(
          label: 'Events',
          value: '${mp.events.length}',
          icon:  Icons.history,
          color: AppTheme.electricBlue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _summaryTile(
          label: 'Overdue',
          value: '${mp.overdueEvents.length}',
          icon:  Icons.warning_amber_rounded,
          color: mp.overdueEvents.isNotEmpty ? AppTheme.warning : AppTheme.chromeAccent,
        )),
        const SizedBox(width: 12),
        Expanded(child: _summaryTile(
          label: 'Tracked Cost',
          value: cost > 0 ? '\$${cost.toStringAsFixed(0)}' : '—',
          icon:  Icons.attach_money,
          color: const Color(0xFF00D4AA),
        )),
      ],
    );
  }

  Widget _summaryTile({
    required String   label,
    required String   value,
    required IconData icon,
    required Color    color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off_outlined,
              color: AppTheme.chromeAccent, size: 40),
          const SizedBox(height: 12),
          const Text('No maintenance events yet',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          const Text('Tap + to log an oil change, brake job, or other service',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add, color: AppTheme.electricBlue),
            label: const Text('Add First Event',
                style: TextStyle(color: AppTheme.electricBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('LOG MAINTENANCE EVENT'),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.chromeAccent,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _deleteEvent(BuildContext context, MaintenanceProvider mp, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Event?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.chromeAccent)),
          ),
          TextButton(
            onPressed: () {
              mp.deleteEvent(id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }

  // ── Add Event Dialog ────────────────────────────────────────────────────────

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _AddEventSheet(
          onAdd: (event) {
            context.read<MaintenanceProvider>().addEvent(event);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}

// ── Event Tile ────────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final MaintenanceEvent event;
  final Color            accent;
  final VoidCallback     onDelete;

  const _EventTile({
    required this.event,
    required this.accent,
    required this.onDelete,
  });

  IconData get _typeIcon => switch (event.type) {
    MaintenanceType.oilChange   => Icons.opacity,
    MaintenanceType.brakes      => Icons.disc_full,
    MaintenanceType.tires       => Icons.tire_repair,
    MaintenanceType.battery     => Icons.battery_charging_full,
    MaintenanceType.repair      => Icons.build_outlined,
    MaintenanceType.inspection  => Icons.search,
    MaintenanceType.other       => Icons.event_note_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${event.typeLabel}  ·  ${fmt.format(event.date)}'
                  '${event.mileage != null ? '  ·  ${event.mileage} mi' : ''}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (event.nextDueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        event.isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.schedule,
                        size: 12,
                        color: event.isOverdue ? AppTheme.warning : AppTheme.chromeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Next due: ${fmt.format(event.nextDueDate!)}'
                        '${event.isOverdue ? ' (OVERDUE)' : ''}',
                        style: TextStyle(
                          color: event.isOverdue
                              ? AppTheme.warning
                              : AppTheme.chromeAccent,
                          fontSize: 11,
                          fontWeight: event.isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.cost != null)
                  Text('\$${event.cost!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Color(0xFF00D4AA),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.chromeAccent, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        ],
      ),
    );
  }
}

// ── Add Event Bottom Sheet ────────────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final void Function(MaintenanceEvent) onAdd;
  const _AddEventSheet({required this.onAdd});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  MaintenanceType _type    = MaintenanceType.oilChange;
  final _titleCtrl         = TextEditingController();
  final _notesCtrl         = TextEditingController();
  final _mileageCtrl       = TextEditingController();
  final _costCtrl          = TextEditingController();
  DateTime  _date          = DateTime.now();
  DateTime? _nextDue;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _mileageCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, {bool isNext = false}) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: isNext ? (_nextDue ?? DateTime.now()) : _date,
      firstDate: isNext ? DateTime.now() : DateTime(2010),
      lastDate: isNext ? DateTime(2040) : DateTime.now(),
      builder: (_, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isNext) {
        _nextDue = picked;
      } else {
        _date = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.chromeAccent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('LOG MAINTENANCE EVENT',
              style: TextStyle(
                  color: AppTheme.electricBlue,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // Type picker
          _label('Event Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MaintenanceType.values.map((t) {
              final sel = t == _type;
              final label = switch (t) {
                MaintenanceType.oilChange   => 'Oil Change',
                MaintenanceType.brakes      => 'Brakes',
                MaintenanceType.tires       => 'Tires',
                MaintenanceType.battery     => 'Battery',
                MaintenanceType.repair      => 'Repair',
                MaintenanceType.inspection  => 'Inspection',
                MaintenanceType.other       => 'Other',
              };
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.electricBlue.withValues(alpha: 0.15)
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? AppTheme.electricBlue
                            : AppTheme.chromeAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: sel
                              ? AppTheme.electricBlue
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Title
          _label('Title'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Synthetic oil change 5W-30',
            ),
          ),

          const SizedBox(height: 12),

          // Date + cost row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Date'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.chromeAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(fmt.format(_date),
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Cost (\$) — optional'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _costCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(hintText: '0.00'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Next due date
          _label('Next Due Date — optional'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _pickDate(context, isNext: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.chromeAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                _nextDue != null ? fmt.format(_nextDue!) : 'Tap to set reminder date',
                style: TextStyle(
                    color: _nextDue != null
                        ? AppTheme.textPrimary
                        : AppTheme.chromeAccent,
                    fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title.')),
                  );
                  return;
                }
                final event = MaintenanceEvent(
                  id:          DateTime.now().millisecondsSinceEpoch.toString(),
                  type:        _type,
                  title:       _titleCtrl.text.trim(),
                  notes:       _notesCtrl.text.trim(),
                  date:        _date,
                  mileage:     int.tryParse(_mileageCtrl.text),
                  nextDueDate: _nextDue,
                  cost:        double.tryParse(_costCtrl.text),
                );
                widget.onAdd(event);
              },
              child: const Text('SAVE EVENT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
        color: AppTheme.chromeAccent, fontSize: 11, letterSpacing: 1.5),
  );
}
