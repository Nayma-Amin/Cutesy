import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/home_page.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';

class UserManage extends StatefulWidget {
  final String openTab;
  const UserManage({super.key, this.openTab = "user"});

  @override
  State<UserManage> createState() => _UserManageState();
}

class _UserManageState extends State<UserManage> {
  bool menuVisible = false;
  int bottomIndex = -1;

  String currentRole = "";
  String viewing = "";
  String searchText = "";
  String? selectedUserId;
  Map<String, dynamic>? selectedUserData;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewing = widget.openTab;
    loadRole();
    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.toLowerCase().trim();
      });
    });
  }

  Future<void> loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    setState(() {
      currentRole = (doc.exists && doc.data()!.containsKey("role"))
          ? doc["role"]
          : "user";
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Stream<QuerySnapshot> usersStream() {
    final users = FirebaseFirestore.instance.collection("users");
    switch (viewing) {
      case "admin":
      case "manager":
      case "user":
        return users.where("role", isEqualTo: viewing).snapshots();
      case "restricted":
        return FirebaseFirestore.instance
            .collection("restricted_users")
            .snapshots();
      case "banned":
        return FirebaseFirestore.instance
            .collection("banned_users")
            .snapshots();
      case "deleted":
        return FirebaseFirestore.instance
            .collection("deleted_users")
            .snapshots();
      default:
        return users.snapshots();
    }
  }

  Future<int> _countInCollectionForUser(String collection, String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .where("userId", isEqualTo: uid)
          .get();
      return snap.size;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> _fetchOrderCounts(String uid) async {
    final total = await _countInCollectionForUser("total_orders", uid);
    final cancelled = await _countInCollectionForUser("cancelled_orders", uid);
    final received = await _countInCollectionForUser("received_orders", uid);
    return {"total": total, "cancelled": cancelled, "received": received};
  }

  void toggleSelect(String uid, Map<String, dynamic> data) {
    setState(() {
      if (selectedUserId == uid) {
        selectedUserId = null;
        selectedUserData = null;
      } else {
        selectedUserId = uid;
        selectedUserData = data;
      }
    });
  }

  Future<void> _deleteSelectedUser({String? reason}) async {
    if (currentRole != "admin") return;

    final uid = selectedUserId;
    final data = selectedUserData;
    if (uid == null || data == null) return;

    final deletedData = Map<String, dynamic>.from(data);
    deletedData["deletedAt"] = FieldValue.serverTimestamp();
    if (reason != null && reason.isNotEmpty) deletedData["reason"] = reason;

    await FirebaseFirestore.instance
        .collection("deleted_users")
        .doc(uid)
        .set(deletedData);

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(
      FirebaseFirestore.instance.collection("banned_users").doc(uid),
    );
    batch.delete(
      FirebaseFirestore.instance.collection("restricted_users").doc(uid),
    );
    batch.delete(FirebaseFirestore.instance.collection("users").doc(uid));
    await batch.commit();

    setState(() {
      selectedUserId = null;
      selectedUserData = null;
    });
  }

  Future<void> _banSelectedUser(String reason) async {
    if (selectedUserId == null || selectedUserData == null) return;
    if (currentRole != "admin") return;

    final uid = selectedUserId!;
    final data = Map<String, dynamic>.from(selectedUserData!);

    data["reason"] = reason;
    data["bannedAt"] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection("banned_users")
        .doc(uid)
        .set(data);

    await FirebaseFirestore.instance.collection("approvals").add({
      "uid": uid,
      "name": data["name"],
      "email": data["email"],
      "phone": data["phone"],
      "address": data["address"],
      "reason": reason,
      "type": "ban",
      "timestamp": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("users").doc(uid).delete();

    setState(() {
      selectedUserId = null;
      selectedUserData = null;
    });
  }

  Future<void> _restrictSelectedUser(String reason) async {
    if (selectedUserId == null || selectedUserData == null) return;
    if (!(currentRole == "admin" || currentRole == "manager")) return;

    final uid = selectedUserId!;
    final data = Map<String, dynamic>.from(selectedUserData!);

    data["reason"] = reason;
    data["restrictedAt"] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection("restricted_users")
        .doc(uid)
        .set(data);

    await FirebaseFirestore.instance.collection("approvals").add({
      "uid": uid,
      "name": data["name"],
      "email": data["email"],
      "phone": data["phone"],
      "address": data["address"],
      "reason": reason,
      "type": "restrict",
      "timestamp": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("users").doc(uid).delete();

    setState(() {
      selectedUserId = null;
      selectedUserData = null;
    });
  }

  Future<void> _retrieveSelectedFrom(String fromCollection) async {
    if (selectedUserId == null) return;
    final uid = selectedUserId!;
    final doc = await FirebaseFirestore.instance
        .collection(fromCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return;
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    data.remove("reason");
    data.remove("restrictedAt");
    data.remove("bannedAt");
    data.remove("timestamp");
    await FirebaseFirestore.instance.collection("users").doc(uid).set(data);
    await FirebaseFirestore.instance
        .collection(fromCollection)
        .doc(uid)
        .delete();
    setState(() {
      selectedUserId = null;
      selectedUserData = null;
    });
  }

  Future<String?> _showReasonDialog(String title) async {
    final tc = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: tc,
            decoration: const InputDecoration(hintText: "Enter reason"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final text = tc.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, text);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: bgPink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black87),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: btnPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget actionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentRole == "admin")
          purpleMini(
            "Delete",
            onTap: () async {
              if (selectedUserId == null) return;

              final reason = await _showReasonDialog(
                "Enter reason for deletion",
              );

              if (reason == null) return;

              await _deleteSelectedUser(reason: reason);
              setState(() {});
            },
          ),

        const SizedBox(width: 10),
        purpleMini(
          "Restrict",
          onTap: () async {
            if (selectedUserId == null) return;
            final reason = await _showReasonDialog("Reason for restriction");
            if (reason == null) return;
            await _restrictSelectedUser(reason);
            setState(() {});
          },
        ),
        const SizedBox(width: 10),
        purpleMini(
          "Bann",
          onTap: () async {
            if (selectedUserId == null) return;
            if (currentRole == "manager") {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Permission denied"),
                  content: const Text(
                    "You do not have the permission to ban users.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
              return;
            }
            if (currentRole != "admin") return;
            final reason = await _showReasonDialog("Reason for ban");
            if (reason == null) return;
            await _banSelectedUser(reason);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget bottomViewTabs() {
    Widget tabButton(String label, String value, {VoidCallback? onTap}) {
      final bool active = viewing == value;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? btnPurple : const Color(0xFFF1D9FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            tabButton(
              "Main",
              widget.openTab,
              onTap: () {
                setState(() {
                  viewing = widget.openTab;
                  selectedUserId = null;
                  selectedUserData = null;
                });
              },
            ),
            const SizedBox(width: 6),

            tabButton(
              "Restricted",
              "restricted",
              onTap: () {
                setState(() {
                  viewing = "restricted";
                  selectedUserId = null;
                  selectedUserData = null;
                });
              },
            ),
            const SizedBox(width: 6),

            tabButton(
              "Banned",
              "banned",
              onTap: () {
                setState(() {
                  viewing = "banned";
                  selectedUserId = null;
                  selectedUserData = null;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (currentRole == "admin")
              tabButton(
                "Deleted",
                "deleted",
                onTap: () {
                  setState(() {
                    viewing = "deleted";
                    selectedUserId = null;
                    selectedUserData = null;
                  });
                },
              ),

            if (currentRole == "admin") const SizedBox(width: 6),

            if (viewing == "restricted" || viewing == "banned")
              tabButton(
                "Retrieve",
                "retrieve",
                onTap: () async {
                  if (selectedUserId == null) return;
                  final from = viewing == "restricted"
                      ? "restricted_users"
                      : "banned_users";
                  await _retrieveSelectedFrom(from);
                  setState(() {});
                },
              ),
          ],
        ),
      ],
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            "User Management",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        inputBox(searchController, "Search users......"),
                        const SizedBox(height: 12),

                        actionButtonsRow(),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Viewing: ${viewing.toUpperCase()}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        bottomViewTabs(),
                        const SizedBox(height: 16),

                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: usersStream(),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              // Filter docs based on searchText
                              final docs = (snap.data?.docs ?? []).where((d) {
                                final data =
                                    (d.data() as Map<String, dynamic>?) ?? {};
                                if (!data.containsKey("uid"))
                                  data["uid"] = d.id;

                                final name = (data["name"] ?? "")
                                    .toString()
                                    .toLowerCase();
                                final email = (data["email"] ?? "")
                                    .toString()
                                    .toLowerCase();
                                final phone = (data["phone"] ?? "")
                                    .toString()
                                    .toLowerCase();
                                final role = (data["role"] ?? "")
                                    .toString()
                                    .toLowerCase();
                                final address = (data["address"] ?? "")
                                    .toString()
                                    .toLowerCase();

                                if (searchText.isEmpty) return true;

                                return name.contains(searchText) ||
                                    email.contains(searchText) ||
                                    phone.contains(searchText) ||
                                    role.contains(searchText) ||
                                    address.contains(searchText);
                              }).toList();

                              if (docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    viewing == "restricted"
                                        ? "No restricted users found"
                                        : viewing == "banned"
                                        ? "No banned users found"
                                        : viewing == "deleted"
                                        ? "No deleted users found"
                                        : "No users found",
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 1400,
                                  ),
                                  child: DataTable(
                                    columnSpacing: 12,
                                    columns: const [
                                      DataColumn(label: Text("Name")),
                                      DataColumn(label: Text("Email")),
                                      DataColumn(label: Text("Phone")),
                                      DataColumn(label: Text("Role")),
                                      DataColumn(label: Text("Address")),
                                      DataColumn(label: Text("Total Orders")),
                                      DataColumn(label: Text("Cancelled")),
                                      DataColumn(label: Text("Received")),
                                    ],
                                    rows: docs.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final uid = data["uid"] ?? doc.id;

                                      return DataRow(
                                        selected: selectedUserId == uid,
                                        onSelectChanged: (_) =>
                                            toggleSelect(uid, data),
                                        cells: [
                                          DataCell(
                                            Text(
                                              "${data["name"] ?? ""}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${data["email"] ?? ""}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${data["phone"] ?? ""}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${data["role"] ?? ""}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${data["address"] ?? ""}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "-",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "-",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "-",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (menuVisible && currentRole.isNotEmpty)
              Positioned(
                top: 70,
                right: 10,
                left: 10,
                child: DropMenu(
                  isVisible: menuVisible,
                  userRole: currentRole,
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

  Widget purpleMini(String text, {VoidCallback? onTap}) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: btnPurple,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
