import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_alert.dart';
import '../providers/vehicle_provider.dart';
import '../services/recall_service.dart';
import '../theme/app_theme.dart';

class RecallAlertsScreen extends StatelessWidget {
  const RecallAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vp, _) {
        final vehicle = vp.vehicle;
        final year  = vehicle?.year  ?? '';
        final make  = vehicle?.make  ?? '';
        final model = vehicle?.model ?? '';

        final recalls = vehicle != null
            ? RecallService.getMockRecalls(year: year, make: make, model: model)
            : RecallService.getMockRecalls(
                year: '2017', make: 'Toyota', model: 'Camry');

        return Scaffold(
          appBar: AppBar(title: const Text('RECALL ALERTS')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _vehicleCard(vehicle, year, make, model),
                const SizedBox(height: 14),
                _mockDisclaimer(),
                const SizedBox(height: 20),
                _sectionLabel('ACTIVE RECALLS'),
                const SizedBox(height: 12),
                if (recalls.isEmpty)
                  _emptyState()
                else
                  ...recalls.map(_recallCard),
                const SizedBox(height: 20),
                _nhtsaButton(
                    context: context,
                    year: year.isEmpty ? '2017' : year,
                    make: make.isEmpty ? 'Toyota' : make,
                    model: model.isEmpty ? 'Camry' : model),
                const SizedBox(height: 16),
                _disclaimerCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _vehicleCard(dynamic vehicle, String year, String make, String model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
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
                  vehicle != null ? '$year $make $model' : 'Demo Vehicle',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle != null
                      ? 'Showing recalls for your vehicle'
                      : '2017 Toyota Camry (no vehicle set)',
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

  Widget _mockDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFFF9500).withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined,
              color: Color(0xFFFF9500), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'DEMO DATA — These are sample recalls for illustration purposes. '
              'Tap "Check on NHTSA" below for real, live recall data for your vehicle.',
              style: TextStyle(
                  color: Color(0xFFFF9500), fontSize: 12, height: 1.4),
            ),
          ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
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

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_outlined, color: AppTheme.success, size: 40),
          SizedBox(height: 8),
          Text('No sample recalls for this vehicle year',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Verify on NHTSA for the most accurate data',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _nhtsaButton({
    required BuildContext context,
    required String year,
    required String make,
    required String model,
  }) {
    final url =
        RecallService.nhtsaSearchUrl(year: year, make: make, model: model);
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
        border: Border.all(
            color: AppTheme.chromeAccent.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'Recall data shown here is for demonstration only. Always check NHTSA.gov '
        'or contact your dealer for official, up-to-date recall information.',
        style: TextStyle(
            color: AppTheme.chromeAccent, fontSize: 11, height: 1.4),
      ),
    );
  }

  Color _severityColor(RecallSeverity s) => switch (s) {
        RecallSeverity.safety => const Color(0xFFFF3B30),
        RecallSeverity.emissions => const Color(0xFFFF9500),
        RecallSeverity.defect => AppTheme.electricBlue,
      };

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.chromeAccent,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600));
}
