import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/part_search_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PartsSearchService
//
// Phase 9: generates real vendor search URLs for 9 stores.
//
// Routing:
//   backend configured → GET /api/search-parts, fallback to local on error
//   no backend         → local link generation (no fake prices)
// ─────────────────────────────────────────────────────────────────────────────
class PartsSearchService {
  static Future<List<PartSearchResult>> search({
    required String year,
    required String make,
    required String model,
    required String engine,
    required String partName,
    List<String> suggestedSearchTerms = const [],
    double estimatedPriceLow  = 0.0,
    double estimatedPriceHigh = 0.0,
  }) async {
    if (ApiConfig.hasBackend) {
      try {
        return await _backendSearch(
          year: year, make: make, model: model,
          engine: engine, partName: partName,
          suggestedSearchTerms: suggestedSearchTerms,
        );
      } catch (_) {
        // fall through to local link generation
      }
    }
    return _localVendorLinks(
      year: year, make: make, model: model,
      engine: engine, partName: partName,
    );
  }

  // ── Backend call ──────────────────────────────────────────────────────────
  static Future<List<PartSearchResult>> _backendSearch({
    required String year,
    required String make,
    required String model,
    required String engine,
    required String partName,
    required List<String> suggestedSearchTerms,
  }) async {
    final uri = Uri.parse(ApiConfig.partsSearchUrl).replace(queryParameters: {
      'year':     year,
      'make':     make,
      'model':    model,
      'engine':   engine,
      'partName': partName,
      'suggestedSearchTerms': suggestedSearchTerms.join(','),
    });

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw const HttpException('Backend returned non-200 for parts search.');
    }

    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((item) => PartSearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── Client-side vendor link generation (no backend required) ──────────────
  // All results use real vendor search URLs. Prices/stock must be checked on site.
  static Future<List<PartSearchResult>> _localVendorLinks({
    required String year,
    required String make,
    required String model,
    required String engine,
    required String partName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final q  = Uri.encodeComponent('$partName $year $make $model');
    final qe = Uri.encodeComponent('$partName $year $make $model $engine');
    final vehicle = '$year $make $model';

    return [
      PartSearchResult(
        storeName:        'AutoZone',
        partTitle:        '$partName — $vehicle',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New',
        shippingOrPickup: 'Free store pickup or ship to home',
        productUrl:       'https://www.autozone.com/searchresult?searchText=$q',
        isLiveLink:       true,
        notes: 'Loan-A-Tool program available. Free battery and check-engine testing in-store.',
      ),
      PartSearchResult(
        storeName:        "O'Reilly Auto Parts",
        partTitle:        '$partName — $vehicle',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New',
        shippingOrPickup: 'Free store pickup or ship to home',
        productUrl:       'https://www.oreillyauto.com/search?q=$q',
        isLiveLink:       true,
        notes: 'Loan-A-Tool available. Price match guarantee.',
      ),
      PartSearchResult(
        storeName:        'Advance Auto Parts',
        partTitle:        '$partName — $vehicle',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New',
        shippingOrPickup: 'Free store pickup — online discount codes often available',
        productUrl:       'https://shop.advanceautoparts.com/web/endeca/search?searchTerm=$q',
        isLiveLink:       true,
        notes: 'Check for online-only promo codes before checkout.',
      ),
      PartSearchResult(
        storeName:        'NAPA Auto Parts',
        partTitle:        '$partName — $vehicle',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New',
        shippingOrPickup: 'In-store pickup or delivery',
        productUrl:       'https://www.napaonline.com/en/search?q=$q',
        isLiveLink:       true,
        notes: 'Pro-grade parts. Commercial accounts available.',
      ),
      PartSearchResult(
        storeName:        'RockAuto',
        partTitle:        '$partName — Multiple grades available',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New / Remanufactured',
        shippingOrPickup: 'Ships from warehouse — no local pickup',
        productUrl:       'https://www.rockauto.com',
        isLiveLink:       true,
        notes: 'Search by year / make / model on site. Economy, Standard, and OEM grades available.',
      ),
      PartSearchResult(
        storeName:        'eBay Motors',
        partTitle:        '$partName — $vehicle (New & Used listings)',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New & Used',
        shippingOrPickup: 'Varies by seller',
        productUrl:       'https://www.ebay.com/sch/i.html?_nkw=$qe&_sacat=6030',
        isLiveLink:       true,
        notes: 'Check seller rating and return policy. Inspect all photos before purchasing.',
      ),
      PartSearchResult(
        storeName:        'Amazon',
        partTitle:        '$partName — $vehicle',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New',
        shippingOrPickup: 'Prime delivery available on eligible items',
        productUrl:       'https://www.amazon.com/s?k=$q&rh=n%3A15684181',
        isLiveLink:       true,
        notes: 'Use the vehicle fitment filter on the results page. Verify seller reputation.',
      ),
      PartSearchResult(
        storeName:        'Walmart Auto',
        partTitle:        '$partName — $vehicle',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'New',
        shippingOrPickup: 'Ship to home or same-day pickup at many locations',
        productUrl:       'https://www.walmart.com/search?q=$q',
        isLiveLink:       true,
        notes: 'Check the automotive section filter. Pickup may be available same-day.',
      ),
      PartSearchResult(
        storeName:        'Car-Part.com',
        partTitle:        '$partName — Salvage / Used ($vehicle)',
        estimatedPrice:   'Check store',
        stockStatus:      'Check availability',
        condition:        'Used — Salvage',
        shippingOrPickup: 'Pickup from yard or freight shipping',
        productUrl:       'https://www.car-part.com/',
        isLiveLink:       true,
        notes: 'Search by year, make, and model on site. Verify mileage and OEM part number before ordering.',
      ),
    ];
  }
}
