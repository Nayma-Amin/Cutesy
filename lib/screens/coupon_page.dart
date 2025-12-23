import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_cutesy/screens/cart_page.dart';
import 'package:shop_cutesy/screens/home_page.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/profile_page.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class Coupon {
  String id;
  String code;
  int percentage;
  Timestamp startTime;
  Timestamp endTime;
  List<String> tags;

  Coupon({
    required this.id,
    required this.code,
    required this.percentage,
    required this.startTime,
    required this.endTime,
    required this.tags,
  });

  factory Coupon.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      code: data['code'],
      percentage: data['percentage'],
      startTime: data['startTime'],
      endTime: data['endTime'],
      tags: List<String>.from(data['tags']),
    );
  }
}

class _CouponPageState extends State<CouponPage> {
  int bottomIndex = 1;
  bool menuVisible = false;
  String username = "";
  String userRole = "user";
  bool _animate = false;

  List<Coupon> coupons = [];
  Set<String> selectedCoupons = {};
  Map<String, Duration> countdowns = {};
  Map<String, Timer> timers = {};

  String formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final daysStr = days > 0 ? '${days}d : ' : '';
    final hoursStr = '${hours.toString().padLeft(2, '0')}h : ';
    final minutesStr = '${minutes.toString().padLeft(2, '0')}m : ';
    final secondsStr = '${seconds.toString().padLeft(2, '0')}s';

    return '$daysStr$hoursStr$minutesStr$secondsStr';
  }

  @override
  void initState() {
    super.initState();
    loadUser();
    loadCoupons();
  }

  Future<void> loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      username = "";
      userRole = "user";
      setState(() => _animate = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    username = doc['name'] ?? "";
    userRole = doc['role'] ?? "user";
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _animate = true);
  }

  Future<void> loadCoupons() async {
    final snap = await FirebaseFirestore.instance.collection('coupons').get();
    setState(() {
      coupons = snap.docs.map((d) => Coupon.fromDoc(d)).toList();
      coupons.sort((a, b) {
        if (a.endTime.toDate().isBefore(DateTime.now()) &&
            !b.endTime.toDate().isBefore(DateTime.now()))
          return 1;
        if (!a.endTime.toDate().isBefore(DateTime.now()) &&
            b.endTime.toDate().isBefore(DateTime.now()))
          return -1;
        return 0;
      });
    });

    for (var coupon in coupons) {
      final now = DateTime.now();
      Duration diff;

      if (coupon.startTime.toDate().isAfter(now)) {
        diff = coupon.startTime.toDate().difference(now);
      } else {
        diff = coupon.endTime.toDate().difference(now);
      }

      countdowns[coupon.id] = diff.isNegative ? Duration.zero : diff;

      timers[coupon.id]?.cancel();
      timers[coupon.id] = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          final remaining = countdowns[coupon.id]! - const Duration(seconds: 1);
          countdowns[coupon.id] = remaining.isNegative
              ? Duration.zero
              : remaining;
        });
      });
    }
  }

  Widget _actionButton(
    String text,
    VoidCallback onTap, {
    Color bgColor = btnPurple,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
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

  void openCouponForm({Coupon? coupon}) async {
    final codeController = TextEditingController(text: coupon?.code ?? '');
    final percentController = TextEditingController(
      text: coupon?.percentage.toString() ?? '',
    );
    DateTime startTime = coupon?.startTime.toDate() ?? DateTime.now();
    DateTime endTime =
        coupon?.endTime.toDate() ?? DateTime.now().add(const Duration(days: 7));
    List<String> selectedTags = coupon?.tags ?? ['All'];

    final tagsSnap = await FirebaseFirestore.instance
        .collection('products')
        .get();
    Set<String> allTags = {};
    for (var doc in tagsSnap.docs) {
      final tag = doc['tag'];
      if (tag != null && tag != '') allTags.add(tag.toString());
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(coupon == null ? 'Add Coupon' : 'Edit Coupon'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
                TextField(
                  controller: percentController,
                  decoration: const InputDecoration(labelText: 'Percentage'),
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: Text('Start: ${startTime.toLocal()}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: startTime,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (dt != null) {
                      setDialogState(() => startTime = dt);
                    }
                  },
                ),
                ListTile(
                  title: Text('End: ${endTime.toLocal()}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: endTime,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (dt != null) {
                      setDialogState(() => endTime = dt);
                    }
                  },
                ),
                Wrap(
                  spacing: 5,
                  children: ['All', ...allTags].map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim();
                final percent =
                    int.tryParse(percentController.text.trim()) ?? 0;
                if (code.isEmpty || percent <= 0) return;

                final data = {
                  'code': code,
                  'percentage': percent,
                  'startTime': Timestamp.fromDate(startTime),
                  'endTime': Timestamp.fromDate(endTime),
                  'tags': selectedTags,
                };
                if (coupon == null) {
                  await FirebaseFirestore.instance
                      .collection('coupons')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('coupons')
                      .doc(coupon.id)
                      .update(data);
                }
                await loadCoupons();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void deleteCoupons() async {
    for (var id in selectedCoupons) {
      await FirebaseFirestore.instance.collection('coupons').doc(id).delete();
    }
    selectedCoupons.clear();
    loadCoupons();
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
                const Text(
                  "Coupon Collection",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                ),
                const SizedBox(height: 10),

                if (userRole == 'admin' || userRole == 'manager')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionButton("Add", () => openCouponForm()),
                        const SizedBox(width: 10),
                        _actionButton(
                          "Edit",
                          selectedCoupons.length == 1
                              ? () {
                                  final coupon = coupons.firstWhere(
                                    (c) => c.id == selectedCoupons.first,
                                  );
                                  openCouponForm(coupon: coupon);
                                }
                              : () {},
                          bgColor: selectedCoupons.length == 1
                              ? btnPurple
                              : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        _actionButton(
                          "Delete",
                          selectedCoupons.isNotEmpty ? deleteCoupons : () {},
                          bgColor: selectedCoupons.isNotEmpty
                              ? btnPurple
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final isExpired = coupon.endTime.toDate().isBefore(
                        DateTime.now(),
                      );
                      final isSelected = selectedCoupons.contains(coupon.id);

                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Card(
                          color: isExpired ? Colors.grey[300] : Colors.white,
                          child: ListTile(
                            leading:
                                (userRole == 'admin' || userRole == 'manager')
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          selectedCoupons.add(coupon.id);
                                        } else {
                                          selectedCoupons.remove(coupon.id);
                                        }
                                      });
                                    },
                                  )
                                : null,
                            title: Text(
                              coupon.code,
                              style: TextStyle(
                                color: isExpired ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${coupon.percentage}% off',
                                  style: TextStyle(
                                    color: isExpired
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  isExpired
                                      ? 'Expired'
                                      : (coupon.startTime.toDate().isAfter(
                                              DateTime.now(),
                                            )
                                            ? 'Starts in: ${formatDuration(countdowns[coupon.id]!)}'
                                            : 'Ends in: ${formatDuration(countdowns[coupon.id]!)}'),
                                  style: TextStyle(
                                    color: isExpired
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Applicable on: ${coupon.tags.join(', ')}',
                                  style: TextStyle(
                                    color: isExpired
                                        ? Colors.grey
                                        : Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),

                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: isExpired
                                  ? null
                                  : () {
                                      Clipboard.setData(
                                        ClipboardData(text: coupon.code),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Code copied!'),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ),
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
          setState(() => bottomIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CouponPage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
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
}
