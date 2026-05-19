import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_alert.dart';
import '../providers/vehicle_provider.dart';
import '../services/recall_service.dart';
import '../theme/app_theme.dart';

class RecallAlertsScreen extends StatefulWidget {
  const RecallAlertsScreen({super.key});

  @override
  State<RecallAlertsScreen> createState() => _RecallAlertsScreenState();
}

class _RecallAlertsScreenState extends State<RecallAlertsScreen> {
  late Future<List<RecallAlert>> _future;
  String _year = '', _make = '', _model = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vp = context.read<VehicleProvider>();
    final v  = vp.vehicle;
    _year  = v?.year  ?? '';
    _make  = v?.make  ?? '';
    _model = v?.model ?? '';
    _load();
  }

  void _load() {
    if (_year.isEmpty || _make.isEmpty || _model.isEmpty) {
      _future = Future.value([]);
    } else {
      _future = RecallService.fetchRecalls(
          year: _year, make: _make, model: _model);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>().vehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RECALL ALERTS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vehicleCard(vehicle),
            const SizedBox(height: 14),
            if (vehicle == null)
              _noVehicleState()
            else
              FutureBuilder<List<RecallAlert>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return _loadingState();
                  }
                  if (snap.hasError) {
                    return _errorState(snap.error.toString());
                  }
                  final recalls = snap.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ACTIVE RECALLS'),
                      const SizedBox(height: 12),
                      if (recalls.isEmpty)
                        _emptyState()
                      else
                        ...recalls.map(_recallCard),
                      const SizedBox(height: 20),
                      _nhtsaButton(context),
                      const SizedBox(height: 16),
                      _disclaimerCard(),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleCard(dynamic vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car,
                color: AppTheme.electricBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle != null
                      ? '$_year $_make $_model'
                      : 'No vehicle set',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle != null
                      ? 'Checking NHTSA for active recalls'
                      : 'Add a vehicle to check for recalls',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noVehicleState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.directions_car_outlined,
              color: AppTheme.chromeAccent, size: 44),
          SizedBox(height: 12),
          Text('No vehicle set',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          SizedBox(height: 4),
          Text('Add your vehicle in My Garage to check for active recalls.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.electricBlue),
            SizedBox(height: 16),
            Text('Checking NHTSA for recalls…',
                style: TextStyle(color: AppTheme.chromeAccent, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.warning, size: 36),
          const SizedBox(height: 10),
          const Text('Unable to load recalls',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _load()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          _nhtsaButton(context),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_outlined, color: AppTheme.success, size: 40),
          const SizedBox(height: 8),
          const Text('No active recalls found',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('No NHTSA recalls found for this vehicle.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          _nhtsaButton(context),
        ],
      ),
    );
  }

  Widget _recallCard(RecallAlert recall) {
    final color = _severityColor(recall.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(recall.severityLabel.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(recall.component,
                    style: const TextStyle(
                        color: AppTheme.chromeAccent, fontSize: 12)),
              ),
              Text(
                '${recall.reportedDate.month}/${recall.reportedDate.year}',
                style: const TextStyle(
                    color: AppTheme.chromeAccent, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(recall.title,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 6),
          Text(recall.description,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.build_outlined,
                  color: AppTheme.success, size: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Remedy: ${recall.remedy}',
                    style: const TextStyle(
                        color: AppTheme.success, fontSize: 12, height: 1.3),
                    maxLines: 2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('NHTSA #${recall.nhtsaNumber}',
              style: const TextStyle(
                  color: AppTheme.chromeAccent,
                  fontSize: 10,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _nhtsaButton(BuildContext context) {
    final url = RecallService.nhtsaSearchUrl(
      year:  _year.isEmpty  ? '2020' : _year,
      make:  _make.isEmpty  ? 'TOYOTA' : _make,
      model: _model.isEmpty ? 'CAMRY' : _model,
    );
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Check on NHTSA (Live Data)'),
      ),
    );
  }

  Widget _disclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'Recall data is fetched live from the NHTSA API. '
        'Always contact your dealer or check NHTSA.gov for the most current information.',
        style: TextStyle(
            color: AppTheme.chromeAccent, fontSize: 11, height: 1.4),
      ),
    );
  }

  Color _severityColor(RecallSeverity s) => switch (s) {
        RecallSeverity.safety    => const Color(0xFFFF3B30),
        RecallSeverity.emissions => const Color(0xFFFF9500),
        RecallSeverity.defect    => AppTheme.electricBlue,
      };

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.chromeAccent,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600));
}
