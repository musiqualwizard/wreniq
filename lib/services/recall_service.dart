import '../models/recall_alert.dart';

// Returns mock recall data based on vehicle details.
// Phase 2: replace with live NHTSA API (api.nhtsa.gov/recalls/recallsByVehicle)
class RecallService {
  static const nhtsaSearchBase =
      'https://www.nhtsa.gov/vehicle/2023/MAKE/MODEL/PV/GAS';

  // Build NHTSA recall search URL for any vehicle.
  static String nhtsaSearchUrl({
    required String year,
    required String make,
    required String model,
  }) {
    final y = Uri.encodeComponent(year);
    final mk = Uri.encodeComponent(make.toUpperCase());
    final mo = Uri.encodeComponent(model.toUpperCase());
    return 'https://api.nhtsa.gov/recalls/recallsByVehicle?make=$mk&model=$mo&modelYear=$y';
  }

  // Returns a set of plausible mock recalls.
  // Always disclose isMock = true in the UI.
  static List<RecallAlert> getMockRecalls({
    required String year,
    required String make,
    required String model,
  }) {
    final y = int.tryParse(year) ?? 2015;

    final all = <RecallAlert>[
      if (y >= 2014 && y <= 2019)
        RecallAlert(
          id:           'mock-001',
          title:        'Takata Airbag Inflator Recall',
          description:  'The airbag inflator may rupture due to propellant degradation, '
              'potentially causing metal fragments to be propelled toward vehicle occupants.',
          component:    'Air Bags',
          severity:     RecallSeverity.safety,
          remedy:       'Dealers will replace the airbag inflator free of charge.',
          nhtsaNumber:  '16V-118-000',
          reportedDate: DateTime(2016, 5, 4),
          isMock:       true,
        ),
      if (y >= 2012 && y <= 2018)
        RecallAlert(
          id:           'mock-002',
          title:        'Fuel Pump Module Failure',
          description:  'The fuel pump module may fail, causing the engine to stall without warning. '
              'Engine stall at highway speed may increase the risk of a crash.',
          component:    'Fuel System',
          severity:     RecallSeverity.safety,
          remedy:       'Dealers will replace the fuel pump module at no charge.',
          nhtsaNumber:  '19V-432-000',
          reportedDate: DateTime(2019, 7, 15),
          isMock:       true,
        ),
      if (y >= 2018)
        RecallAlert(
          id:           'mock-003',
          title:        'Software Update — Infotainment System',
          description:  'A software defect in the infotainment module may cause unexpected '
              'touchscreen resets that could distract the driver.',
          component:    'Electrical System',
          severity:     RecallSeverity.defect,
          remedy:       'Dealers will reprogram the infotainment module free of charge.',
          nhtsaNumber:  '22V-815-000',
          reportedDate: DateTime(2022, 11, 3),
          isMock:       true,
        ),
      if (y >= 2015 && y <= 2022)
        RecallAlert(
          id:           'mock-004',
          title:        'NOx Emissions Exceedance',
          description:  'The vehicle may emit nitrogen oxide levels above EPA-regulated limits '
              'under certain real-world driving conditions.',
          component:    'Emission Control System',
          severity:     RecallSeverity.emissions,
          remedy:       'Dealers will reprogram the engine control module (ECM) at no charge.',
          nhtsaNumber:  '23E-021-000',
          reportedDate: DateTime(2023, 2, 28),
          isMock:       true,
        ),
    ];

    return all;
  }
}
