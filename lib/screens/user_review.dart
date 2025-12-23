import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/screens/product_page.dart';

class UserReviewsPage extends StatefulWidget {
  const UserReviewsPage({super.key});

  @override
  State<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
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

  Query _reviewQuery() {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .orderBy('time', descending: true);
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

                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    "Your Reviews",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _reviewQuery().snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snap.data!.docs.isEmpty) {
                        return const Center(child: Text("No reviews found"));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: snap.data!.docs.length,
                        itemBuilder: (_, index) {
                          final reviewDoc = snap.data!.docs[index];
                          final review = reviewDoc.data() as Map<String, dynamic>;

                          final status = review['status'] ?? 'pending';
                          final isApproved = status.toLowerCase() == 'approved';
                          final bgColor =
                              isApproved ? const Color(0xFFEADCF8) : Colors.grey.shade200;

                          final reviewTime = (review['time'] as Timestamp?)?.toDate();

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductPage(
                                    productId: review['productId'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['productTitle'] ?? 'Product',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isApproved ? Colors.black : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (reviewTime != null)
                                    Text(
                                      "${reviewTime.day}-${reviewTime.month}-${reviewTime.year} ${reviewTime.hour}:${reviewTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  if (review['option'] != null)
                                    Text(
                                      "Option: ${review['option']}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  const SizedBox(height: 6),
                                  if (review['images'] != null &&
                                      (review['images'] as List).isNotEmpty)
                                    SizedBox(
                                      height: 60,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: (review['images'] as List)
                                            .map<Widget>((img) => Padding(
                                                  padding: const EdgeInsets.only(right: 6),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.memory(
                                                      base64Decode(img),
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    review['reviewText'] ?? '',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < (review['rating'] ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Status: ${review['status']}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isApproved ? Colors.green : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
            Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
          }
        },
      ),
    );
  }
}
