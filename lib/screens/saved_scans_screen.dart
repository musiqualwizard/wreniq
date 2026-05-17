import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class SavedScansScreen extends StatelessWidget {
  const SavedScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SAVED SCANS')),
      body: Consumer<ScanProvider>(
        builder: (context, sp, _) {
          if (sp.savedScans.isEmpty) return _emptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sp.savedScans.length,
            itemBuilder: (context, index) =>
                _ScanCard(scan: sp.savedScans[index]),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_camera_back_outlined, size: 64, color: AppTheme.chromeAccent),
          SizedBox(height: 16),
          Text('No saved scans',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Your analyzed parts will appear here.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final ScanResult scan;
  const _ScanCard({required this.scan});

  Color get _diffColor {
    switch (scan.repairDifficulty) {
      case 'Beginner':
        return AppTheme.success;
      case 'Advanced':
        return AppTheme.warning;
      default:
        return AppTheme.electricBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(scan.imagePath);

    return GestureDetector(
      onTap: () {
        // Make this scan the active result so ResultsScreen can display it
        context.read<ScanProvider>().viewSavedScan(scan);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: file.existsSync()
                  ? Image.file(file, height: 160, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      height: 100,
                      color: AppTheme.surface,
                      child: const Center(
                        child: Icon(Icons.car_repair, size: 40, color: AppTheme.electricBlue),
                      ),
                    ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scan.partName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                      _badge(
                        '${(scan.confidenceScore * 100).toStringAsFixed(0)}%',
                        AppTheme.electricBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(scan.vehicleInfo,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _badge(scan.repairDifficulty, _diffColor),
                      const SizedBox(width: 8),
                      _badge(scan.priceEstimate, const Color(0xFF00D4AA)),
                      const Spacer(),
                      _deleteButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _deleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmDelete(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.warning, size: 18),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Scan?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.chromeAccent)),
          ),
          TextButton(
            onPressed: () {
              context.read<ScanProvider>().deleteScan(scan.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }
}
