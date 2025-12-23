import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/screens/home_page.dart';

class ConfirmOrder extends StatefulWidget {
  final List<CartItem> selectedItems;

  const ConfirmOrder({super.key, required this.selectedItems});

  @override
  State<ConfirmOrder> createState() => _ConfirmOrderState();
}

class _ConfirmOrderState extends State<ConfirmOrder> {
  final user = FirebaseAuth.instance.currentUser;
  bool orderRulesChecked = false;
  bool termsChecked = false;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  String? email;
  String? phone;
  String? address;
  String? city;
  List<String> cities = [
    'Dhaka',
    'Chittagong',
    'Sylhet',
    'Khulna',
    'Rajshahi',
    'Barisal',
    'Rangpur',
    'Mymensingh',
    'Comilla',
    'Narayanganj',
    'Gazipur',
    'Tangail',
    'Jessore',
    'Feni',
  ];

  int totalPrice = 0;
  bool menuVisible = false;
  String username = "";
  String userRole = "user";
  bool isLoggedIn = false;
  int bottomIndex = -1;
  int deliveryCharge = 0;
  int grandTotal = 0;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();

    _loadUserDetails().then((_) => _loadDeliveryCharge());
    _loadUser();
    _calculateTotal();
  }

  TextEditingController couponController = TextEditingController();
  String? appliedCoupon;
  int couponDiscount = 0;

  Future<void> _applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) return;

    final query = await FirebaseFirestore.instance
        .collection('coupons')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Coupon doesn't exist")));
      return;
    }

    final doc = query.docs.first;
    final data = doc.data();
    final startTime = (data['startTime'] as Timestamp).toDate();
    final endTime = (data['endTime'] as Timestamp).toDate();
    final discount = data['percentage'] ?? 0;
    final tags = List<String>.from(
      data['tags'] ?? ['All'],
    ).map((e) => e.trim().toLowerCase()).toList();

    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon will be active from $startTime')),
      );
      return;
    }
    if (now.isAfter(endTime)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Coupon Expired'),
          content: const Text('This coupon has expired.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final productIds = widget.selectedItems
        .map((item) => item.productId)
        .toList();
    final productDocs = await FirebaseFirestore.instance
        .collection('products')
        .where(FieldPath.documentId, whereIn: productIds)
        .get();

    final productTags = {
      for (var doc in productDocs.docs)
        doc.id: (doc.data()['tag'] ?? '').toString().trim().toLowerCase(),
    };

    int sum = 0;
    bool anyItemDiscounted = false;

    for (var i = 0; i < widget.selectedItems.length; i++) {
      final item = widget.selectedItems[i];
      final itemTotal = item.unitPrice * item.quantity;
      int discountedTotal = itemTotal;

      final itemTag = productTags[item.productId] ?? '';

      if (tags.contains('all') || tags.contains(itemTag)) {
        discountedTotal = (itemTotal - (itemTotal * discount / 100)).round();
        anyItemDiscounted = true;
      }

      widget.selectedItems[i] = CartItem(
        id: item.id,
        productId: item.productId,
        title: item.title,
        unitPrice: item.unitPrice,
        totalPrice: discountedTotal,
        image: item.image,
        option: item.option,
        quantity: item.quantity,
        stock: item.stock,
        productTag: itemTag,
        originalTotal: itemTotal,
        discountedTotal: discountedTotal,
        discountPercentage: item.discountPercentage,
      );

      sum += discountedTotal;
    }

    if (!anyItemDiscounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Coupon Not Applicable'),
          content: Text('This coupon applies only to: ${tags.join(", ")}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      appliedCoupon = code;
      couponDiscount = discount;
      totalPrice = sum;
      grandTotal = totalPrice + deliveryCharge;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon applied! $discount% discount')),
    );
  }

  Future<void> _loadDeliveryCharge() async {
    if (city == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('delivery_charges')
        .doc('default')
        .get();

    final data = doc.data();
    if (data == null) return;

    int charge = city == 'Dhaka' ? data['inside_dhaka'] : data['outside_dhaka'];

    setState(() {
      deliveryCharge = charge;
      grandTotal = totalPrice + deliveryCharge;
    });
  }

  Future<void> _loadUserDetails() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      email = data['email'] ?? '';
      phone = data['phone'] ?? '';
      address = data['address'] ?? '';
      city = data['city'];

      emailController.text = email!;
      phoneController.text = phone!;
      addressController.text = address!;
    });
  }

  void _calculateTotal() {
    int sum = 0;
    for (var item in widget.selectedItems) {
      int originalTotal = item.unitPrice * item.quantity;
      int discountedTotal = item.discountPercentage > 0
          ? (originalTotal - (originalTotal * item.discountPercentage / 100))
                .round()
          : originalTotal;
      sum += discountedTotal;
    }

    setState(() {
      totalPrice = sum;
      grandTotal = totalPrice + deliveryCharge;
    });
  }

  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        username = "";
        userRole = "user";
        isLoggedIn = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final data = doc.data() ?? {};
    setState(() {
      username = (data['name'] ?? "").toString();
      userRole = (data['role'] ?? "user").toString();
      isLoggedIn = true;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _confirmOrder() async {
    if (city == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a city')));
      return;
    }

    await _loadDeliveryCharge();

    final int finalGrandTotal = totalPrice + deliveryCharge;

    if (user == null) return;

    final orderRef = FirebaseFirestore.instance.collection('orders').doc();
    final timestamp = Timestamp.now();

    await orderRef.set({
      'orderId': orderRef.id,
      'userId': user!.uid,
      'items': widget.selectedItems
          .map(
            (item) => {
              'productId': item.productId,
              'title': item.title,
              'option': item.option,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'discountPercentage': item.discountPercentage,
            },
          )
          .toList(),
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'paymentMethod': 'COD',
      'itemsTotal': totalPrice,
      'deliveryCharge': deliveryCharge,
      'grandTotal': finalGrandTotal,
      'couponCode': appliedCoupon ?? '',
      'couponDiscount': couponDiscount,
      'status': 'Processing',
      'timestamp': timestamp,
    });

    for (var item in widget.selectedItems) {
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(item.productId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final currentQty = int.tryParse(data['quantity'].toString()) ?? 0;
        final newQty = currentQty - item.quantity;

        transaction.update(productRef, {
          'quantity': newQty.toString(),
          'total_sold': FieldValue.increment(item.quantity),
        });
      });
    }

    for (var item in widget.selectedItems) {
      await FirebaseFirestore.instance.collection('cart').doc(item.id).delete();
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order Placed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your order #${orderRef.id} has been successfully placed.'),
            const SizedBox(height: 10),
            Text('Total: ৳$finalGrandTotal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
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
                const Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Confirm Order",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          onChanged: (v) => email = v,
                        ),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          onChanged: (v) => phone = v,
                        ),
                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          onChanged: (v) => address = v,
                        ),

                        DropdownButtonFormField<String>(
                          value: city,
                          items: cities
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          hint: const Text('Select city'),
                          onChanged: (val) {
                            setState(() => city = val);
                            _loadDeliveryCharge();
                          },
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        ...widget.selectedItems.map(
                          (item) => ListTile(
                            title: Text(item.title),
                            subtitle: Text(
                              'Qty: ${item.quantity}, Option: ${item.option}',
                            ),
                            trailing: Text('৳${item.totalPrice}'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Items Total: ৳$totalPrice'),
                        Text('Delivery Charge: ৳$deliveryCharge'),
                        const Divider(),
                        Text(
                          'Grand Total: ৳$grandTotal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const SizedBox(height: 16),
                        const Text(
                          'Apply Coupon',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: couponController,
                                decoration: const InputDecoration(
                                  labelText: 'Coupon Code',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _applyCoupon,
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        CheckboxListTile(
                          value: orderRulesChecked,
                          onChanged: (v) =>
                              setState(() => orderRulesChecked = v ?? false),
                          title: const Text(
                            'I agree to the Order Rules',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '1. All products must be checked in front of the delivery man. If any issue is found, contact us immediately.',
                              ),
                              SizedBox(height: 6),
                              Text(
                                '2. Once the product is received, no refund, return, or exchange will be accepted.',
                              ),
                              SizedBox(height: 6),
                              Text(
                                '3. If a problem is found during delivery, you must pay the delivery charge and return the product to the delivery man.',
                              ),
                            ],
                          ),
                        ),

                        CheckboxListTile(
                          value: termsChecked,
                          onChanged: (v) =>
                              setState(() => termsChecked = v ?? false),
                          title: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsManage(),
                                ),
                              );
                            },
                            child: const Text(
                              'I agree to Terms and Conditions',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  orderRulesChecked &&
                                      termsChecked &&
                                      city != null
                                  ? _confirmOrder
                                  : null,

                              child: const Text('Confirm Order'),
                            ),
                          ],
                        ),
                      ],
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
                  onItemTap: (value) {
                    setState(() => menuVisible = false);
                    if (value == "Management") {
                      Navigator.pushNamed(context, '/management');
                    }
                  },
                  userRole: userRole,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: bottomIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(context, '/offer', (_) => false);
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(context, '/cart', (_) => false);
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile',
              (_) => false,
            );
          }
        },
      ),
    );
  }
}

class CartItem {
  final String id;
  final String productId;
  final String title;
  final int unitPrice;
  final int totalPrice;
  final String image;
  final String option;
  final int quantity;
  final int stock;
  final String productTag;
  final int originalTotal;
  final int discountedTotal;
  final int discountPercentage;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.unitPrice,
    required this.totalPrice,
    required this.image,
    required this.option,
    required this.quantity,
    required this.stock,
    required this.productTag,
    required this.originalTotal,
    required this.discountedTotal,
    required this.discountPercentage,
  });
}
