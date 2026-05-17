import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/diagnostic_code.dart';
import '../models/scan_result.dart';
import '../providers/vehicle_provider.dart';
import '../services/bluetooth_obd_service.dart';
import '../services/obd_service.dart';
import '../services/repair_estimate_service.dart';
import '../theme/app_theme.dart';
import 'find_parts_screen.dart';
import 'live_dashboard_screen.dart';
import 'mechanic_chat_screen.dart';
import 'repair_estimate_screen.dart';

class OBDScreen extends StatefulWidget {
  const OBDScreen({super.key});

  @override
  State<OBDScreen> createState() => _OBDScreenState();
}

class _OBDScreenState extends State<OBDScreen> {
  static const Color _amber  = Color(0xFFFF9500);
  static const Color _red    = Color(0xFFFF3B30);
  static const Color _yellow = Color(0xFFFFCC00);

  ObdScanSession? _session;
  bool _isScanning    = false;
  bool _isLoadingLast = true;
  final Set<String> _expanded = {};

  // ── Bluetooth state (Phase 12) ────────────────────────────────────────────────
  ObdBtAdapterState _btAdapterState = ObdBtAdapterState.unknown;
  bool _isBtScanning = false;
  List<ObdAdapterDevice> _nearbyDevices = [];
  ObdAdapterDevice? _connectingTo;
  ObdAdapterDevice? _connectedAdapter;
  String? _btError;

  StreamSubscription<ObdBtAdapterState>? _btStateSub;
  StreamSubscription<bool>? _btIsScanSub;
  StreamSubscription<List<ObdAdapterDevice>>? _btResultsSub;
  StreamSubscription<bool>? _connStateSub;

  @override
  void initState() {
    super.initState();
    _loadLastSession();
    _btStateSub = BluetoothObdService.adapterStateStream.listen((s) {
      if (mounted) setState(() => _btAdapterState = s);
    });
    _btIsScanSub = BluetoothObdService.isScanningStream.listen((scanning) {
      if (mounted) setState(() => _isBtScanning = scanning);
    });
    _btResultsSub = BluetoothObdService.scanResultStream.listen((devices) {
      if (mounted) setState(() => _nearbyDevices = devices);
    });
  }

  @override
  void dispose() {
    _btStateSub?.cancel();
    _btIsScanSub?.cancel();
    _btResultsSub?.cancel();
    _connStateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLastSession() async {
    final session = await ObdService.loadLastSession();
    if (mounted) {
      setState(() {
        _session       = session;
        _isLoadingLast = false;
      });
    }
  }

  Future<void> _scan() async {
    setState(() {
      _isScanning = true;
      _expanded.clear();
    });
    try {
      final session = await ObdService.scan();
      await ObdService.saveSession(session);
      if (mounted) {
        setState(() {
          _session    = session;
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    await ObdService.clearSession();
    if (mounted) setState(() => _session = null);
  }

  // ── Bluetooth methods (Phase 12) ──────────────────────────────────────────────

  Future<void> _requestPermissionsAndScan() async {
    setState(() => _btError = null);
    if (_btAdapterState == ObdBtAdapterState.off) {
      await BluetoothObdService.enableBluetooth();
      return;
    }
    final permError = await BluetoothObdService.requestPermissions();
    if (permError != null) {
      if (mounted) setState(() => _btError = permError);
      return;
    }
    try {
      if (mounted) setState(() => _nearbyDevices = []);
      await BluetoothObdService.startScan();
    } catch (e) {
      if (mounted) setState(() => _btError = _friendlyBtError(e));
    }
  }

  Future<void> _stopBtScan() => BluetoothObdService.stopScan();

  Future<void> _connectDevice(ObdAdapterDevice adapter) async {
    setState(() { _connectingTo = adapter; _btError = null; });
    try {
      await BluetoothObdService.stopScan();
      await BluetoothObdService.connect(adapter);
      _connStateSub?.cancel();
      _connStateSub = BluetoothObdService.connectedDeviceConnectionStream?.listen(
        (connected) {
          if (!connected && mounted) {
            setState(() { _connectedAdapter = null; _btError = 'Adapter disconnected.'; });
          }
        },
      );
      if (mounted) setState(() { _connectedAdapter = adapter; _connectingTo = null; });
    } catch (e) {
      if (mounted) setState(() { _connectingTo = null; _btError = _friendlyBtError(e); });
    }
  }

  Future<void> _disconnect() async {
    await BluetoothObdService.disconnect();
    _connStateSub?.cancel();
    if (mounted) setState(() { _connectedAdapter = null; _btError = null; });
  }

  String _friendlyBtError(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('timeout'))    return 'Connection timed out. Ensure the adapter is powered on.';
    if (m.contains('permission')) return 'Bluetooth permission denied. Check app Settings.';
    if (m.contains('not found'))  return 'Device not found. Try scanning again.';
    return 'Connection failed. Confirm the adapter is in pairing mode.';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VEHICLE DIAGNOSTICS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: (_isScanning || _isBtScanning || _connectingTo != null)
              ? null
              : () => Navigator.pop(context),
        ),
        actions: [
          if (_session != null && !_isScanning)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppTheme.chromeAccent,
              tooltip: 'Clear history',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildConnectionCard(),
          const SizedBox(height: 12),
          _buildLiveDashboardButton(),
          const SizedBox(height: 12),
          _buildDeviceDiscovery(),
          const SizedBox(height: 16),
          _buildScanButton(),
          const SizedBox(height: 24),
          if (_isLoadingLast) ...[
            const Center(child: CircularProgressIndicator(color: _amber)),
          ] else if (_session != null) ...[
            _buildSessionHeader(),
            const SizedBox(height: 12),
            ..._session!.codes.map(_buildCodeCard),
          ] else if (!_isScanning) ...[
            _buildEmptyState(),
          ],
          const SizedBox(height: 24),
          _buildDisclaimer(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Connection Card (replaces old Status Card) ───────────────────────────────

  Widget _buildConnectionCard() {
    final connected = _connectedAdapter != null;
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    if (connected) {
      color    = AppTheme.success;
      icon     = Icons.bluetooth_connected;
      title    = 'Connected: ${_connectedAdapter!.displayName}';
      subtitle = _isScanning ? 'Reading fault codes…' : 'Tap SCAN FOR CODES to read live data.';
    } else if (_isScanning) {
      color    = _amber;
      icon     = Icons.sensors;
      title    = 'Scanning…';
      subtitle = 'Reading fault codes from vehicle ECU…';
    } else if (_btAdapterState == ObdBtAdapterState.on) {
      color    = _amber;
      icon     = Icons.cable;
      title    = 'No Adapter Connected';
      subtitle = 'Scan for nearby OBD2 adapters below.';
    } else {
      color    = AppTheme.chromeAccent;
      icon     = Icons.electrical_services;
      title    = 'Demo Diagnostics Mode';
      subtitle = 'Enable Bluetooth and connect an OBD2 adapter for live data.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: _isScanning ? 0.6 : 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          if (_isScanning)
            SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: color, strokeWidth: 2)),
          if (connected && !_isScanning)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled, size: 18),
              color: AppTheme.chromeAccent,
              tooltip: 'Disconnect',
              onPressed: _disconnect,
            ),
        ],
      ),
    );
  }

  // ── Live Dashboard Button (Phase 13) ─────────────────────────────────────────

  Widget _buildLiveDashboardButton() {
    const teal = Color(0xFF00D4AA);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveDashboardScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.speed_rounded, color: teal, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live Vehicle Data',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Real-time OBD2 dashboard',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('LIVE',
                  style: TextStyle(
                      color: teal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.chromeAccent, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Device Discovery ─────────────────────────────────────────────────────────

  Widget _buildDeviceDiscovery() {
    // BT unavailable or unknown — don't show the section.
    if (_btAdapterState == ObdBtAdapterState.unavailable ||
        _btAdapterState == ObdBtAdapterState.unknown) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header + scan/stop button ──────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: Text('OBD2 ADAPTER',
                  style: TextStyle(
                      color: AppTheme.chromeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
            ),
            if (_btAdapterState == ObdBtAdapterState.off)
              _smallOutlinedButton(
                label: 'ENABLE BT',
                color: _amber,
                icon: Icons.bluetooth,
                onTap: BluetoothObdService.enableBluetooth,
              )
            else if (_isBtScanning)
              _smallOutlinedButton(
                label: 'STOP',
                color: AppTheme.warning,
                icon: Icons.stop,
                onTap: _stopBtScan,
              )
            else
              _smallOutlinedButton(
                label: 'FIND ADAPTER',
                color: _amber,
                icon: Icons.bluetooth_searching,
                onTap: _connectedAdapter != null ? null : _requestPermissionsAndScan,
              ),
          ],
        ),

        // ── Error banner ────────────────────────────────────────────────────
        if (_btError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.warning, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_btError!,
                      style: const TextStyle(
                          color: AppTheme.warning, fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        ],

        // ── Device list / scanning indicator ────────────────────────────────
        if (_nearbyDevices.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._nearbyDevices.map(_buildDeviceTile),
        ] else if (_isBtScanning) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _amber)),
                SizedBox(width: 12),
                Text('Scanning for nearby devices…',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceTile(ObdAdapterDevice adapter) {
    final isLikely     = adapter.isLikelyObd2;
    final isConnecting = _connectingTo?.remoteId == adapter.remoteId;
    final isConnected  = _connectedAdapter?.remoteId == adapter.remoteId;
    final accent       = isLikely ? _amber : AppTheme.chromeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected
              ? AppTheme.success.withValues(alpha: 0.5)
              : accent.withValues(alpha: isLikely ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isConnected ? AppTheme.success : accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(adapter.displayName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(
                  isLikely
                      ? 'OBD2 adapter • ${adapter.rssi} dBm'
                      : 'Other device • ${adapter.rssi} dBm',
                  style: TextStyle(
                      color: isLikely ? _amber : AppTheme.textSecondary,
                      fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('CONNECTED',
                  style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            )
          else
            SizedBox(
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLikely ? _amber : AppTheme.surface,
                  foregroundColor: isLikely ? Colors.black : AppTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: accent.withValues(alpha: 0.35)),
                  ),
                ),
                onPressed: isConnecting ? null : () => _connectDevice(adapter),
                child: isConnecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('CONNECT'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _smallOutlinedButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
  }) =>
      SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 14),
          label: Text(label),
        ),
      );

  // ── Scan Button ───────────────────────────────────────────────────────────────

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        onPressed: _isScanning ? null : _scan,
        icon: _isScanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
              )
            : const Icon(Icons.search, size: 20),
        label: Text(_isScanning
            ? 'SCANNING…'
            : _connectedAdapter != null
                ? 'SCAN LIVE CODES'
                : 'DEMO SCAN'),
      ),
    );
  }

  // ── Session Header ────────────────────────────────────────────────────────────

  Widget _buildSessionHeader() {
    final s = _session!;
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(s.scannedAt);
    final count   = s.codeCount;
    return Row(
      children: [
        const Icon(Icons.history, color: AppTheme.chromeAccent, size: 14),
        const SizedBox(width: 6),
        Text(
          dateStr,
          style: const TextStyle(color: AppTheme.chromeAccent, fontSize: 12),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ${count == 1 ? 'CODE' : 'CODES'} FOUND',
            style: const TextStyle(
              color: _amber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  // ── Code Card ─────────────────────────────────────────────────────────────────

  Widget _buildCodeCard(DiagnosticCode code) {
    final sColor   = _severityColor(code.severity);
    final isExpand = _expanded.contains(code.code);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Severity stripe + header ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Code badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    code.code,
                    style: TextStyle(
                      color: sColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    code.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Severity badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code.severityLabel,
                    style: TextStyle(
                      color: sColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explanation
                Text(
                  code.explanation,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Safe-to-drive row
                _buildSafeToDriveRow(code),
                const SizedBox(height: 8),

                // Est. repair cost
                Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: AppTheme.chromeAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Est. repair: ${code.estimatedRepairCost}',
                      style: const TextStyle(
                          color: AppTheme.chromeAccent, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Expandable possible causes
                GestureDetector(
                  onTap: () => setState(() {
                    if (isExpand) {
                      _expanded.remove(code.code);
                    } else {
                      _expanded.add(code.code);
                    }
                  }),
                  child: Row(
                    children: [
                      const Text(
                        'POSSIBLE CAUSES',
                        style: TextStyle(
                          color: AppTheme.chromeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpand
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.chromeAccent,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                if (isExpand) ...[
                  const SizedBox(height: 8),
                  ...code.possibleCauses.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: AppTheme.chromeAccent, fontSize: 13)),
                          Expanded(
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: _buildActionRow(code),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeToDriveRow(DiagnosticCode code) {
    final safe  = code.safeToDrive;
    final color = safe ? AppTheme.success : AppTheme.warning;
    final icon  = safe ? Icons.check_circle_outline : Icons.warning_amber_outlined;
    final label = safe ? 'Safe to drive (short term)' : 'Avoid heavy driving';
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionRow(DiagnosticCode code) {
    final vp          = context.read<VehicleProvider>();
    final vehicleInfo = vp.vehicle?.displayName;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon:  Icons.smart_toy_outlined,
                label: 'Ask Wreniq',
                color: const Color(0xFF9C6FFF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MechanicChatScreen(
                      vehicleInfo:    vehicleInfo,
                      initialMessage: 'Explain diagnostic code ${code.code}: '
                          '${code.title}. What should I do?',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon:  Icons.search,
                label: 'Find Parts',
                color: AppTheme.electricBlue,
                onTap: () {
                  final syntheticScan = ScanResult(
                    id:                   code.code,
                    imagePath:            '',
                    partName:             code.partSearchName,
                    confidenceScore:      1.0,
                    priceEstimate:        code.estimatedRepairCost,
                    estimatedPriceLow:    0.0,
                    estimatedPriceHigh:   0.0,
                    repairDifficulty:     'Intermediate',
                    toolsNeeded:          const [],
                    repairSteps:          const [],
                    buyOptions:           const [],
                    compatibleParts:      const [],
                    explanation:          code.explanation,
                    fitmentWarning:
                        'Verify diagnosis with a mechanic before purchasing parts.',
                    suggestedSearchTerms: code.suggestedSearchTerms,
                    safetyWarnings:       const [],
                    scannedAt:            code.detectedAt,
                    vehicleInfo:          vehicleInfo ?? '',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FindPartsScreen(scan: syntheticScan),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon:  Icons.build_outlined,
                label: 'Repair Guide',
                color: const Color(0xFF00D4AA),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MechanicChatScreen(
                      vehicleInfo:    vehicleInfo,
                      initialMessage: 'Give me a step-by-step repair guide for '
                          '${code.code}: ${code.title}.',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D4AA),
              side: BorderSide(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 9),
              textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final estimate = RepairEstimateService.estimateFromDiagCode(
                code,
                vehicleInfo: vehicleInfo ?? '',
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RepairEstimateScreen(estimate: estimate),
                ),
              );
            },
            icon: const Icon(Icons.calculate_outlined, size: 14),
            label: const Text('ESTIMATE REPAIR'),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          textStyle: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 13),
        label: Text(label),
      );

  // ── Empty State ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.electrical_services, color: AppTheme.chromeAccent, size: 44),
          SizedBox(height: 12),
          Text(
            'No diagnostic history',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Connect an OBD2 adapter above, or tap DEMO SCAN for sample codes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ────────────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _amber, size: 14),
              SizedBox(width: 8),
              Text(
                'DISCLAIMER',
                style: TextStyle(
                  color: _amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Diagnostic information is informational only and does not replace '
            'a professional inspection. Always verify repairs with a qualified '
            'mechanic before purchasing parts or performing work.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
          ),
          SizedBox(height: 6),
          Text(
            'Bluetooth adapter connection is available. Live code reading '
            '(RPM, coolant temp, fuel trims) will be added in a future update.',
            style:
                TextStyle(color: AppTheme.chromeAccent, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _severityColor(DiagnosticSeverity s) => switch (s) {
    DiagnosticSeverity.critical => _red,
    DiagnosticSeverity.high     => AppTheme.warning,
    DiagnosticSeverity.medium   => _yellow,
    DiagnosticSeverity.low      => AppTheme.electricBlue,
  };
}
