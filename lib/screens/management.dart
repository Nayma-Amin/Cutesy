import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/coupon_page.dart';
import 'package:shop_cutesy/screens/order_manage.dart';
import 'package:shop_cutesy/screens/product_manage.dart';
import 'package:shop_cutesy/screens/review_manage.dart';
import 'package:shop_cutesy/screens/graph_analytics.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/screens/user_manage.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  String userRole = "manager";
  bool menuVisible = false;
  int bottomIndex = -1;
  String username = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(current.uid)
        .get();

    setState(() {
      userRole = doc["role"] ?? "manager";
      username = doc["name"] ?? "";
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _purpleActionButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: btnPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget managementBox(String title, {VoidCallback? onTap}) {
    TextEditingController dummy = TextEditingController(text: title);

    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: inputBox(dummy, title),
        ),
      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 5),

                        if (userRole == "admin") ...[
                          const Text(
                            "Management",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),

                          const SizedBox(height: 15),
                          managementBox(
                            "Admins",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserManage(openTab: "admin"),
                              ),
                            );
                          },
                        ),
                          managementBox(
                            "Managers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserManage(openTab: "manager"),
                              ),
                            );
                          },
                        ),

                          const SizedBox(height: 15),
                        ],

                        const Text(
                          "Manage Database",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 10),

                        managementBox("Users",
                        onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserManage(openTab: "user"),
                              ),
                            );
                          },
                        ),

                        managementBox(
                          "Orders",
                        onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderManage(),
                              ),
                            );
                          },
                        ),

                        managementBox(
                          "Products",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductManage(),
                              ),
                            );
                          },
                        ),

                        managementBox(
                          "Coupons",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CouponPage(),
                              ),
                            );
                          },
                        ),

                        managementBox(
                          "Reviews",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReviewManage(),
                              ),
                            );
                          },
                        ),

                        managementBox(
                          "Terms & Conditions",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsManage(),
                              ),
                            );
                          },
                        ),

                        managementBox(
                          "Graphs & Analytics",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GraphAnalytics(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 15),
                        const Text(
                          "Team Cutesy!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 40),
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
                        MaterialPageRoute(
                          builder: (_) => const TermsManage(),
                        ),
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
