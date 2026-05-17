// A single vendor result returned by PartsSearchService.
class PartSearchResult {
  final String storeName;
  final String partTitle;
  final String estimatedPrice;    // "Check store" for live search links
  final String stockStatus;
  final String condition;
  final String shippingOrPickup;
  final String productUrl;
  final bool   isLiveLink;        // true = opens a real vendor search URL
  final String notes;

  const PartSearchResult({
    required this.storeName,
    required this.partTitle,
    required this.estimatedPrice,
    required this.stockStatus,
    required this.condition,
    required this.shippingOrPickup,
    required this.productUrl,
    this.isLiveLink = false,
    required this.notes,
  });

  factory PartSearchResult.fromJson(Map<String, dynamic> json) => PartSearchResult(
    storeName:        json['storeName']                       as String? ?? '',
    partTitle:        json['partTitle']                       as String? ?? '',
    estimatedPrice:   (json['estimatedPrice'] ?? json['price']) as String? ?? 'Check store',
    stockStatus:      json['stockStatus']                     as String? ?? 'Check availability',
    condition:        json['condition']                       as String? ?? 'New',
    shippingOrPickup: json['shippingOrPickup']                as String? ?? '',
    productUrl:       json['productUrl']                      as String? ?? '',
    isLiveLink:       json['isLiveLink']                      as bool?   ?? false,
    notes:            json['notes']                           as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'storeName':        storeName,
    'partTitle':        partTitle,
    'estimatedPrice':   estimatedPrice,
    'stockStatus':      stockStatus,
    'condition':        condition,
    'shippingOrPickup': shippingOrPickup,
    'productUrl':       productUrl,
    'isLiveLink':       isLiveLink,
    'notes':            notes,
  };
}
