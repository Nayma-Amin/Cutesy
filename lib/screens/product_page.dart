import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';

class ProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductPage({super.key, required this.product});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _OptionChip extends StatelessWidget {
  final String label;
  const _OptionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1D9FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  int bottomIndex = -1;
  int quantity = 1;
  late bool isFav;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  String username = "";
  String userRole = "user";
  bool isLoggedIn = false;
  bool menuVisible = false;

  @override
  void initState() {
    super.initState();

    isFav = false;
    _loadFav();
    _loadUser();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
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

    setState(() {
      username = doc['name'] ?? "";
      userRole = doc['role'] ?? "user";
      isLoggedIn = true;
    });
  }

  Future<void> _loadFav() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFav = prefs.getBool(widget.product["id"].toString()) ?? false;
    });
  }

  Future<void> _toggleFav() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFav = !isFav;
    });
    prefs.setBool(widget.product["id"].toString(), isFav);
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

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

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                product["image"],
                                height: 260,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product["name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              Text(
                                "Tk. ${product["price"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: [
                              const Text(
                                "Options",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${product["stock"]} in stock",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _toggleFav,
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: const Color(0xFFB564F7),
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        SizedBox(
                          height: 50,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                            scrollDirection: Axis.horizontal,
                            children: const [
                              _OptionChip(label: "Cherry"),
                              _OptionChip(label: "Berry-4"),
                              _OptionChip(label: "Bow"),
                              _OptionChip(label: "Heart-6"),
                              _OptionChip(label: "Flower-1"),
                              _OptionChip(label: "Flower-2"),
                              _OptionChip(label: "Flower-8"),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 5),
                          child: Row(
                            children: [
                              const Text(
                                "Quantity:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1D9FB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity > 1) quantity--;
                                        setState(() {});
                                      },
                                      child: const Icon(Icons.remove, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity < product["stock"]) quantity++;
                                        setState(() {});
                                      },
                                      child: const Icon(Icons.add, size: 22),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.fromLTRB(15, 10, 15, 3),
                          child: Text(
                            "Description",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "Handmade cute charms made from resin.\n"
                            "Charms include fruits, flowers, shapes and tiny details.\n"
                            "Each charm is handmade and uses fiber ribbon.\n"
                            "Can be used as a phone charm, keychain, bag charm, or bookmark.",
                            style: TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB564F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Add to Cart",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB564F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Reviews",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManagementPage(),
                        ),
                      );
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
