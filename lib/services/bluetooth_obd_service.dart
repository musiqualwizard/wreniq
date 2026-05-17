import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/live_data.dart';
import 'live_data_service.dart';

// ── Adapter state (FBP-agnostic enum exposed to the UI) ───────────────────────

enum ObdBtAdapterState { on, off, unavailable, unknown }

// ── Device wrapper ────────────────────────────────────────────────────────────

// Wraps a BluetoothDevice so the UI layer never imports flutter_blue_plus.
class ObdAdapterDevice {
  final BluetoothDevice device;
  final int rssi;

  const ObdAdapterDevice({required this.device, required this.rssi});

  static const List<String> _obd2Keywords = [
    'obd', 'elm', 'elm327', 'vgate', 'icar', 'fixd',
    'carista', 'veepeak', 'lelink', 'kiwi', 'bluedriver',
  ];

  // True when the advertised name matches a known OBD2 adapter keyword.
  bool get isLikelyObd2 {
    final name = device.platformName.toLowerCase();
    return _obd2Keywords.any((kw) => name.contains(kw));
  }

  String get displayName {
    final n = device.platformName;
    if (n.isNotEmpty) return n;
    final id = device.remoteId.str;
    return 'Unknown (${id.length > 8 ? id.substring(0, 8) : id}…)';
  }

  String get remoteId => device.remoteId.str;
}

// ── Service ───────────────────────────────────────────────────────────────────

// Thin BT OBD2 service. All vehicle data interactions are READ-ONLY.
// This service never writes to the vehicle ECU.
class BluetoothObdService {
  // ── Static state ─────────────────────────────────────────────────────────────

  static BluetoothDevice? _connectedDevice;

  static bool get isConnected => _connectedDevice?.isConnected ?? false;

  // ── Adapter-state stream ──────────────────────────────────────────────────────

  static Stream<ObdBtAdapterState> get adapterStateStream =>
      FlutterBluePlus.adapterState.map(_mapAdapterState);

  static ObdBtAdapterState _mapAdapterState(BluetoothAdapterState s) =>
      switch (s) {
        BluetoothAdapterState.on          => ObdBtAdapterState.on,
        BluetoothAdapterState.off         => ObdBtAdapterState.off,
        BluetoothAdapterState.unavailable => ObdBtAdapterState.unavailable,
        _                                 => ObdBtAdapterState.unknown,
      };

  // ── Scan streams ──────────────────────────────────────────────────────────────

  // Emits `true` while a BT scan is in progress.
  static Stream<bool> get isScanningStream => FlutterBluePlus.isScanning;

  // Emits the current list of named devices found during a scan,
  // sorted strongest-signal-first.
  static Stream<List<ObdAdapterDevice>> get scanResultStream =>
      FlutterBluePlus.scanResults.map(
        (results) => (results
                .where((r) => r.device.platformName.isNotEmpty)
                .map((r) => ObdAdapterDevice(device: r.device, rssi: r.rssi))
                .toList()
              ..sort((a, b) => b.rssi.compareTo(a.rssi))),
      );

  // Emits `false` when the connected device disconnects unexpectedly.
  // Returns null if no device is connected.
  static Stream<bool>? get connectedDeviceConnectionStream =>
      _connectedDevice?.connectionState
          .map((s) => s == BluetoothConnectionState.connected);

  // ── Permissions ───────────────────────────────────────────────────────────────

  // Returns null on success, or a user-facing error string on failure.
  static Future<String?> requestPermissions() async {
    if (!Platform.isAndroid) return null;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // On Android 12+ bluetoothScan is real; on older Android it auto-grants and
    // locationWhenInUse is what actually matters for BT scanning.
    final hasBt  = statuses[Permission.bluetoothScan]?.isGranted  == true;
    final hasLoc = statuses[Permission.locationWhenInUse]?.isGranted == true;

    if (hasBt || hasLoc) return null;

    final permanent = statuses.values.any((s) => s.isPermanentlyDenied);
    return permanent
        ? 'Permissions permanently denied. Open app Settings to enable Bluetooth.'
        : 'Bluetooth permissions are required to scan for OBD2 adapters.';
  }

  // ── Bluetooth enable ──────────────────────────────────────────────────────────

  // Android-only: prompts the user to enable Bluetooth. Silently no-ops on errors.
  static Future<void> enableBluetooth() async {
    if (!Platform.isAndroid) return;
    try { await FlutterBluePlus.turnOn(); } catch (_) {}
  }

  // ── Scan lifecycle ────────────────────────────────────────────────────────────

  static Future<void> startScan() async {
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: false,
    );
  }

  static Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // ── Connect / Disconnect ──────────────────────────────────────────────────────

  static Future<void> connect(ObdAdapterDevice adapter) async {
    await adapter.device.connect(timeout: const Duration(seconds: 15));
    _connectedDevice = adapter.device;
  }

  static Future<void> disconnect() async {
    final d = _connectedDevice;
    _connectedDevice = null;
    await d?.disconnect();
  }

  // ── Live data stream (Phase 13) ───────────────────────────────────────────────

  static Stream<LiveData> get liveDataStream => LiveDataService.stream();

  // ── Future live-read stubs (Phase 13+) ───────────────────────────────────────
  // These are READ-ONLY OBD-II PIDs. This service will never issue write commands.
  //
  // static Future<List<String>> readFaultCodes()     => throw UnimplementedError();
  // static Future<double?>      readRpm()            => throw UnimplementedError();
  // static Future<double?>      readCoolantTemp()    => throw UnimplementedError();
  // static Future<double?>      readBatteryVoltage() => throw UnimplementedError();
  // static Future<double?>      readFuelTrim()       => throw UnimplementedError();
}
