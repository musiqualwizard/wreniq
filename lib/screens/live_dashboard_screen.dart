import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/live_data.dart';
import '../services/live_data_service.dart';
import '../services/bluetooth_obd_service.dart';
import '../theme/app_theme.dart';

// ── Card state enum ───────────────────────────────────────────────────────────

enum _CardState { normal, warning, critical }

// ── Insight item ──────────────────────────────────────────────────────────────

class _InsightItem {
  final String message;
  final _CardState severity;
  const _InsightItem(this.message, this.severity);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class LiveDashboardScreen extends StatefulWidget {
  const LiveDashboardScreen({super.key});

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  // ── Theme constants ───────────────────────────────────────────────────────

  static const _electricBlue = Color(0xFF00B4FF);
  static const _teal         = Color(0xFF00D4AA);
  static const _amber        = Color(0xFFFF6B35);
  static const _yellow       = Color(0xFFFF9500);
  static const _purple       = Color(0xFF9C6FFF);
  static const _lightBlue    = Color(0xFF4A9EFF);
  static const _cardColor    = Color(0xFF1C1C2E);
  static const _red          = Color(0xFFFF3B30);
  static const _green        = Color(0xFF30D158);

  // ── State ─────────────────────────────────────────────────────────────────

  LiveData? _data;
  StreamSubscription<LiveData>? _dataSub;
  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _dataSub = LiveDataService.stream().listen((d) {
      if (mounted) setState(() => _data = d);
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isDemo => !BluetoothObdService.isConnected;

  String _formatRpm(double v) => _fmt.format(v.round());

  String _formatTime(DateTime t) => DateFormat('HH:mm:ss').format(t);

  // ── Insight generation ────────────────────────────────────────────────────

  List<_InsightItem> _generateInsights(LiveData d) {
    final items = <_InsightItem>[];

    if (d.isOverheating) {
      items.add(const _InsightItem(
          'Engine overheating — pull over safely and let the engine cool.',
          _CardState.critical));
    } else if (d.isTempHigh) {
      items.add(const _InsightItem(
          'Coolant temperature is elevated. Monitor closely.',
          _CardState.warning));
    }

    if (d.isLowVoltage) {
      items.add(const _InsightItem(
          'Battery voltage critically low — charging system may have failed.',
          _CardState.critical));
    } else if (d.isVoltageLow) {
      items.add(const _InsightItem(
          'Battery voltage slightly low. Check alternator output.',
          _CardState.warning));
    }

    if (d.isHighRpm) {
      items.add(const _InsightItem(
          'RPM is high — ease off the throttle to protect the engine.',
          _CardState.warning));
    }

    if (d.isCriticalFuel) {
      items.add(const _InsightItem(
          'Fuel critically low — refuel as soon as possible.',
          _CardState.critical));
    } else if (d.isFuelLow) {
      items.add(const _InsightItem(
          'Fuel level is low. Plan a stop at a fuel station soon.',
          _CardState.warning));
    }

    if (items.isEmpty) {
      items.add(const _InsightItem(
          'All systems normal. Engine data looks healthy.',
          _CardState.normal));
    }

    return items;
  }

  // ── Card color helpers ────────────────────────────────────────────────────

  Color _cardBg(_CardState state) => switch (state) {
        _CardState.critical => _red.withValues(alpha: 0.15),
        _CardState.warning  => _amber.withValues(alpha: 0.12),
        _CardState.normal   => _cardColor,
      };

  Color _insightIconColor(_CardState state) => switch (state) {
        _CardState.critical => _red,
        _CardState.warning  => _amber,
        _CardState.normal   => _green,
      };

  IconData _insightIcon(_CardState state) => switch (state) {
        _CardState.critical => Icons.error_rounded,
        _CardState.warning  => Icons.warning_amber_rounded,
        _CardState.normal   => Icons.check_circle_rounded,
      };

  // ── Metric card builder ───────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required double fraction,   // 0.0–1.0 for progress bar
    required Color accentColor,
    required _CardState state,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 120,
      decoration: BoxDecoration(
        color: _cardBg(state),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state == _CardState.normal
              ? accentColor.withValues(alpha: 0.25)
              : (state == _CardState.critical ? _red : _amber)
                    .withValues(alpha: 0.6),
          width: state == _CardState.normal ? 1 : 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      letterSpacing: 0.8)),
              if (state != _CardState.normal)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: state == _CardState.critical
                        ? _red.withValues(alpha: 0.3)
                        : _amber.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    state == _CardState.critical ? 'CRIT' : 'WARN',
                    style: TextStyle(
                      color:
                          state == _CardState.critical ? _red : _amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: double.parse(
                value.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '').isEmpty
                    ? '0'
                    : value.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), ''))),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, animVal, _) {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label == 'RPM'
                          ? _fmt.format(animVal.round())
                          : animVal.toStringAsFixed(
                              unit == 'V' ? 1 : (unit == '%' || unit == 'km/h' ? 0 : 0)),
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, animFrac, _) => LinearProgressIndicator(
              value: animFrac,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                state == _CardState.critical
                    ? _red
                    : state == _CardState.warning
                        ? _amber
                        : accentColor,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid builder ──────────────────────────────────────────────────────────

  Widget _buildDashboardGrid(LiveData d) {
    _CardState tempState = d.isOverheating
        ? _CardState.critical
        : d.isTempHigh
            ? _CardState.warning
            : _CardState.normal;

    _CardState battState = d.isLowVoltage
        ? _CardState.critical
        : d.isVoltageLow
            ? _CardState.warning
            : _CardState.normal;

    _CardState fuelState = d.isCriticalFuel
        ? _CardState.critical
        : d.isFuelLow
            ? _CardState.warning
            : _CardState.normal;

    _CardState rpmState =
        d.isHighRpm ? _CardState.warning : _CardState.normal;

    final metrics = [
      _buildMetricCard(
        label: 'RPM',
        value: _formatRpm(d.rpm),
        unit: 'rpm',
        fraction: d.rpm / 7000,
        accentColor: _electricBlue,
        state: rpmState,
      ),
      _buildMetricCard(
        label: 'SPEED',
        value: d.speedKmh.toStringAsFixed(0),
        unit: 'km/h',
        fraction: d.speedKmh / 180,
        accentColor: _teal,
        state: _CardState.normal,
      ),
      _buildMetricCard(
        label: 'ENGINE TEMP',
        value: d.coolantTempC.toStringAsFixed(0),
        unit: '°C',
        fraction: d.coolantTempC / 130,
        accentColor: _amber,
        state: tempState,
      ),
      _buildMetricCard(
        label: 'BATTERY',
        value: d.batteryVoltage.toStringAsFixed(1),
        unit: 'V',
        fraction: (d.batteryVoltage - 10) / 6,
        accentColor: _yellow,
        state: battState,
      ),
      _buildMetricCard(
        label: 'FUEL LEVEL',
        value: d.fuelLevelPct.toStringAsFixed(0),
        unit: '%',
        fraction: d.fuelLevelPct / 100,
        accentColor: _purple,
        state: fuelState,
      ),
      _buildMetricCard(
        label: 'ENGINE LOAD',
        value: d.engineLoadPct.toStringAsFixed(0),
        unit: '%',
        fraction: d.engineLoadPct / 100,
        accentColor: _lightBlue,
        state: _CardState.normal,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: metrics,
    );
  }

  // ── Insights card ─────────────────────────────────────────────────────────

  Widget _buildInsightsCard(LiveData d) {
    final insights = _generateInsights(d);
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppTheme.electricBlue, size: 18),
              const SizedBox(width: 8),
              Text('AI Insights',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_insightIcon(item.severity),
                        color: _insightIconColor(item.severity), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.message,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Demo banner ───────────────────────────────────────────────────────────

  Widget _buildDemoBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _purple, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo vehicle data active. Connect an OBD2 adapter for live readings.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer card ───────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        'Live data is for informational purposes only. '
        'This app never sends commands to the vehicle ECU. '
        'Always consult a qualified mechanic for diagnosis and repairs.',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'LIVE VEHICLE DATA',
          style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isDemo
                  ? _purple.withValues(alpha: 0.2)
                  : _green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isDemo
                    ? _purple.withValues(alpha: 0.5)
                    : _green.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _isDemo ? 'DEMO' : 'LIVE',
              style: TextStyle(
                  color: _isDemo ? _purple : _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1),
            ),
          ),
        ],
      ),
      body: _data == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00B4FF)))
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (_isDemo) ...[
                  _buildDemoBanner(),
                  const SizedBox(height: 14),
                ],
                _buildDashboardGrid(_data!),
                const SizedBox(height: 14),
                _buildInsightsCard(_data!),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Updated ${_formatTime(_data!.timestamp)} • 1s interval',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
                _buildDisclaimer(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
