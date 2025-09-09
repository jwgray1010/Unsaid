import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs - these should match your App Store Connect/Google Play Console setup
  static const String monthlySubscriptionId = 'unsaid_monthly_subscription';
  static const Set<String> _productIds = {monthlySubscriptionId};

  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  // Getters
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get loading => _loading;
  String? get queryProductError => _queryProductError;

  /// Initialize the subscription service
  Future<void> initialize() async {
    // Check if in-app purchase is available
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _isAvailable = false;
      _loading = false;
      notifyListeners();
      return;
    }

    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Load products and past purchases
    await _loadProducts();
    await _loadPastPurchases();

    _isAvailable = true;
    _loading = false;
    notifyListeners();
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse productDetailResponse =
          await _inAppPurchase.queryProductDetails(_productIds);

      if (productDetailResponse.error != null) {
        _queryProductError = productDetailResponse.error!.message;
        print('Error loading products: ${productDetailResponse.error}');
        return;
      }

      if (productDetailResponse.productDetails.isEmpty) {
        _queryProductError =
            'No products found. Check your product IDs in App Store Connect/Google Play Console.';
        print('Warning: No products found for IDs: $_productIds');
        return;
      }

      _products = productDetailResponse.productDetails;
      _queryProductError = null;
    } catch (e) {
      _queryProductError = 'Failed to load products: $e';
      print('Exception loading products: $e');
    }
  }

  /// Load past purchases
  Future<void> _loadPastPurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      // Note: restorePurchases() triggers the purchase stream with past purchases
      // so we don't need to handle the response directly here
    } catch (e) {
      print('Exception loading past purchases: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }

    // Update purchases list
    _purchases.addAll(purchaseDetailsList.where((p) =>
        p.status == PurchaseStatus.purchased ||
        p.status == PurchaseStatus.restored));
    notifyListeners();
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      _purchasePending = true;
      notifyListeners();
    } else {
      if (purchaseDetails.status == PurchaseStatus.error) {
        print('Purchase error: ${purchaseDetails.error}');
        _purchasePending = false;
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase with your backend here if needed
        await _verifyPurchase(purchaseDetails);
        _purchasePending = false;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }

      notifyListeners();
    }
  }

  /// Verify purchase (implement your backend verification here)
  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Implement server-side receipt validation
    // For now, we'll just mark it as successful locally
    print('Purchase verified: ${purchaseDetails.productID}');

    // Update local subscription status
    // You might want to save this to secure storage or sync with your backend
    if (purchaseDetails.productID == monthlySubscriptionId) {
      // User now has an active subscription
      await _activateSubscription(purchaseDetails);
    }
  }

  /// Activate subscription locally
  Future<void> _activateSubscription(PurchaseDetails purchaseDetails) async {
    // TODO: Save subscription status to secure storage
    // TODO: Sync with your backend
    // TODO: Update trial service status
    print('Subscription activated for product: ${purchaseDetails.productID}');
  }

  /// Start a subscription purchase
  Future<bool> purchaseSubscription() async {
    if (_products.isEmpty) {
      print('No products available for purchase');
      return false;
    }

    final ProductDetails productDetails = _products.first;
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    try {
      _purchasePending = true;
      notifyListeners();

      final bool success =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        _purchasePending = false;
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('Error purchasing subscription: $e');
      _purchasePending = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  /// Check if user has active subscription
  bool get hasActiveSubscription {
    return _purchases.any((purchase) =>
        purchase.productID == monthlySubscriptionId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored));
  }

  /// Get subscription product details
  ProductDetails? get subscriptionProduct {
    return _products.isNotEmpty ? _products.first : null;
  }

  /// Get formatted price
  String get subscriptionPrice {
    final product = subscriptionProduct;
    return product?.price ?? '\$2.99';
  }

  /// Dispose resources
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
