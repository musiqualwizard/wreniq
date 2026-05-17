// Decoded vehicle data returned by VinDecoderService (sourced from NHTSA).
class VinDecodeResult {
  final String vin;
  final String year;
  final String make;
  final String model;
  final String trim;
  final String engine;
  final String bodyClass;
  final String driveType;
  final String fuelType;
  final String rawErrorText; // full NHTSA error/status string for debugging

  const VinDecodeResult({
    required this.vin,
    required this.year,
    required this.make,
    required this.model,
    required this.trim,
    required this.engine,
    required this.bodyClass,
    required this.driveType,
    required this.fuelType,
    required this.rawErrorText,
  });
}
