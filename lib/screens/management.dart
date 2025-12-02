import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/product_manage.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserRole();
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

                        const Text(
                          "Management",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),

                        const SizedBox(height: 15),

                        if (userRole == "admin") ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _purpleActionButton("Add Admin"),
                              _purpleActionButton("Add Manager"),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (userRole == "manager") ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _purpleActionButton("Add User"),
                              _purpleActionButton("Delete User"),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        managementBox("Admins"),
                        managementBox("Managers"),

                        const SizedBox(height: 15),
                        const Text(
                          "Manage Database",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 10),

                        managementBox("Users Details"),
                        managementBox("Total Orders"),
                        managementBox("Delivered Orders"),
                        managementBox("Canceled Orders"),
                        managementBox("Pending Order Details"),
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

                        managementBox("Approvals"),

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
                  onItemTap: (_) => setState(() => menuVisible = false),
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
