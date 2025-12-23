import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';

class TermsManage extends StatefulWidget {
  const TermsManage({super.key});

  @override
  State<TermsManage> createState() => _TermsManageState();
}

class _TermsManageState extends State<TermsManage> {
  String userRole = "user";
  bool menuVisible = false;
  int bottomIndex = -1;

  bool showForm = false;
  String selectedTag = "order_rule";

  final Map<String, List<String>> _localCache = {};

  final List<SectionDraft> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    setState(() {
      userRole = doc["role"] ?? "user";
    });
  }

  bool get canEdit => userRole == "admin" || userRole == "manager";

  Future<void> _openForm(String tag) async {
    selectedTag = tag;
    _sections.clear();

    final doc = await FirebaseFirestore.instance
        .collection("terms_rules")
        .doc(tag)
        .get();

    if (doc.exists && doc.data()?["sections"] != null) {
      final List sections = doc["sections"];

      for (final s in sections) {
        final draft = SectionDraft();
        draft.titleController.text = s["title"] ?? "";

        final List items = s["items"] ?? [];
        draft.itemControllers.clear();

        for (final item in items) {
          draft.itemControllers.add(
            TextEditingController(text: item["text"] ?? ""),
          );
        }

        _sections.add(draft);
      }
    } else {
      _sections.add(SectionDraft());
    }

    setState(() => showForm = true);
  }

  Future<void> _submitForm() async {
    final List<Map<String, dynamic>> sections = [];

    for (int i = 0; i < _sections.length; i++) {
      final title = _sections[i].titleController.text.trim();
      if (title.isEmpty) continue;

      final items = _sections[i].itemControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .map((t) => {"text": t})
          .toList();

      if (items.isEmpty) continue;

      sections.add({"order": sections.length, "title": title, "items": items});
    }

    if (sections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one section")));
      return;
    }

    await FirebaseFirestore.instance
        .collection("terms_rules")
        .doc(selectedTag)
        .set({
          "sections": sections,
          "updatedAt": FieldValue.serverTimestamp(),
          "editedBy": FirebaseAuth.instance.currentUser?.uid,
        }, SetOptions(merge: true));

    setState(() => showForm = false);
  }

  Future<void> _saveToFirestore(List<Map<String, dynamic>> items) async {
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _localCache[selectedTag] = items
          .map((item) => item["text"] as String)
          .toList();
      showForm = false;
    });

    await FirebaseFirestore.instance
        .collection("terms_rules")
        .doc(selectedTag)
        .set({
          "tag": selectedTag,
          "items": items,
          "updatedAt": FieldValue.serverTimestamp(),
          "editedBy": user?.uid,
        }, SetOptions(merge: true));
  }

  Widget _actionButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

  Widget _displaySection(String tag, String title) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("terms_rules")
          .doc(tag)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox();

        final data = snap.data!.data() as Map<String, dynamic>;
        final List sections = (data["sections"] as List?) ?? [];

        final updatedAt = snap.data!["updatedAt"] as Timestamp?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            if (updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(
                  "Last updated: ${updatedAt.toDate()}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            ...sections.map((section) {
              final List items = section["items"] ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Text(
                    "${(section["order"] ?? 0) + 1}. ${section["title"]}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...items.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 6),
                      child: Text("• ${e["text"]}"),
                    ),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.titleController.dispose();
      for (final c in section.itemControllers) {
        c.dispose();
      }
    }
    super.dispose();
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
                  "Terms And Conditions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),

                if (canEdit)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionButton(
                          "Order Rule",
                          () => _openForm("order_rule"),
                        ),
                        const SizedBox(width: 10),
                        _actionButton(
                          "Terms & Conditions",
                          () => _openForm("terms"),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),

                Center(
                  child: const Text(
                    "Welcome to Cutesy.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.purple,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    "By accessing or using our mobile application and services, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the app.",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _displaySection("order_rule", "Order Rules"),
                        _displaySection("terms", "Terms & Conditions"),
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
                left: 10,
                right: 10,
                child: DropMenu(
                  isVisible: menuVisible,
                  userRole: userRole,
                  onItemTap: (_) => setState(() => menuVisible = false),
                ),
              ),

            if (showForm) _buildFormOverlay(),
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

  Widget _buildFormOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedTag == "order_rule"
                    ? "Edit Order Rules"
                    : "Edit Terms & Conditions",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int s = 0; s < _sections.length; s++) ...[
                        // SECTION HEADER
                        inputBox(
                          _sections[s].titleController,
                          "Section title (e.g. Definitions)",
                        ),

                        const SizedBox(height: 8),

                        // SECTION ITEMS
                        for (
                          int i = 0;
                          i < _sections[s].itemControllers.length;
                          i++
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: inputBox(
                              _sections[s].itemControllers[i],
                              "Write rule / definition",
                            ),
                          ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _sections[s].itemControllers.add(
                                  TextEditingController(),
                                );
                              });
                            },
                            child: const Text("+ Add item"),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _actionButton("Add Section", () {
                          setState(() {
                            _sections.add(SectionDraft());
                          });
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() => showForm = false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionDraft {
  final TextEditingController titleController;
  final List<TextEditingController> itemControllers;

  SectionDraft()
    : titleController = TextEditingController(),
      itemControllers = [TextEditingController()];
}
