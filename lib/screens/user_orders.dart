import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';

enum OrderViewType { received, cancelled, processing }

class UserOrdersPage extends StatefulWidget {
  final OrderViewType type;
  const UserOrdersPage({super.key, required this.type});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  final user = FirebaseAuth.instance.currentUser!;
  bool menuVisible = false;
  int bottomIndex = -1;
  String userRole = "user";
  String username = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    setState(() {
      userRole = doc["role"] ?? "user";
      username = doc["name"] ?? "";
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Query _buildQuery() {
    if (widget.type == OrderViewType.received) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Delivered');
    }
    if (widget.type == OrderViewType.cancelled) {
      return FirebaseFirestore.instance
          .collection('cancelled_orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Cancelled');
    }
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['Processing', 'Pending']);
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
                  onMenuTap: () => setState(() => menuVisible = !menuVisible),
                ),

                const Text(
                  "Your Orders",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _buildQuery().snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snap.data!.docs.isEmpty) {
                        return const Center(child: Text("No orders found"));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: snap.data!.docs.length,
                        itemBuilder: (_, index) {
                          final orderDoc = snap.data!.docs[index];
                          final data = orderDoc.data() as Map<String, dynamic>;
                          final items = List<Map<String, dynamic>>.from(
                            data['items'] ?? [],
                          );

                          return Column(
                            children: items.asMap().entries.map((entry) {
                              final itemIndex = entry.key;
                              final item = entry.value;

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(item['productId'])
                                    .get(),
                                builder: (_, pSnap) {
                                  if (!pSnap.hasData) return const SizedBox();

                                  final product =
                                      pSnap.data!.data()
                                          as Map<String, dynamic>;
                                  final images = List<String>.from(
                                    product['images'] ?? [],
                                  );
                                  final qty = item['quantity'] ?? 0;
                                  final price = item['unitPrice'] ?? 0;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: images.isNotEmpty
                                                  ? Image.memory(
                                                      base64Decode(
                                                        images.first,
                                                      ),
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      width: 60,
                                                      height: 60,
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Option: ${item['option']}",
                                                  ),
                                                  Text("Qty: $qty"),
                                                  Text("Price: ৳$price"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (widget.type ==
                                            OrderViewType.received)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: FutureBuilder<QuerySnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('reviews')
                                                  .where(
                                                    'userId',
                                                    isEqualTo: user.uid,
                                                  )
                                                  .where(
                                                    'orderId',
                                                    isEqualTo: orderDoc.id,
                                                  )
                                                  .where(
                                                    'itemIndex',
                                                    isEqualTo: itemIndex,
                                                  )
                                                  .limit(1)
                                                  .get(),
                                              builder: (_, rSnap) {
                                                if (!rSnap.hasData)
                                                  return const SizedBox();

                                                if (rSnap
                                                    .data!
                                                    .docs
                                                    .isNotEmpty) {
                                                  return const Text(
                                                    "Reviewed",
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  );
                                                }

                                                return ElevatedButton(
                                                  style: _primaryBtnStyle(),
                                                  onPressed: () =>
                                                      _showAddReviewDialog(
                                                        context,
                                                        item['productId'],
                                                        orderDoc.id,
                                                        itemIndex,
                                                        item['option'],
                                                      ),
                                                  child: const Text("Review"),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
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

                    if (value == "Logout") {
                      await _logout();
                    } else if (value == "Management") {
                      Navigator.pushNamed(context, '/management');
                    } else if (value == "Terms and Conditions") {
                      Navigator.pushNamed(context, '/terms');
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

  String _title() {
    if (widget.type == OrderViewType.received) return "Received Orders";
    if (widget.type == OrderViewType.cancelled) return "Cancelled Orders";
    return "Processing Orders";
  }

  void _showAddReviewDialog(
    BuildContext context,
    String productId,
    String orderId,
    int itemIndex,
    String selectedOption,
  ) {
    TextEditingController reviewC = TextEditingController();
    List<String> reviewImages = [];
    int rating = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickImage() async {
              if (reviewImages.length >= 2) return;
              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (file != null) {
                final bytes = await file.readAsBytes();
                reviewImages.add(base64Encode(bytes));
                setStateDialog(() {});
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              backgroundColor: const Color(0xFFFDF1F5),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add Review",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: List.generate(2, (i) {
                        return GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEADCF8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: reviewImages.length > i
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(
                                      base64Decode(reviewImages[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.add, size: 28),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Select Option",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.white,
                      ),
                      child: Text(
                        selectedOption,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Rating",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (i) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 28,
                          ),
                          onPressed: () {
                            setStateDialog(() => rating = i + 1);
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: reviewC,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Write your review",
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Color(0xFFB57EDC),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('reviews')
                                .add({
                                  'userId': user.uid,
                                  'orderId': orderId,
                                  'itemIndex': itemIndex,
                                  'productId': productId,
                                  'rating': rating,
                                  'reviewText': reviewC.text,
                                  'images': reviewImages,
                                  'option': selectedOption,
                                  'status': 'pending',
                                  'time': FieldValue.serverTimestamp(),
                                });

                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              color: Color(0xFFB57EDC),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  ButtonStyle _primaryBtnStyle({Color? color}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color ?? const Color(0xFF9B5DE5),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }
}
