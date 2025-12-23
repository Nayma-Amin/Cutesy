import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/confirm_order.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/screens/home_page.dart';
import 'package:shop_cutesy/screens/coupon_page.dart';
import 'package:shop_cutesy/screens/profile_page.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int bottomIndex = 2;
  bool menuVisible = false;
  String userRole = "user";
  bool _animate = false;
  String username = "";

  final user = FirebaseAuth.instance.currentUser;

  final Set<String> selectedIds = {};
  bool selectAll = false;

  List<_CartItem> inStockItems = [];
  List<_CartItem> outOfStockItems = [];

  List<_CartItem> _getSelectedItems() {
    return inStockItems.where((item) => selectedIds.contains(item.id)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      username = "";
      userRole = "user";
      setState(() => _animate = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    username = doc['name'] ?? "";
    userRole = doc['role'] ?? "user";

    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _animate = true);
  }

  int _calculateItemTotal(_CartItem item) {
    final originalTotal = item.unitPrice * item.quantity;

    if (item.discountPercentage > 0) {
      return (originalTotal - (originalTotal * item.discountPercentage / 100))
          .round();
    }

    return originalTotal;
  }

  int _calculateSelectedTotal(List<_CartItem> items) {
    int sum = 0;
    for (final item in items) {
      sum += _calculateItemTotal(item);
    }
    return sum;
  }

  Future<Map<String, dynamic>?> _getActiveDiscountForTag(String tag) async {
    final now = Timestamp.now();

    final snap = await FirebaseFirestore.instance
        .collection('discounts')
        .where('start_at', isLessThanOrEqualTo: now)
        .where('end_at', isGreaterThan: now)
        .get();

    Map<String, dynamic>? allDiscount;

    for (final doc in snap.docs) {
      final data = doc.data();
      final tags = List<String>.from(data['tags'] ?? []);

      if (tags.contains(tag)) return data;
      if (tags.contains("All")) allDiscount ??= data;
    }

    return allDiscount;
  }

  Future<void> _loadCart() async {
    if (user == null) return;

    final cartSnap = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: user!.uid)
        .get();

    List<_CartItem> inStock = [];
    List<_CartItem> outStock = [];

    for (final doc in cartSnap.docs) {
      final data = doc.data();

      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(data['productId'])
          .get();

      int productQty = 0;
      if (productDoc.exists) {
        productQty =
            int.tryParse(productDoc['quantity']?.toString() ?? '0') ?? 0;
      }

      String productImage = '';

      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final images = List<String>.from(productData['images'] ?? []);

        if (images.isNotEmpty) {
          productImage = images[0];
        }
      }

      final productTag = productDoc.exists ? productDoc['tag'] ?? '' : '';

      final int unitPrice = (data['unitPrice'] is int) ? data['unitPrice'] : 0;
      final int quantity = (data['quantity'] is int && data['quantity'] > 0)
          ? data['quantity']
          : 1;

      int discountPercentage = data['discountPercentage'] ?? 0;
      int discountedUnitPrice = data['discountedUnitPrice'] ?? 0;
      int discountedTotalPrice = data['discountedTotalPrice'] ?? 0;
      Timestamp? discountEndAt = data['discountEndAt'];

      final discount = await _getActiveDiscountForTag(productTag);

      bool needsUpdate = false;

      if (discount == null) {
        if (discountPercentage != 0) {
          discountPercentage = 0;
          discountedUnitPrice = 0;
          discountedTotalPrice = 0;
          discountEndAt = null;
          needsUpdate = true;
        }
      } else {
        final newPercentage = discount['percentage'] ?? 0;

        if (newPercentage != discountPercentage) {
          discountPercentage = newPercentage;
          discountEndAt = discount['end_at'];

          discountedUnitPrice =
              (unitPrice - (unitPrice * discountPercentage / 100)).round();
          discountedTotalPrice = discountedUnitPrice * quantity;

          needsUpdate = true;
        }
      }

      final effectiveTotal = discountedTotalPrice > 0
          ? discountedTotalPrice
          : unitPrice * quantity;

      final originalTotal = unitPrice * quantity;
      final finalDiscountedTotal = discountedTotalPrice > 0
          ? discountedTotalPrice
          : 0;

      final cartItem = _CartItem(
        id: doc.id,
        productId: data['productId'],
        title: productDoc.exists ? productDoc['title'] ?? '' : '',
        unitPrice: unitPrice,
        totalPrice: effectiveTotal,
        originalTotal: originalTotal,
        discountedTotal: finalDiscountedTotal,
        discountPercentage: discountPercentage,
        image: productImage,
        option: data['option'] ?? '',
        quantity: quantity,
        stock: productQty,
      );

      if (productQty >= quantity) {
        inStock.add(cartItem);
      } else {
        outStock.add(cartItem);
      }

      if (needsUpdate) {
        await FirebaseFirestore.instance.collection('cart').doc(doc.id).update({
          'discountPercentage': discountPercentage,
          'discountedUnitPrice': discountedUnitPrice,
          'discountedTotalPrice': discountedTotalPrice,
          'discountEndAt': discountEndAt,
          'totalPrice': effectiveTotal,
        });
      }
    }
    setState(() {
      inStockItems = inStock;
      outOfStockItems = outStock;
      selectedIds.clear();
      selectAll = false;
    });
  }

  void _showOrderSummaryDialog() {
    final selectedItems = _getSelectedItems();
    if (selectedItems.isEmpty) return;

    int totalPrice = 0;
    for (final item in selectedItems) {
      final originalTotal = item.unitPrice * item.quantity;
      final discountedTotal = item.discountPercentage > 0
          ? (originalTotal - (originalTotal * item.discountPercentage / 100))
                .round()
          : originalTotal;
      totalPrice += discountedTotal;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF1F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Order Summary",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...selectedItems.map((item) {
                  final itemTotal = item.discountPercentage > 0
                      ? (item.unitPrice * item.quantity -
                                (item.unitPrice *
                                    item.quantity *
                                    item.discountPercentage /
                                    100))
                            .round()
                      : item.unitPrice * item.quantity;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text("Category: ${item.option}"),
                        Text("Quantity: ${item.quantity}"),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "৳$itemTotal",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (item.discountPercentage > 0)
                              Text(
                                "৳${item.unitPrice * item.quantity}",
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            if (item.discountPercentage > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  "-${item.discountPercentage}%",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 18),
                      ],
                    ),
                  );
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "৳$totalPrice",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Delivery charge not included",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB564F7),
              ),
              onPressed: () {
                final selectedItemsForOrder = _getSelectedItems()
                    .map(
                      (item) => CartItem(
                        id: item.id,
                        productId: item.productId,
                        title: item.title,
                        unitPrice: item.unitPrice,
                        totalPrice: item.totalPrice,
                        image: item.image,
                        option: item.option,
                        quantity: item.quantity,
                        stock: item.stock,
                        originalTotal: item.originalTotal,
                        discountedTotal: item.discountedTotal,
                        discountPercentage: item.discountPercentage, productTag: '',
                      ),
                    )
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ConfirmOrder(selectedItems: selectedItemsForOrder),
                  ),
                );
              },
              child: const Text(
                "Proceed",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      selectedIds.clear();

      if (selectAll) {
        for (final item in inStockItems) {
          selectedIds.add(item.id);
        }
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }

      selectAll = selectedIds.length == inStockItems.length;
    });
  }

  Future<void> _confirmDelete(String cartId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove item?"),
        content: const Text("Do you want to remove this item from your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('cart').doc(cartId).delete();
      _loadCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Deleted successfully"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateQuantity(_CartItem item, int newQty) async {
    if (newQty < 1) return;

    if (newQty > 10) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Limit reached"),
          content: const Text("You can only order 10 at once!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final originalTotal = item.unitPrice * newQty;

    final discountedTotal = item.discountPercentage > 0
        ? (originalTotal - (originalTotal * item.discountPercentage / 100))
              .round()
        : 0;

    final effectiveTotal = discountedTotal > 0
        ? discountedTotal
        : originalTotal;

    await FirebaseFirestore.instance.collection('cart').doc(item.id).update({
      'quantity': newQty,
      'totalPrice': effectiveTotal,
      'discountedTotalPrice': discountedTotal,
    });

    setState(() {
      final list = inStockItems.contains(item) ? inStockItems : outOfStockItems;

      final index = list.indexOf(item);
      list[index] = _CartItem(
        id: item.id,
        productId: item.productId,
        title: item.title,
        unitPrice: item.unitPrice,
        totalPrice: effectiveTotal,
        originalTotal: originalTotal,
        discountedTotal: discountedTotal,
        discountPercentage: item.discountPercentage,
        image: item.image,
        option: item.option,
        quantity: newQty,
        stock: item.stock,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(
                  onMenuTap: () {
                    setState(() {
                      menuVisible = !menuVisible;
                    });
                  },
                ),

                const Text(
                  "My Cart",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (inStockItems.isEmpty && outOfStockItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 15),
                                Text(
                                  "No Cart Items Found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (inStockItems.isNotEmpty)
                            _sectionHeader(
                              "Available Items",
                              trailing: TextButton(
                                onPressed: _toggleSelectAll,
                                child: Text(
                                  selectAll ? "Unselect All" : "Select All",
                                ),
                              ),
                            ),
                          ...inStockItems.map(_cartTile),
                          if (outOfStockItems.isNotEmpty)
                            _sectionHeader("Out of Stock"),
                          ...outOfStockItems.map(_cartTile),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  color: const Color(0xFFB564F7),
                  child: GestureDetector(
                    onTap: () {
                      if (selectedIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select at least one item"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        _showOrderSummaryDialog();
                      }
                    },
                    child: const Center(
                      child: Text(
                        "Place Order",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (menuVisible)
              Positioned(
                top: 70,
                right: 10,
                left: 10,
                child: DropMenu(
                  isVisible: menuVisible,
                  userRole: userRole,
                  onItemTap: (value) async {
                    setState(() => menuVisible = false);

                    if (value == "Management") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManagementPage(),
                        ),
                      );
                    } else if (value == "Terms and Conditions") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsManage()),
                      );
                    } else if (value == "Logout") {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: bottomIndex,
        onTap: (index) {
          setState(() => bottomIndex = index);

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CouponPage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          }

          if (index == 3) {
            final u = FirebaseAuth.instance.currentUser;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    u != null ? const ProfilePage() : const SignupPage(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _sectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 5),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _cartTile(_CartItem item) {
    final selected = selectedIds.contains(item.id);
    final inStock = item.stock >= item.quantity;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: inStock ? (_) => _toggleSelect(item.id) : null,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image.isNotEmpty
                ? Image.memory(
                    base64Decode(item.image),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.option,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                Row(
                  children: [
                    Text(
                      "৳${item.totalPrice}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (item.discountPercentage > 0) ...[
                      Text(
                        "৳${item.originalTotal}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "-${item.discountPercentage}%",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),
                Container(
                  height: 35,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1D9FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () =>
                            _updateQuantity(item, item.quantity - 1),
                      ),
                      SizedBox(
                        width: 24,
                        child: Center(
                          child: Text(
                            item.quantity.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () =>
                            _updateQuantity(item, item.quantity + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFB564F7)),
              onPressed: () => _confirmDelete(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItem {
  final String id;
  final String productId;
  final String title;
  final int unitPrice;
  final int totalPrice;
  final String image;
  final String option;
  final int quantity;
  final int stock;
  final int originalTotal;
  final int discountedTotal;
  final int discountPercentage;

  _CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.unitPrice,
    required this.totalPrice,
    required this.image,
    required this.option,
    required this.quantity,
    required this.stock,
    required this.originalTotal,
    required this.discountedTotal,
    required this.discountPercentage,
  });
}
