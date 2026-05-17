import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/vin_decode_result.dart';

// Thrown for any decode failure — carries a user-facing message.
class VinDecodeException implements Exception {
  final String message;
  const VinDecodeException(this.message);
  @override
  String toString() => message;
}

// Decodes a 17-character VIN using the free NHTSA vPIC API.
// No API key required.  Endpoint docs:
//   https://vpic.nhtsa.dot.gov/api/
class VinDecoderService {
  static const _base =
      'https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues';
  static const _timeout = Duration(seconds: 20);

  // Valid VIN characters: digits + A-Z except I, O, Q
  static final _vinPattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  // ── Public entry point ─────────────────────────────────────────────────────

  static Future<VinDecodeResult> decode(String raw) async {
    final vin = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

    // Client-side validation before the network call
    if (vin.length != 17) {
      throw const VinDecodeException(
          'VIN must be exactly 17 characters. Please check and try again.');
    }
    if (!_vinPattern.hasMatch(vin)) {
      throw const VinDecodeException(
          'VIN contains invalid characters. '
          'Valid VINs do not use the letters I, O, or Q.');
    }

    // ── Network call ─────────────────────────────────────────────────────────
    final uri = Uri.parse('$_base/$vin?format=json');
    final http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } on SocketException {
      throw const VinDecodeException(
          'No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw const VinDecodeException(
          'Request timed out. Check your connection and try again.');
    }

    if (response.statusCode != 200) {
      throw VinDecodeException(
          'NHTSA API error (HTTP ${response.statusCode}). Please try again.');
    }

    // ── Parse outer envelope ──────────────────────────────────────────────────
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const VinDecodeException(
          'Unexpected response from NHTSA API. Please try again.');
    }

    final results = body['Results'] as List?;
    if (results == null || results.isEmpty) {
      throw const VinDecodeException(
          'No data returned for this VIN. Please verify the number and try again.');
    }

    final r = results.first as Map<String, dynamic>;

    // ── Validate decoded content ───────────────────────────────────────────────
    final year  = (r['ModelYear']  as String? ?? '').trim();
    final make  = (r['Make']       as String? ?? '').trim();
    final model = (r['Model']      as String? ?? '').trim();

    // NHTSA returns "0" for a clean decode; other codes indicate issues.
    // If the core identity fields are all empty the VIN wasn't recognised.
    if (year.isEmpty && make.isEmpty && model.isEmpty) {
      final errText = (r['ErrorText'] as String? ?? '').trim();
      throw VinDecodeException(
          errText.isNotEmpty ? _cleanErrorText(errText) : 'VIN not found in NHTSA database.');
    }

    return VinDecodeResult(
      vin:          vin,
      year:         year,
      make:         make,
      model:        model,
      trim:         (r['Trim']            as String? ?? '').trim(),
      engine:       _buildEngine(r),
      bodyClass:    (r['BodyClass']        as String? ?? '').trim(),
      driveType:    (r['DriveType']        as String? ?? '').trim(),
      fuelType:     (r['FuelTypePrimary']  as String? ?? '').trim(),
      rawErrorText: (r['ErrorText']        as String? ?? '').trim(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Construct a human-readable engine string from NHTSA displacement / cylinder fields.
  static String _buildEngine(Map<String, dynamic> r) {
    final disp = (r['DisplacementL']   as String? ?? '').trim();
    final cyl  = (r['EngineCylinders'] as String? ?? '').trim();
    final fuel = (r['FuelTypePrimary'] as String? ?? '').trim();

    final parts = <String>[];
    if (disp.isNotEmpty && disp != '0') {
      // Round to 1 decimal place so "1.9999" becomes "2.0L"
      final d = double.tryParse(disp);
      parts.add(d != null ? '${d.toStringAsFixed(1)}L' : '${disp}L');
    }
    if (cyl.isNotEmpty && cyl != '0') parts.add('$cyl-Cyl');
    if (fuel.isNotEmpty)              parts.add(fuel);
    return parts.join(' ');
  }

  // NHTSA error strings include the code prefix: "6 - Incomplete VIN…"
  // Strip it for display.
  static String _cleanErrorText(String raw) =>
      raw.replaceAll(RegExp(r'^\d+\s*-\s*'), '').trim();
}
