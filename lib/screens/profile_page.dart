import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_cutesy/main.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';
import 'package:shop_cutesy/screens/cart_page.dart';
import 'package:shop_cutesy/screens/coupon_page.dart';
import 'package:shop_cutesy/screens/home_page.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/services/authentication.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/screens/user_orders.dart';
import 'package:shop_cutesy/screens/user_review.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware {
  int bottomIndex = 3;
  bool menuVisible = false;
  String userRole = "user";
  String username = "";
  bool generalExpanded = false;
  bool passwordExpanded = false;
  bool isEditing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      username = data['name'] ?? "";
      userRole = data['role'] ?? "user";

      _nameController.text = data['name'] ?? "";
      _phoneController.text = data['phone'] ?? "";
      _addressController.text = data['address'] ?? "";
      _emailController.text = data['email'] ?? "";
    });
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          });

      setState(() {
        isEditing = false;
        username = _nameController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
    }
  }

  Future<void> _sendPasswordReset() async {
    String? res = await AuthService().resetPassword(
      _emailController.text.trim(),
    );

    if (res == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Reset email sent!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignupPage()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete account")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F5),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  TopBar(
                    onMenuTap: () {
                      setState(() {
                        menuVisible = !menuVisible;
                      });
                    },
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Profile",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Hello, $username\nThank You for choosing us",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _generalInformationSection(),

                  _profileTile(
                    "Received Orders",
                    null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const UserOrdersPage(type: OrderViewType.received),
                      ),
                    ),
                  ),

                  _profileTile(
                    "Canceled Orders",
                    null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const UserOrdersPage(type: OrderViewType.cancelled),
                      ),
                    ),
                  ),

                  _profileTile(
                    "Processing Order Details",
                    null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserOrdersPage(
                          type: OrderViewType.processing,
                        ),
                      ),
                    ),
                  ),

                  _profileTile(
                    "Reviews",
                    null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserReviewsPage(),
                      ),
                    ),
                  ),

                  _changePasswordSection(),
                  _profileTile(
                    "Delete Account",
                    Icons.delete_outline,
                    isDelete: true,
                    onTap: _confirmDeleteAccount,
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Team Cutesy!",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            if (menuVisible)
              Positioned(
                top: 70,
                right: 10,
                left: 10,
                child: DropMenu(
                  isVisible: menuVisible,
                  userRole: userRole,
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

                    if (value == "Terms and Conditions") {
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
          setState(() {
            bottomIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CouponPage()),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
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

  Widget _profileTile(
    String title,
    IconData? icon, {
    bool isDelete = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFEEDBFA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _generalInformationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEEDBFA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  generalExpanded = !generalExpanded;
                  isEditing = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "General Information",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      generalExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            if (generalExpanded) ...[
              _infoField("Name", _nameController, enabled: isEditing),
              _infoField("Phone", _phoneController, enabled: isEditing),
              _infoField("Address", _addressController, enabled: isEditing),
              _emailField(),

              const SizedBox(height: 10),

              if (!isEditing)
                _actionButton("Edit Information", () {
                  setState(() => isEditing = true);
                })
              else
                Row(
                  children: [
                    Expanded(
                      child: _actionButton("Cancel", () {
                        setState(() {
                          isEditing = false;
                          _loadUser();
                        });
                      }),
                    ),
                    Expanded(child: _actionButton("Save", _saveProfile)),
                  ],
                ),

              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _changePasswordSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEEDBFA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  passwordExpanded = !passwordExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      passwordExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            if (passwordExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _emailController,
                  enabled: false,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
              ),

              const SizedBox(height: 15),

              _actionButton("Send Reset Email", _sendPasswordReset),

              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoField(
    String label,
    TextEditingController controller, {
    bool enabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        style: TextStyle(color: enabled ? Colors.black : Colors.grey.shade800),
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _emailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Email cannot be edited"),
              content: const Text(
                "Emails cannot be edited. Please contact admin panel if change is needed.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        },
        child: AbsorbPointer(
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnPurple,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
