import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'management.dart';
import 'terms_conditions.dart';

const String STATUS_PENDING = "pending";
const String STATUS_APPROVED = "approved";
const String STATUS_TRASHED = "trashed";

class ReviewManage extends StatefulWidget {
  const ReviewManage({super.key});

  @override
  State<ReviewManage> createState() => _ReviewManageState();
}

class _ReviewManageState extends State<ReviewManage> {
  String userRole = "manager";
  bool menuVisible = false;
  int bottomIndex = -1;

  String currentStatus = STATUS_PENDING;
  String searchText = "";
  final TextEditingController searchCtrl = TextEditingController();

  final Set<String> selectedIds = {};
  final Set<String> _lastLoadedIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserRole();

    searchCtrl.addListener(() {
      setState(() {
        searchText = searchCtrl.text.toLowerCase().trim();
      });
    });
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    setState(() {
      userRole = doc["role"] ?? "manager";
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _updateStatus(String newStatus) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final id in selectedIds) {
      batch.update(FirebaseFirestore.instance.collection("reviews").doc(id), {
        "status": newStatus,
      });
    }

    await batch.commit();
    setState(() => selectedIds.clear());
  }

  Future<void> _deleteReviews() async {
    final batch = FirebaseFirestore.instance.batch();

    for (final id in selectedIds) {
      batch.delete(FirebaseFirestore.instance.collection("reviews").doc(id));
    }

    await batch.commit();
    setState(() => selectedIds.clear());
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

                const Text(
                  "Manage Reviews",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),

                _buildSearchBar(),
                _buildStatusTabs(),
                _buildSelectAllRow(),
                _buildActionButtons(),
                Expanded(child: _buildReviewList()),
              ],
            ),

            if (menuVisible)
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: inputBox(searchCtrl, "Search reviews here...."),
    );
  }

  Widget _buildStatusTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _tab("Pending", STATUS_PENDING),
        _tab("Approved", STATUS_APPROVED),
        _tab("Trash", STATUS_TRASHED),
      ],
    );
  }

  Widget _tab(String text, String status) {
    final active = currentStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentStatus = status;
          selectedIds.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? btnPurple : const Color(0xFFF1D9FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (selectedIds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentStatus != STATUS_TRASHED)
            _actionBtn("Approve", () => _updateStatus(STATUS_APPROVED)),

          if (currentStatus != STATUS_TRASHED)
            _actionBtn("Trash", () => _updateStatus(STATUS_TRASHED)),

          if (currentStatus == STATUS_TRASHED)
            _actionBtn("Delete", _deleteReviews),
        ],
      ),
    );
  }

  Widget _actionBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
      ),
    );
  }

  Widget _buildSelectAllRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Checkbox(
            value:
                selectedIds.isNotEmpty &&
                selectedIds.length == _lastLoadedIds.length,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  selectedIds.addAll(_lastLoadedIds);
                } else {
                  selectedIds.clear();
                }
              });
            },
          ),
          const Text(
            "Select all",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("reviews")
          .where("status", isEqualTo: currentStatus)
          .orderBy("time", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("No reviews found"));
        }

        final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data.values.any(
            (v) => v.toString().toLowerCase().contains(searchText),
          );
        }).toList();

        _lastLoadedIds
          ..clear()
          ..addAll(docs.map((e) => e.id));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) => _reviewCard(docs[i]),
        );
      },
    );
  }

  Widget _reviewCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final List<String> images = List<String>.from(data["images"] ?? []);
    final selected = selectedIds.contains(doc.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? btnPurple : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) {
              setState(() {
                selected ? selectedIds.remove(doc.id) : selectedIds.add(doc.id);
              });
            },
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(data["userId"])
                      .get(),
                  builder: (_, snap) {
                    final name = snap.hasData ? snap.data!["name"] : "User";
                    return Text(
                      "$name • ${_formatTime(data["time"])}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("products")
                      .doc(data["productId"])
                      .get(),
                  builder: (_, pSnap) {
                    if (!pSnap.hasData || pSnap.data!.data() == null) {
                      return const Text(
                        "Product",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }

                    final product = pSnap.data!.data() as Map<String, dynamic>;

                    return Text(
                      product["title"] ?? "Product",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),

                Text(
                  "Option: ${data["option"]}   •   ⭐ ${data["rating"]}",
                  style: const TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 8),

                Text(data["reviewText"], style: const TextStyle(fontSize: 14)),

                if (images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(images[i]),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }
}
