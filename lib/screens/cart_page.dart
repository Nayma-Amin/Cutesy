import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/screens/home_page.dart';
import 'package:shop_cutesy/screens/offer_page.dart';
import 'package:shop_cutesy/screens/profile_page.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  
  int bottomIndex = 2; // <-- Cart tab selected

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("cart_items");

    if (raw != null) {
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(jsonDecode(raw));
      });
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("cart_items", jsonEncode(cartItems));
  }

  void _updateQuantity(int index, int newQty) {
    setState(() {
      cartItems[index]["quantity"] = newQty;
    });
    _saveCart();
  }

  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
    _saveCart();
  }

  double get totalPrice {
    double sum = 0;
    for (var item in cartItems) {
      sum += (item["price"] * item["quantity"]);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF1F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty 🛒",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          item["image"],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["name"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Option: ${item["option"]}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                // Quantity Selector Box
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1D9FB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (item["quantity"] > 1) {
                                            _updateQuantity(
                                                index, item["quantity"] - 1);
                                          }
                                        },
                                        child:
                                            const Icon(Icons.remove, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        item["quantity"].toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          _updateQuantity(
                                              index, item["quantity"] + 1);
                                        },
                                        child: const Icon(Icons.add, size: 20),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                Text(
                                  "Tk. ${item["price"] * item["quantity"]}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      GestureDetector(
                        onTap: () => _removeItem(index),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                      ),
                    ],
                  ),
                );
              },
            ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: bottomIndex,
        onTap: (index) {
          setState(() => bottomIndex = index);

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfferPage()),
            );
          }

          if (index == 2) {
            // Already in Cart → do nothing
          }

          if (index == 3) {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupPage()),
              );
            }
          }
        },
      ),
    );
  }
}
