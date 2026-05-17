import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/vin_decode_result.dart';
import '../providers/vehicle_provider.dart';
import '../services/vin_decoder_service.dart';
import '../theme/app_theme.dart';

// Add a new vehicle or edit an existing one.
// Pass [vehicle] to edit; omit (or null) to add.
class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;
  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _modelCtrl    = TextEditingController();
  final _trimCtrl     = TextEditingController();
  final _engineCtrl   = TextEditingController();
  final _vinCtrl      = TextEditingController();

  String? _year;
  String? _make;
  bool _isSaving   = false;
  bool _isDecoding = false;
  String? _vinDecodeError;
  String? _vinDecodeSuccess;

  bool get _isEditing => widget.vehicle != null;

  static final List<String> _years = List.generate(
    36, (i) => (2025 - i).toString(),
  );

  static const List<String> _makes = [
    'Acura','Audi','BMW','Buick','Cadillac','Chevrolet','Chrysler',
    'Dodge','Ford','GMC','Honda','Hyundai','Infiniti','Jeep','Kia',
    'Land Rover','Lexus','Lincoln','Mazda','Mercedes-Benz','Mitsubishi',
    'Nissan','RAM','Subaru','Tesla','Toyota','Volkswagen',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    if (v != null) {
      _nicknameCtrl.text = v.nickname;
      _modelCtrl.text    = v.model;
      _trimCtrl.text     = v.trim;
      _engineCtrl.text   = v.engine;
      _vinCtrl.text      = v.vin;
      _year = _years.contains(v.year) ? v.year : null;
      _make = _makes.contains(v.make) ? v.make : null;
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _modelCtrl.dispose();
    _trimCtrl.dispose();
    _engineCtrl.dispose();
    _vinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final vp  = context.read<VehicleProvider>();
    final now = DateTime.now();

    final updated = Vehicle(
      id:        _isEditing ? widget.vehicle!.id : now.millisecondsSinceEpoch.toString(),
      nickname:  _nicknameCtrl.text.trim(),
      year:      _year!,
      make:      _make!,
      model:     _modelCtrl.text.trim(),
      trim:      _trimCtrl.text.trim(),
      engine:    _engineCtrl.text.trim(),
      vin:       _vinCtrl.text.trim().toUpperCase(),
      createdAt: _isEditing ? widget.vehicle!.createdAt : now,
      isPrimary: _isEditing ? widget.vehicle!.isPrimary : false,
    );

    if (_isEditing) {
      await vp.updateVehicle(updated);
    } else {
      await vp.addVehicle(updated);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _decodeVin() async {
    setState(() {
      _isDecoding     = true;
      _vinDecodeError   = null;
      _vinDecodeSuccess = null;
    });

    try {
      final result = await VinDecoderService.decode(_vinCtrl.text);
      _applyDecodeResult(result);
      setState(() {
        _vinDecodeSuccess =
            'Decoded: ${result.year} ${result.make} ${result.model}';
        _isDecoding = false;
      });
    } on VinDecodeException catch (e) {
      setState(() {
        _vinDecodeError = e.message;
        _isDecoding     = false;
      });
    } catch (_) {
      setState(() {
        _vinDecodeError = 'Unexpected error. Please try again.';
        _isDecoding     = false;
      });
    }
  }

  // Mutates state fields and controllers directly; caller must call setState.
  void _applyDecodeResult(VinDecodeResult r) {
    if (_years.contains(r.year)) _year = r.year;

    final makeLower = r.make.toLowerCase();
    for (final m in _makes) {
      if (m.toLowerCase() == makeLower) { _make = m; break; }
    }

    if (r.model.isNotEmpty)  _modelCtrl.text  = _toTitleCase(r.model);
    if (r.trim.isNotEmpty)   _trimCtrl.text   = _toTitleCase(r.trim);
    if (r.engine.isNotEmpty) _engineCtrl.text = r.engine;
  }

  String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'EDIT VEHICLE' : 'ADD VEHICLE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: (_isSaving || _isDecoding) ? null : () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Nickname ──────────────────────────────────────────────────
            _fieldLabel('Nickname (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nicknameCtrl,
              decoration: _decor(
                hint: 'e.g. Daily Driver, Work Truck',
                icon: Icons.label_outline,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // ── Year & Make ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Year *'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_year),
                        initialValue: _year,
                        decoration: _decor(hint: 'Year', icon: Icons.calendar_today_outlined),
                        items: _years
                            .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (v) => setState(() => _year = v),
                        validator: (v) => v == null ? 'Required' : null,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Make *'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_make),
                        initialValue: _make,
                        decoration: _decor(hint: 'Make', icon: Icons.directions_car_outlined),
                        items: _makes
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => _make = v),
                        validator: (v) => v == null ? 'Required' : null,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Model ─────────────────────────────────────────────────────
            _fieldLabel('Model *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _modelCtrl,
              decoration: _decor(hint: 'e.g. Camry, F-150, Civic', icon: Icons.directions_car),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Model is required' : null,
            ),
            const SizedBox(height: 20),

            // ── Trim & Engine ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Trim / Grade'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _trimCtrl,
                        decoration: _decor(hint: 'e.g. LE, Sport, XLT', icon: Icons.tune),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Engine'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _engineCtrl,
                        decoration: _decor(hint: 'e.g. 2.5L 4-Cyl', icon: Icons.settings_outlined),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── VIN ───────────────────────────────────────────────────────
            _fieldLabel('VIN (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _vinCtrl,
              enabled: !_isDecoding,
              decoration: _decor(
                hint: '17-character VIN',
                icon: Icons.qr_code_outlined,
              ).copyWith(
                suffixIcon: _isDecoding
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.electricBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: _decodeVin,
                        child: const Text(
                          'DECODE VIN',
                          style: TextStyle(
                            color: AppTheme.electricBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(17),
              ],
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {
                _vinDecodeError   = null;
                _vinDecodeSuccess = null;
              }),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final vin = v.trim().toUpperCase();
                if (vin.length != 17) return 'VIN must be exactly 17 characters';
                if (RegExp(r'[IOQ]').hasMatch(vin)) {
                  return 'VIN cannot contain the letters I, O, or Q';
                }
                return null;
              },
            ),

            // Decode feedback
            if (_vinDecodeError != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.warning, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _vinDecodeError!,
                      style: const TextStyle(color: AppTheme.warning, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            if (_vinDecodeSuccess != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF00D4AA), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _vinDecodeSuccess!,
                        style: const TextStyle(
                            color: Color(0xFF00D4AA), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            _vinDisclaimer(),
            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isSaving || _isDecoding) ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isEditing ? 'SAVE CHANGES' : 'ADD VEHICLE'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: AppTheme.chromeAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      );

  InputDecoration _decor({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.chromeAccent, size: 18),
      );

  Widget _vinDisclaimer() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.electricBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppTheme.electricBlue.withValues(alpha: 0.2)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppTheme.electricBlue, size: 14),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'VIN data is provided by NHTSA and may be incomplete. '
                'Always verify your trim/engine.',
                style: TextStyle(
                    color: AppTheme.electricBlue, fontSize: 11, height: 1.5),
              ),
            ),
          ],
        ),
      );
}
