import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';

class OrderManage extends StatefulWidget {
  const OrderManage({super.key});

  @override
  State<OrderManage> createState() => _OrderManageState();
}

class _OrderManageState extends State<OrderManage> {
  bool menuVisible = false;
  int bottomIndex = -1;
  String userRole = "manager";

  final TextEditingController insideDhakaCtrl = TextEditingController(
    text: "0",
  );
  final TextEditingController outsideDhakaCtrl = TextEditingController(
    text: "0",
  );

  final TextEditingController searchCtrl = TextEditingController();
  String searchText = "";

  String selectedStatus = "Processing";

  final Set<String> selectedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadDeliveryCharges();
    _loadUserRole();

    searchCtrl.addListener(() {
      setState(() {
        searchText = searchCtrl.text.toLowerCase().trim();
      });
    });
  }

  Future<void> _loadUserRole() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(current.uid)
        .get();

    setState(() {
      userRole = doc["role"] ?? "manager";
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _loadDeliveryCharges() async {
    final ref = FirebaseFirestore.instance
        .collection("delivery_charges")
        .doc("default");

    final snap = await ref.get();
    if (snap.exists) {
      insideDhakaCtrl.text = snap["inside_dhaka"].toString();
      outsideDhakaCtrl.text = snap["outside_dhaka"].toString();
    }
  }

  Future<void> _saveDeliveryCharges() async {
    FocusScope.of(context).unfocus();

    await FirebaseFirestore.instance
        .collection("delivery_charges")
        .doc("default")
        .set({
          "inside_dhaka": int.tryParse(insideDhakaCtrl.text) ?? 0,
          "outside_dhaka": int.tryParse(outsideDhakaCtrl.text) ?? 0,
          "updatedAt": FieldValue.serverTimestamp(),
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Delivery charges updated")));
  }

  Widget statusButton(String title) {
    final bool active = selectedStatus == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = title;
          selectedOrders.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? btnPurple : const Color(0xFFF1D9FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Widget> updateButtons() {
    if (selectedStatus == "Processing") {
      return [
        _updateBtn("Update to\nPending", () => _bulkUpdate("Pending")),
        _updateBtn("Update to\nDelivered", () => _bulkUpdate("Delivered")),
        _updateBtn("Update to\nCancelled", _showCancelDialog),
      ];
    }
    if (selectedStatus == "Pending") {
      return [
        _updateBtn("Update to\nDelivered", () => _bulkUpdate("Delivered")),
        _updateBtn("Update to\nCancelled", _showCancelDialog),
      ];
    }
    return [];
  }

  Widget _updateBtn(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: selectedOrders.isEmpty ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selectedOrders.isEmpty ? const Color(0xFFF1D9FB) : btnPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selectedOrders.isEmpty ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _bulkUpdate(String status) async {
    final firestore = FirebaseFirestore.instance;

    final batch = firestore.batch();

    final List<Map<String, dynamic>> deliveredItems = [];

    for (final orderId in selectedOrders) {
      final orderRef = firestore.collection("orders").doc(orderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) continue;

      final orderData = orderSnap.data()!;
      final currentStatus = orderData['status'];

      batch.update(orderRef, {
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (status == "Delivered" && currentStatus != "Delivered") {
        for (final item in orderData['items']) {
          deliveredItems.add({
            "orderId": orderId,
            "productId": item['productId'],
            "qty": (item['quantity'] as num).toInt(),
          });
        }
      }
    }

    await batch.commit();

    if (status == "Delivered") {
      await firestore.runTransaction((tx) async {
        for (final entry in deliveredItems) {
          final productRef = firestore
              .collection("products")
              .doc(entry['productId']);

          final snap = await tx.get(productRef);
          if (!snap.exists) continue;

          final data = snap.data()!;
          final List deliveredOrders = List.from(data['deliveredOrders'] ?? []);

          if (deliveredOrders.contains(entry['orderId'])) continue;

          tx.update(productRef, {
            "total_sold": (data['total_sold'] ?? 0) + entry['qty'],
            "deliveredOrders": FieldValue.arrayUnion([entry['orderId']]),
          });
        }
      });
    }

    setState(() => selectedOrders.clear());
  }

  Future<void> _showCancelDialog() async {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Orders"),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Reason for cancellation",
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Close"),
          ),
          ElevatedButton(
            child: const Text("Submit"),
            onPressed: () async {
              await _cancelOrders(reasonCtrl.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrders(String reason) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final id in selectedOrders) {
      final doc = await FirebaseFirestore.instance
          .collection("orders")
          .doc(id)
          .get();

      final data = doc.data()!;
      final cancelRef = FirebaseFirestore.instance
          .collection("cancelled_orders")
          .doc(id);

      batch.set(cancelRef, {
        ...data,
        "status": "Cancelled",
        "reason": reason,
        "cancelledAt": FieldValue.serverTimestamp(),
      });

      batch.delete(doc.reference);
    }

    await batch.commit();
    // await _sendNotifications("Cancelled");

    setState(() => selectedOrders.clear());
  }

  /*Future<void> _sendNotifications(String status) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'sendOrderStatus',
    );

    for (final id in selectedOrders) {
      final doc = await FirebaseFirestore.instance
          .collection("orders")
          .doc(id)
          .get();
      await callable.call({
        "userId": doc['userId'],
        "title": "Order Update",
        "body": "Your order is now $status",
      });
    }
  }*/

  Query<Map<String, dynamic>> get orderQuery {
    if (selectedStatus == "Cancelled") {
      return FirebaseFirestore.instance
          .collection("cancelled_orders")
          .orderBy("timestamp", descending: true);
    }
    return FirebaseFirestore.instance
        .collection("orders")
        .where("status", isEqualTo: selectedStatus)
        .orderBy("timestamp", descending: true);
  }

  Widget productImage(String productId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Icon(Icons.image_not_supported, size: 60);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null ||
            data['images'] == null ||
            (data['images'] as List).isEmpty) {
          return const Icon(Icons.image_not_supported, size: 60);
        }

        final images = data['images'] as List<dynamic>;
        final base64String = images[0] as String;

        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(base64String),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          );
        } catch (e) {
          return const Icon(Icons.image_not_supported, size: 60);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(
                  onMenuTap: () {
                    setState(() => menuVisible = !menuVisible);
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Order Management",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        inputBox(searchCtrl, "Search orders here..."),
                        const SizedBox(height: 20),

                        const SizedBox(height: 20),
                        const Text(
                          "Delivery Charges",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: const Text(
                                "Inside Dhaka",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: inputBox(insideDhakaCtrl, "Charge"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: const Text(
                                "Outside Dhaka",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: inputBox(outsideDhakaCtrl, "Charge"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _saveDeliveryCharges,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB564F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Save Charges",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            statusButton("Processing"),
                            statusButton("Pending"),
                            statusButton("Delivered"),
                            statusButton("Cancelled"),
                          ],
                        ),

                        const SizedBox(height: 15),
                        Wrap(spacing: 10, children: updateButtons()),
                        const SizedBox(height: 20),
                        StreamBuilder<QuerySnapshot>(
                          stream: orderQuery.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: const Text(
                                  "Failed to load orders",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No orders found",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            }

                            final filteredDocs = snapshot.data!.docs.where((
                              doc,
                            ) {
                              final data = doc.data() as Map<String, dynamic>;
                              final query = searchText;

                              if (query.isEmpty) return true;

                              bool matchUser =
                                  data['email']
                                      .toString()
                                      .toLowerCase()
                                      .contains(query) ||
                                  data['city']
                                      .toString()
                                      .toLowerCase()
                                      .contains(query) ||
                                  data['address']
                                      .toString()
                                      .toLowerCase()
                                      .contains(query);

                              bool matchProducts = (data['items'] as List).any((
                                item,
                              ) {
                                return item['title']
                                        .toString()
                                        .toLowerCase()
                                        .contains(query) ||
                                    item['option']
                                        .toString()
                                        .toLowerCase()
                                        .contains(query);
                              });

                              return matchUser || matchProducts;
                            }).toList();

                            return Column(
                              children: filteredDocs.map((doc) {
                                final selected = selectedOrders.contains(
                                  doc.id,
                                );
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: selected,
                                              onChanged: (_) {
                                                setState(() {
                                                  selected
                                                      ? selectedOrders.remove(
                                                          doc.id,
                                                        )
                                                      : selectedOrders.add(
                                                          doc.id,
                                                        );
                                                });
                                              },
                                            ),
                                            Expanded(
                                              child: Text(
                                                "Order #${doc['orderId']}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              doc['status'],
                                              style: const TextStyle(
                                                color: Colors.purple,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const Divider(),

                                        Text("📧 ${doc['email']}"),
                                        Text("📞 ${doc['phone']}"),
                                        Text("🏠 ${doc['address']}"),
                                        Text("📍 ${doc['city']}"),

                                        const SizedBox(height: 10),
                                        const Text(
                                          "Products",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        Column(
                                          children: (doc['items'] as List).map<Widget>((
                                            item,
                                          ) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  productImage(
                                                    item['productId'],
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item['title'],
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        Text(
                                                          "Option: ${item['option']}",
                                                        ),
                                                        Text(
                                                          "Qty: ${item['quantity']}",
                                                        ),
                                                        Text(
                                                          "Price: ৳${item['unitPrice']}",
                                                        ),
                                                        if (item['discountPercentage'] >
                                                            0)
                                                          Text(
                                                            "Discount: ${item['discountPercentage']}%",
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),

                                        const Divider(),

                                        Text(
                                          "Items Total: ৳${doc['itemsTotal']}",
                                        ),
                                        Text(
                                          "Delivery: ৳${doc['deliveryCharge']}",
                                        ),
                                        Text(
                                          "Grand Total: ৳${doc['grandTotal']}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Payment: ${doc['paymentMethod']}",
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (menuVisible && userRole.isNotEmpty)
              Positioned(
                top: 70,
                left: 10,
                right: 10,
                child: DropMenu(
                  isVisible: menuVisible,
                  userRole: userRole,
                  onItemTap: (value) async {
                    setState(() => menuVisible = false);

                    if (value == "Logout") {
                      await _logout();
                    } else if (value == "Management") {
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
